import Foundation

public final class DownloadManagerFactory {
    public init () {
    }
    
    public func make() -> any DownloadManagerProtocol {
        let storage = FileStorage()
        let downloadTask = DownloadTaskFactory(configuration: .default, storage: storage).make()
        return DownloadManager(storage: storage, downloadTask: downloadTask)
    }
}
