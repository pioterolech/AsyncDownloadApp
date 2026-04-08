import SwiftUI

struct RootView: View {
    @StateObject private var coordinator = AppCoordinator()
    @StateObject private var container = DependencyContainer()

    var body: some View {
        NavigationStack(path: $coordinator.path) {
            DownloadListView(
                viewModel: container.downloadListViewModel,
                onAddTapped: { coordinator.showAddLink() }
            )
            .navigationDestination(for: Route.self) { route in
                switch route {
                case .addLink:
                    AddLinkView(
                        viewModel: container.makeAddLinkViewModel(),
                        onDismiss: { coordinator.dismissAddLink() }
                    )
                }
            }
        }
    }
}
