import Foundation
import DownloadManager

@MainActor
final class AddLinkViewModel: ObservableObject {
    @Published var urlText: String = ""
    @Published private(set) var validationError: String? = nil

    private let downloadManager: any DownloadManagerProtocol

    init(downloadManager: any DownloadManagerProtocol) {
        self.downloadManager = downloadManager
    }

    func add() async -> Bool {
        let trimmed = urlText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard let url = URL(string: trimmed),
              url.scheme == "https" || url.scheme == "http",
              url.host != nil else {
            validationError = "Please enter a valid URL (e.g. https://example.com/file.zip)"
            return false
        }
        validationError = nil
        await downloadManager.add(url: url)
        return true
    }
}
