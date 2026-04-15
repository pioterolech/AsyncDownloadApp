import Foundation
import DownloadManager

@MainActor
final class DependencyContainer: ObservableObject {

    // MARK: - Core

    let downloadManager: any DownloadManagerProtocol

    // MARK: - ViewModels

    let downloadListViewModel: DownloadListViewModel

    // MARK: - Init

    init() {
        downloadManager = DownloadManagerFactory(configuration: .default).make()
        downloadListViewModel = DownloadListViewModel(downloadManager: downloadManager)
    }

    // MARK: - Factories

    func makeAddLinkViewModel() -> AddLinkViewModel {
        AddLinkViewModel(downloadManager: downloadManager)
    }
}
