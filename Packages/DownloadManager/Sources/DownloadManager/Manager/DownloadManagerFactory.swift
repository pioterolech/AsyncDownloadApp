import Foundation

public final class DownloadManagerFactory {
    public init() {}

    public func make() throws -> any DownloadManagerProtocol {
        let fileStorage = FileStorage()
        let downloadTask = DownloadTaskFactory(configuration: .default, storage: fileStorage).make()
        let container = try DownloadStorage.makeContainer()
        let downloadStorage = DownloadStorage(modelContainer: container)
        return DownloadManager(fileStorage: fileStorage, downloadTask: downloadTask, downloadStorage: downloadStorage)
    }
}
