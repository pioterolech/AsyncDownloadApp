import SwiftUI

struct RootView: View {
    @StateObject private var coordinator = AppCoordinator()
    private let containerResult: Result<ViewModelsDependencyContainer, Error>

    init() {
        containerResult = Result { try ViewModelsDependencyContainer() }
    }

    var body: some View {
        switch containerResult {
        case .success(let container):
            MainView(coordinator: coordinator, container: container)
        case .failure(let error):
            ContentUnavailableView(
                "Storage Unavailable",
                systemImage: "exclamationmark.triangle",
                description: Text(error.localizedDescription)
            )
        }
    }
}

private struct MainView: View {
    @ObservedObject var coordinator: AppCoordinator
    @ObservedObject var container: ViewModelsDependencyContainer
    @StateObject private var downloadListViewModel: DownloadListViewModel

    init(coordinator: AppCoordinator, container: ViewModelsDependencyContainer) {
        self.coordinator = coordinator
        self.container = container
        _downloadListViewModel = StateObject(wrappedValue: container.makeDownloadListViewModel())
    }

    var body: some View {
        NavigationStack {
            DownloadListView(
                viewModel: downloadListViewModel,
                onAddTapped: { coordinator.showAddLink() }
            )
        }
        .sheet(isPresented: $coordinator.isAddLinkPresented) {
            NavigationStack {
                AddLinkView(
                    viewModel: container.makeAddLinkViewModel(),
                    onDismiss: { coordinator.dismissAddLink() }
                )
            }
        }
    }
}
