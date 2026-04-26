import Foundation

final class DownloadSessionDelegate: NSObject, URLSessionDownloadDelegate {

    nonisolated(unsafe) weak var delegate: (any DownloadTaskDelegate)?
    private let storage: any FileStorageProtocol

    init(storage: any FileStorageProtocol) {
        self.storage = storage
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
        let id = downloadTask.taskIdentifier
        do {
            let savedURL = try storage.saveTempFile(from: location)
            Task { await self.delegate?.complete(for: id, location: savedURL) }
        } catch {
            Task { await self.delegate?.fail(for: id, error: error) }
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
}
