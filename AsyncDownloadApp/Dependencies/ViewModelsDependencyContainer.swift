import Foundation

@MainActor
final class ViewModelsDependencyContainer: ObservableObject {

    private let managers: ManagersDependencyContainer

    let downloadListViewModel: DownloadListViewModel

    init(managers: ManagersDependencyContainer) {
        self.managers = managers
        downloadListViewModel = DownloadListViewModel(downloadManager: managers.downloadManager)
    }

    func makeAddLinkViewModel() -> AddLinkViewModel {
        AddLinkViewModel(downloadManager: managers.downloadManager)
    }
}
