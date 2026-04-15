import Foundation

actor DownloadTask: DownloadTaskProtocol {

    private let session: any URLSessionProtocol
    private let storage: any FileStorageProtocol
    private var states: [Int: AsyncThrowingStream<DownloadTaskEvent, Error>.Continuation] = [:]

    init(session: any URLSessionProtocol, storage: any FileStorageProtocol) {
        self.session = session
        self.storage = storage
    }

    func fetch(from url: URL) -> AsyncThrowingStream<DownloadTaskEvent, Error> {
        AsyncThrowingStream { continuation in
            let task = session.downloadTask(with: url)
            states[task.taskIdentifier] = continuation
            continuation.onTermination = {
                _ in task.cancel()
            }
            task.resume()
        }
    }
}

extension DownloadTask: DownloadTaskDelegate {

    func progress(for taskID: Int, written: Int64, total: Int64) {
        states[taskID]?.yield(.progress(written, total))
    }

    func complete(for taskID: Int, location: URL) {
        let continuation = states.removeValue(forKey: taskID)
        do {
            let tempURL = try storage.saveTempFile(from: location)
            continuation?.yield(.completed(tempURL))
            continuation?.finish()
        } catch {
            continuation?.finish(throwing: error)
        }
    }

    func fail(for taskID: Int, error: Error) {
        let continuation = states.removeValue(forKey: taskID)
        continuation?.finish(throwing: error)
    }
}
