import Foundation

public final class DownloadManagerFactory {

    private let configuration: URLSessionConfiguration

    public init(configuration: URLSessionConfiguration) {
        self.configuration = configuration
    }

    public func make() -> any DownloadManagerProtocol {
        let storage = FileStorage()
        let downloadTask = DownloadTaskFactory(configuration: configuration, storage: storage).make()
        return DownloadManager(storage: storage, downloadTask: downloadTask)
    }
}
