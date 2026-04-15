import Foundation

public actor DownloadManager {
    private let continuation: AsyncStream<[Download]>.Continuation
    private let storage: any FileStorageProtocol
    private let downloadTask: any DownloadTaskProtocol
    private var downloads: [UUID: Download] = [:]
    private var tasks: [UUID: Task<Void, Never>] = [:]

    public let downloadStream: AsyncStream<[Download]>

    public init(
        storage: any FileStorageProtocol,
        downloadTask: any DownloadTaskProtocol
    ) {
        (downloadStream, continuation) = AsyncStream.makeStream()
        self.storage = storage
        self.downloadTask = downloadTask
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
            do {
                try await performDownload(id: id)
            } catch is CancellationError {
                markCancelled(id: id)
            } catch {
                markFailed(id: id, error: .networkError(underlying: error))
            }
            tasks[id] = nil
        }
    }

    private func performDownload(id: UUID) async throws {
        guard let download = downloads[id] else { return }

        markDownloading(id: id)

        for try await event in await downloadTask.fetch(from: download.url) {
            switch event {
            case .progress(let received, let total):
                updateProgress(id: id, received: received, total: total)
            case .completed(let tempURL):
                let destURL = try storage.moveToDocuments(from: tempURL, id: id, sourceURL: download.url)
                markCompleted(id: id, fileURL: destURL)
            }
        }
        try Task.checkCancellation()
    }

    // MARK: - State updates

    private func markDownloading(id: UUID) {
        downloads[id]?.state = .downloading
        emit()
    }

    private func markCompleted(id: UUID, fileURL: URL) {
        guard downloads[id]?.state == .downloading else { return }
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
