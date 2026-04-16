import SwiftUI

struct RootView: View {
    @StateObject private var coordinator = AppCoordinator()
    @StateObject private var container = DependencyContainer()

    var body: some View {
        NavigationStack {
            DownloadListView(
                viewModel: container.downloadListViewModel,
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
