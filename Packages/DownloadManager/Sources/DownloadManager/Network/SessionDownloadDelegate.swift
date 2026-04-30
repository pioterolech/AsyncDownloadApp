import Foundation

final class SessionDownloadDelegate: NSObject, URLSessionDownloadDelegate, @unchecked Sendable {

    nonisolated(unsafe) weak var delegate: (any DownloadTaskDelegate)?
    nonisolated(unsafe) weak var backgroundEventsDelegate: (any BackgroundEventsDelegate)?
    private let fileStorage: any FileStorageProtocol

    init(storage: any FileStorageProtocol) {
        self.fileStorage = storage
    }

    func urlSession(
        _ session: URLSession,
        downloadTask: URLSessionDownloadTask,
        didWriteData bytesWritten: Int64,
        totalBytesWritten: Int64,
        totalBytesExpectedToWrite: Int64
    ) {
        guard totalBytesExpectedToWrite > 0 else { return }
        let id = downloadTask.taskIdentifier
        Task { await self.delegate?.progress(for: id, written: totalBytesWritten, total: totalBytesExpectedToWrite) }
    }

    func urlSession(
        _ session: URLSession,
        downloadTask: URLSessionDownloadTask,
        didFinishDownloadingTo location: URL
    ) {
        let taskID = downloadTask.taskIdentifier
        do {
            let tempURL = try fileStorage.saveTempFile(from: location)
            Task { await self.delegate?.complete(for: taskID, tempURL: tempURL) }
        } catch {
            Task { await self.delegate?.fail(for: taskID, error: error) }
        }
    }

    func urlSession(
        _ session: URLSession,
        task: URLSessionTask,
        didCompleteWithError error: Error?
    ) {
        guard let error else { return }
        let id = task.taskIdentifier
        Task { await self.delegate?.fail(for: id, error: error) }
    }

    func urlSessionDidFinishEvents(forBackgroundURLSession session: URLSession) {
        Task { await self.backgroundEventsDelegate?.urlSessionDidFinishEvents() }
    }
}
