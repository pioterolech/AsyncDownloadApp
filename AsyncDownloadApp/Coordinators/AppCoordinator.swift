import SwiftUI

enum Route: Hashable {
    case addLink
}

@MainActor
final class AppCoordinator: ObservableObject {
    @Published var path = NavigationPath()

    func showAddLink() {
        path.append(Route.addLink)
    }

    func dismissAddLink() {
        path.removeLast()
    }
}
