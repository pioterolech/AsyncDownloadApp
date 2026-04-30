import Foundation

actor DownloadTask: DownloadTaskProtocol {

    private let session: any URLSessionProtocol
    private var states: [Int: AsyncThrowingStream<DownloadTaskEvent, Error>.Continuation] = [:]

    init(session: any URLSessionProtocol) {
        self.session = session
    }

    func fetch(from url: URL, id: UUID) -> AsyncThrowingStream<DownloadTaskEvent, Error> {
        AsyncThrowingStream { continuation in
            let task = session.downloadTask(with: url)
            task.taskDescription = id.uuidString
            states[task.taskIdentifier] = continuation
            continuation.onTermination = { _ in task.cancel() }
            task.resume()
        }
    }
}

extension DownloadTask: DownloadTaskDelegate {

    func progress(for taskID: Int, written: Int64, total: Int64) {
        let continuation = states[taskID]
        continuation?.yield(.progress(written, total))
    }

    func complete(for taskID: Int, tempURL: URL) {
        let continuation = states.removeValue(forKey: taskID)
        continuation?.yield(.completed(tempURL))
        continuation?.finish()
    }

    func fail(for taskID: Int, error: Error) {
        let continuation = states.removeValue(forKey: taskID)
        continuation?.finish(throwing: error)
    }
}
