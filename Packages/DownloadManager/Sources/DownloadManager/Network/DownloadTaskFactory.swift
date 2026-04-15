import Foundation

final class DownloadTaskFactory {

    private let configuration: URLSessionConfiguration
    private let storage: any FileStorageProtocol

    init(
        configuration: URLSessionConfiguration = .default,
        storage: any FileStorageProtocol
    ) {
        self.configuration = configuration
        self.storage = storage
    }

    func make() -> DownloadTask {
        let delegate = DownloadSessionDelegate()
        let session = URLSession(configuration: configuration, delegate: delegate, delegateQueue: nil)
        let task = DownloadTask(session: session, storage: storage)
        delegate.delegate = task
        return task
    }
}
