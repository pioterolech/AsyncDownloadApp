import SwiftUI

@main
struct AsyncDownloadApp: App {
    private let containerResult: Result<ViewModelsDependencyContainer, Error> =
        Result { try ViewModelsDependencyContainer() }

    var body: some Scene {
        WindowGroup {
            RootView(containerResult: containerResult)
        }
    }
}
