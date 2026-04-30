import Foundation
import DownloadManager

@MainActor
struct ViewModelsDependencyContainer {
    private let downloadManager: any DownloadManagerProtocol

    init(downloadManager: any DownloadManagerProtocol) {
        self.downloadManager = downloadManager
    }

    func makeDownloadListViewModel() -> DownloadListViewModel {
        DownloadListViewModel(downloadManager: downloadManager)
    }

    func makeAddLinkViewModel() -> AddLinkViewModel {
        AddLinkViewModel(downloadManager: downloadManager)
    }
}
