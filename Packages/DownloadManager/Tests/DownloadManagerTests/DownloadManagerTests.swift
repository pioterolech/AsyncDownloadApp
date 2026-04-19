import Testing
import Foundation
@testable import DownloadManager

// MARK: - Tests

@Suite("DownloadManager")
struct DownloadManagerTests {

    let fileStorage = FileStorageProtocolMock()
    let downloadTask = DownloadTaskProtocolMock()
    let downloadStorage = DownloadStorageProtocolMock()
    let url = URL(string: "https://example.com/file.zip")!

    func makeManager() -> DownloadManager {
        if downloadStorage.fetchAllReturnValue == nil {
            downloadStorage.fetchAllReturnValue = []
        }
        if downloadTask.fetchReturnValue == nil {
            downloadTask.fetchReturnValue = AsyncThrowingStream { $0.finish() }
        }
        return DownloadManager(fileStorage: fileStorage, downloadTask: downloadTask, downloadStorage: downloadStorage)
    }

    // MARK: - Existing behaviour

    @Test("add transitions through queued → downloading → completed")
    func addCompletesSuccessfully() async throws {
        // Given
        let tempURL = URL(filePath: "/tmp/mock")
        let destURL = URL(filePath: "/docs/mock.zip")
        fileStorage.moveToDocumentsReturnValue = destURL
        downloadTask.fetchHandler = { @Sendable _ in
            AsyncThrowingStream { continuation in
                continuation.yield(.progress(512, 1024))
                continuation.yield(.progress(1024, 1024))
                continuation.yield(.completed(tempURL))
                continuation.finish()
            }
        }
        let manager = makeManager()

        // When
        await manager.add(url: url)
        let emissions = await manager.downloadStream.collect { $0.first?.state == .completed }

        // Then
        let states = emissions.compactMap { $0.first?.state }
        #expect(states == [.queued, .downloading, .downloading, .downloading, .completed])
        #expect(emissions.last?.first?.fileURL == destURL)
        #expect(emissions.last?.first?.progress == 1.0)
    }

    @Test("cancel transitions download to cancelled state")
    func cancelStopsDownload() async throws {
        // Given
        downloadTask.fetchHandler = { @Sendable _ in AsyncThrowingStream { _ in } }
        let manager = makeManager()
        await manager.add(url: url)
        let downloading = await manager.downloadStream.collect { $0.first?.state == .downloading }
        let id = try #require(downloading.last?.first?.id)

        // When
        await manager.cancel(id: id)
        let emissions = await manager.downloadStream.collect { $0.first?.state == .cancelled }

        // Then
        #expect(emissions.last?.first?.state == .cancelled)
    }

    @Test("remove eliminates download from stream")
    func removeDeletesDownload() async throws {
        // Given
        let tempURL = URL(filePath: "/tmp/mock")
        fileStorage.moveToDocumentsReturnValue = URL(filePath: "/docs/mock.zip")
        downloadTask.fetchHandler = { @Sendable _ in
            AsyncThrowingStream { continuation in
                continuation.yield(.completed(tempURL))
                continuation.finish()
            }
        }
        let manager = makeManager()
        await manager.add(url: url)
        let completed = await manager.downloadStream.collect { $0.first?.state == .completed }
        let id = try #require(completed.last?.first?.id)

        // When
        try await manager.remove(id: id)
        let emissions = await manager.downloadStream.collect { $0.isEmpty }

        // Then
        #expect(emissions.last?.isEmpty == true)
    }

    @Test("failed fetch transitions download to failed state")
    func fetchErrorTransitionsToFailed() async throws {
        // Given
        struct FetchError: Error {}
        downloadTask.fetchHandler = { @Sendable _ in
            AsyncThrowingStream { continuation in
                continuation.finish(throwing: FetchError())
            }
        }
        let manager = makeManager()

        // When
        await manager.add(url: url)
        let emissions = await manager.downloadStream.collect { $0.first?.state == .failed }

        // Then
        let states = emissions.compactMap { $0.first?.state }
        #expect(states == [.queued, .downloading, .failed])
    }

    @Test("progress is reported during fetch")
    func progressIsUpdated() async throws {
        // Given
        let tempURL = URL(filePath: "/tmp/mock")
        fileStorage.moveToDocumentsReturnValue = URL(filePath: "/docs/mock.zip")
        downloadTask.fetchHandler = { @Sendable _ in
            AsyncThrowingStream { continuation in
                continuation.yield(.progress(256, 1024))
                continuation.yield(.progress(512, 1024))
                continuation.yield(.progress(1024, 1024))
                continuation.yield(.completed(tempURL))
                continuation.finish()
            }
        }
        let manager = makeManager()

        // When
        await manager.add(url: url)
        let emissions = await manager.downloadStream.collect { $0.first?.state == .completed }

        // Then
        let progressValues = emissions.compactMap { $0.first?.progress }
        #expect(progressValues == [0.0, 0.0, 0.25, 0.5, 1.0, 1.0])
    }

