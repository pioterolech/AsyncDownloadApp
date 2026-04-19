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
        let delegate = DownloadSessionDelegate(storage: storage)
        let session = URLSession(configuration: configuration, delegate: delegate, delegateQueue: nil)
        let task = DownloadTask(session: session)
        delegate.delegate = task
        return task
    }
}
