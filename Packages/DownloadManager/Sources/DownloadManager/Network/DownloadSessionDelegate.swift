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
        Task { await self.delegate?.progress(for: downloadTask.taskIdentifier, written: totalBytesWritten, total: totalBytesExpectedToWrite) }
    }

    func urlSession(
        _ session: URLSession,
        downloadTask: URLSessionDownloadTask,
        didFinishDownloadingTo location: URL
    ) {
        do {
            let savedURL = try storage.saveTempFile(from: location)
            Task { await self.delegate?.complete(for: downloadTask.taskIdentifier, location: savedURL) }
        } catch {
            Task { await self.delegate?.fail(for: downloadTask.taskIdentifier, error: error) }
        }
    }

    func urlSession(
        _ session: URLSession,
        task: URLSessionTask,
        didCompleteWithError error: Error?
    ) {
        guard let error else { return }
        Task { await self.delegate?.fail(for: task.taskIdentifier, error: error) }
    }
}
