import Foundation

public actor DownloadManager {
    private let continuation: AsyncStream<[Download]>.Continuation
    private let storage: any DownloadStorageProtocol
    private let streamer: any NetworkBytesFetcherProtocol
    private var downloads: [UUID: Download] = [:]
    private var tasks: [UUID: Task<Void, Never>] = [:]

    public let downloadStream: AsyncStream<[Download]>

    public init(
        storage: any DownloadStorageProtocol,
        streamer: any NetworkBytesFetcherProtocol
    ) {
        (downloadStream, continuation) = AsyncStream.makeStream()
        self.storage = storage
        self.streamer = streamer
    }

    // MARK: - Public API

    public func add(url: URL) {
        let download = Download(url: url, state: .queued)
        downloads[download.id] = download
        emit()
        startTask(for: download.id)
    }

    public func cancel(id: UUID) {
        tasks[id]?.cancel()
        tasks[id] = nil
    }

    public func remove(id: UUID) {
        tasks[id]?.cancel()
        tasks[id] = nil
        downloads[id] = nil
        emit()
    }

    // MARK: - Private

    private func startTask(for id: UUID) {
        tasks[id] = Task {
            await performDownload(id: id)
        }
    }

    private func performDownload(id: UUID) async {
        guard let download = downloads[id] else { return }

        markDownloading(id: id)

        let tempURL = storage.createTempFile(for: id)

        do {
            try await streamer.fetch(from: download.url, into: tempURL) { [self] received, total in
                await updateProgress(id: id, received: received, total: total)
            }
            let destURL = try storage.moveToDocuments(
                from: tempURL,
                id: id,
                sourceURL: download.url
            )
            markCompleted(id: id, fileURL: destURL)
        } catch is CancellationError {
            storage.deleteTempFile(for: id)
            markCancelled(id: id)
        } catch {
            storage.deleteTempFile(for: id)
            markFailed(id: id, error: .networkError(underlying: error))
        }

        tasks[id] = nil
    }

    // MARK: - State updates

    private func markDownloading(id: UUID) {
        downloads[id]?.state = .downloading
        emit()
    }

    private func markCompleted(id: UUID, fileURL: URL) {
        downloads[id]?.state = .completed
        downloads[id]?.progress = 1.0
        downloads[id]?.fileURL = fileURL
        emit()
    }

    private func markCancelled(id: UUID) {
        downloads[id]?.state = .cancelled
        downloads[id]?.error = .cancelled
        emit()
    }

    private func markFailed(id: UUID, error: DownloadError) {
        downloads[id]?.state = .failed
        downloads[id]?.error = error
        emit()
    }

    private func updateProgress(id: UUID, received: Int64, total: Int64) {
        downloads[id]?.progress = min(Double(received) / Double(total), 1.0)
        emit()
    }

    private func emit() {
        let snapshot = Array(downloads.values).sorted { $0.url.absoluteString < $1.url.absoluteString }
        continuation.yield(snapshot)
    }
}
