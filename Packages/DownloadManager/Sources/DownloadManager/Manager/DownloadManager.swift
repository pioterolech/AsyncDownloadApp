import Foundation

public actor DownloadManager: DownloadManagerProtocol {
    private let continuation: AsyncStream<[Download]>.Continuation
    private let fileStorage: any FileStorageProtocol
    private let downloadTask: any DownloadTaskProtocol
    private let downloadStorage: any DownloadStorageProtocol
    private var downloads: [UUID: Download] = [:]
    private var tasks: [UUID: Task<Void, Never>] = [:]

    public let downloadStream: AsyncStream<[Download]>

    public init(
        fileStorage: any FileStorageProtocol,
        downloadTask: any DownloadTaskProtocol,
        downloadStorage: any DownloadStorageProtocol
    ) {
        (downloadStream, continuation) = AsyncStream.makeStream()
        self.fileStorage = fileStorage
        self.downloadTask = downloadTask
        self.downloadStorage = downloadStorage
        Task { await self.restorePersistedDownloads() }
    }

    // MARK: - Public API

    public func add(url: URL) async {
        let download = Download(url: url, state: .queued)
        downloads[download.id] = download
        emit()
        await persist(download)
        startTask(for: download.id)
    }

    public func cancel(id: UUID) async {
        tasks[id]?.cancel()
        tasks[id] = nil
    }

    public func remove(id: UUID) async throws {
        tasks[id]?.cancel()
        tasks[id] = nil
        downloads[id] = nil
        emit()
        try await downloadStorage.delete(id: id)
    }

    // MARK: - Private

    private func restorePersistedDownloads() async {
        guard let records = try? await downloadStorage.fetchAll(), !records.isEmpty else { return }
        for record in records {
            guard var download = try? Download(persisted: record) else { continue }
            if download.state == .queued || download.state == .downloading {
                download.state = .cancelled
                download.progress = 0
                await persist(download)
            }
            downloads[download.id] = download
        }
        emit()
    }

    private func persist(_ download: Download) async {
        let record = PersistedDownload(
            id: download.id,
            urlString: download.url.absoluteString,
            stateRaw: download.state.rawValue,
            progress: download.progress,
            fileURLString: download.fileURL?.absoluteString
        )
        try? await downloadStorage.save(record)
    }

    private func startTask(for id: UUID) {
        tasks[id] = Task {
            do {
                try await performDownload(id: id)
            } catch is CancellationError {
                await markCancelled(id: id)
            } catch {
                await markFailed(id: id, error: .networkError(underlying: error))
            }
            tasks[id] = nil
        }
    }

    private func performDownload(id: UUID) async throws {
        guard let download = downloads[id] else { return }
        await markDownloading(id: id)
        for try await event in await downloadTask.fetch(from: download.url) {
            switch event {
            case .progress(let received, let total):
                updateProgress(id: id, received: received, total: total)
            case .completed(let tempURL):
                let destURL = try fileStorage.moveToDocuments(from: tempURL, id: id, sourceURL: download.url)
                await markCompleted(id: id, fileURL: destURL)
            }
        }
        try Task.checkCancellation()
    }

    // MARK: - State updates

    private func markDownloading(id: UUID) async {
        downloads[id]?.state = .downloading
        emit()
        if let download = downloads[id] { await persist(download) }
    }

    private func markCompleted(id: UUID, fileURL: URL) async {
        guard downloads[id]?.state == .downloading else { return }
        downloads[id]?.state = .completed
        downloads[id]?.progress = 1.0
        downloads[id]?.fileURL = fileURL
        emit()
        if let download = downloads[id] { await persist(download) }
    }

    private func markCancelled(id: UUID) async {
        guard downloads[id]?.state == .downloading || downloads[id]?.state == .queued else { return }
        downloads[id]?.state = .cancelled
        downloads[id]?.error = .cancelled
        emit()
        if let download = downloads[id] { await persist(download) }
    }

    private func markFailed(id: UUID, error: DownloadError) async {
        guard downloads[id]?.state == .downloading else { return }
        downloads[id]?.state = .failed
        downloads[id]?.error = error
        emit()
        if let download = downloads[id] { await persist(download) }
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
