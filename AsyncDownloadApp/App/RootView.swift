import SwiftUI

struct RootView: View {
    @StateObject private var coordinator = AppCoordinator()
    private let containerResult: Result<ViewModelsDependencyContainer, Error>

    init(containerResult: Result<ViewModelsDependencyContainer, Error>) {
        self.containerResult = containerResult
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
    var container: ViewModelsDependencyContainer

    var body: some View {
        NavigationStack {
            DownloadListView(
                viewModel: container.makeDownloadListViewModel(),
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
