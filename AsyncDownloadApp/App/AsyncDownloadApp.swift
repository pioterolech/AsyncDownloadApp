import SwiftUI
import DownloadManager

@main
struct AsyncDownloadApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    private let managerResult: Result<any DownloadManagerProtocol, Error>
    @State private var containerResult: Result<ViewModelsDependencyContainer, Error>? = nil

    init() {
        managerResult = Result { try DownloadManagerFactory().make() }
        if case .success(let manager) = managerResult {
            appDelegate.downloadManager = manager
        }
    }

    var body: some Scene {
        WindowGroup {
            Group {
                if let result = containerResult {
                    RootView(containerResult: result)
                } else {
                    ProgressView()
                }
            }
            .task {
                do {
                    let manager = try managerResult.get()
                    try await manager.startup()
                    containerResult = .success(ViewModelsDependencyContainer(downloadManager: manager))
                } catch {
                    containerResult = .failure(error)
                }
            }
        }
    }
}
