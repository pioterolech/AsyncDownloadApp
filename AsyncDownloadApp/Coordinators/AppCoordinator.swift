import SwiftUI

@MainActor
final class AppCoordinator: ObservableObject {
    @Published var isAddLinkPresented = false

    func showAddLink() {
        isAddLinkPresented = true
    }

    func dismissAddLink() {
        isAddLinkPresented = false
    }
}
