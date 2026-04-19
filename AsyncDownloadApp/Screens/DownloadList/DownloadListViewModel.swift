import Foundation
import DownloadManager

@MainActor
final class DownloadListViewModel: ObservableObject {
    @Published private(set) var downloads: [Download] = []

    private let downloadManager: any DownloadManagerProtocol
    private var streamTask: Task<Void, Never>?

    init(downloadManager: any DownloadManagerProtocol) {
        self.downloadManager = downloadManager
        streamTask = Task { [weak self] in
            guard let self else { return }
            for await snapshot in self.downloadManager.downloadStream {
                self.downloads = snapshot
            }
        }
    }

    deinit {
        streamTask?.cancel()
    }

    func cancel(id: UUID) {
        Task { await downloadManager.cancel(id: id) }
    }

    func remove(id: UUID) {
        Task { try await downloadManager.remove(id: id) }
    }
}
