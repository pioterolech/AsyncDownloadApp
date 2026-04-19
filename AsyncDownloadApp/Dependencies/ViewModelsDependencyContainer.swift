import Foundation
import DownloadManager

@MainActor
final class ViewModelsDependencyContainer: ObservableObject {
    private let downloadManager: any DownloadManagerProtocol

    init() throws {
        let managers = try ManagersDependencyContainer()
        self.downloadManager = managers.downloadManager
    }

    func makeDownloadListViewModel() -> DownloadListViewModel {
        DownloadListViewModel(downloadManager: downloadManager)
    }

    func makeAddLinkViewModel() -> AddLinkViewModel {
        AddLinkViewModel(downloadManager: downloadManager)
    }
}
