import UIKit
import DownloadManager

@MainActor
final class AppDelegate: NSObject, UIApplicationDelegate {
    var downloadManager: (any DownloadManagerProtocol)?

    func application(
        _ application: UIApplication,
        handleEventsForBackgroundURLSession identifier: String,
        completionHandler: @Sendable @escaping () -> Void
    ) {
        guard identifier == DownloadManagerConstants.backgroundSessionIdentifier else {
            completionHandler()
            return
        }
        Task {
            await downloadManager?.handleBackgroundEvents(completionHandler: completionHandler)
        }
    }
}
