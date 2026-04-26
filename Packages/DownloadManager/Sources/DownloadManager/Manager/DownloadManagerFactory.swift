import Foundation

public final class DownloadManagerFactory {
    public init() {}

    public func make() throws -> any DownloadManagerProtocol {
        let fileStorage = FileStorage()
        let sessionDelegate = DownloadSessionDelegate(storage: fileStorage)
        let configuration = URLSessionConfiguration.background(withIdentifier: DownloadManagerConstants.backgroundSessionIdentifier)
        let session = URLSession(configuration: configuration, delegate: sessionDelegate, delegateQueue: nil)
        let downloadTask = DownloadTask(session: session)
        sessionDelegate.delegate = downloadTask
        let container = try DownloadStorage.makeContainer()
        let downloadStorage = DownloadStorage(modelContainer: container)
        return DownloadManager(
            fileStorage: fileStorage,
            downloadTask: downloadTask,
            downloadStorage: downloadStorage
        )
    }
}
