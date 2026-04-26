import Foundation
import DownloadManager

@MainActor
struct ViewModelsDependencyContainer {
    private let downloadManager: any DownloadManagerProtocol

    init() throws {
        self.downloadManager = try DownloadManagerFactory().make()
    }

    func makeDownloadListViewModel() -> DownloadListViewModel {
        DownloadListViewModel(downloadManager: downloadManager)
    }

    func makeAddLinkViewModel() -> AddLinkViewModel {
        AddLinkViewModel(downloadManager: downloadManager)
    }
}