    // MARK: - State restoration

    @Test("queued downloads are restored as cancelled on launch")
    func queuedDownloadsRestoredAsCancelled() async {
        // Given
        downloadStorage.fetchAllReturnValue = [
            Download(url: url, state: .queued)
        ]

        // When
        let manager = makeManager()
        let emissions = await manager.downloadStream.collect { !$0.isEmpty }

        // Then
        #expect(emissions.last?.first?.state == .cancelled)
    }

    @Test("downloading downloads are restored as cancelled on launch")
    func downloadingDownloadsRestoredAsCancelled() async {
        // Given
        downloadStorage.fetchAllReturnValue = [
            Download(url: url, state: .downloading, progress: 0.5)
        ]

        // When
        let manager = makeManager()
        let emissions = await manager.downloadStream.collect { !$0.isEmpty }

        // Then
        #expect(emissions.last?.first?.state == .cancelled)
    }

    @Test("completed downloads are restored with their original state")
    func completedDownloadsRestoredAsCompleted() async {
        // Given
        let fileURL = URL(string: "file:///docs/file.zip")
        downloadStorage.fetchAllReturnValue = [
            Download(url: url, state: .completed, progress: 1.0, fileURL: fileURL)
        ]

        // When
        let manager = makeManager()
        let emissions = await manager.downloadStream.collect { !$0.isEmpty }

        // Then
        #expect(emissions.last?.first?.state == .completed)
        #expect(emissions.last?.first?.progress == 1.0)
    }

    // MARK: - State guards

    @Test("error after completion does not overwrite completed state")
    func errorAfterCompletionKeepsCompletedState() async {
        // Given
        struct LateError: Error {}
        let tempURL = URL(filePath: "/tmp/mock")
        fileStorage.moveToDocumentsReturnValue = URL(filePath: "/docs/mock.zip")
        downloadTask.fetchHandler = { @Sendable _ in
            AsyncThrowingStream { continuation in
                continuation.yield(.completed(tempURL))
                continuation.finish(throwing: LateError())
            }
        }
        let manager = makeManager()

        // When
        await manager.add(url: url)
        let emissions = await manager.downloadStream.collect { $0.first?.state == .completed }

        // Then
        #expect(emissions.last?.first?.state == .completed)
    }

    @Test("cancellation after completion does not overwrite completed state")
    func cancellationAfterCompletionKeepsCompletedState() async throws {
        // Given
        let tempURL = URL(filePath: "/tmp/mock")
        fileStorage.moveToDocumentsReturnValue = URL(filePath: "/docs/mock.zip")
        downloadTask.fetchHandler = { @Sendable _ in
            AsyncThrowingStream { continuation in
                continuation.yield(.completed(tempURL))
                continuation.finish()
            }
        }
        let manager = makeManager()
        await manager.add(url: url)
        let completed = await manager.downloadStream.collect { $0.first?.state == .completed }
        let id = try #require(completed.last?.first?.id)

        // When
        await manager.cancel(id: id)

        // Then
        #expect(completed.last?.first?.state == .completed)
    }

    // MARK: - Storage interactions

    @Test("remove deletes download from storage")
    func removeDeletesFromStorage() async throws {
        // Given
        let tempURL = URL(filePath: "/tmp/mock")
        fileStorage.moveToDocumentsReturnValue = URL(filePath: "/docs/mock.zip")
        downloadTask.fetchHandler = { @Sendable _ in
            AsyncThrowingStream { continuation in
                continuation.yield(.completed(tempURL))
                continuation.finish()
            }
        }
        let manager = makeManager()
        await manager.add(url: url)
        let completed = await manager.downloadStream.collect { $0.first?.state == .completed }
        let id = try #require(completed.last?.first?.id)

        // When
        try await manager.remove(id: id)

        // Then
        #expect(downloadStorage.deleteReceivedId == id)
    }

    @Test("add persists download to storage")
    func addPersistsDownload() async throws {
        // Given
        let manager = makeManager()

        // When
        await manager.add(url: url)

        // Then
        #expect(downloadStorage.saveReceivedDownload?.url == url)
    }
}
