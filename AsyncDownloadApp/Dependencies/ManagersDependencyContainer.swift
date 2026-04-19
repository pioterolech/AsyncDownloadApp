import Foundation
import DownloadManager

@MainActor
final class ManagersDependencyContainer {
    let downloadManager: any DownloadManagerProtocol

    init() throws {
        downloadManager = try DownloadManagerFactory().make()
    }
}
