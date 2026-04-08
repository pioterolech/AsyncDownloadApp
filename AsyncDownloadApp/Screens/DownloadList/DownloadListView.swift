import SwiftUI
import DownloadManager

struct DownloadListView: View {
    @ObservedObject var viewModel: DownloadListViewModel
    let onAddTapped: () -> Void

    var body: some View {
        Group {
            if viewModel.downloads.isEmpty {
                ContentUnavailableView(
                    "No Downloads",
                    systemImage: "arrow.down.circle",
                    description: Text("Tap + to add a URL.")
                )
            } else {
                List {
                    ForEach(viewModel.downloads) { download in
                        DownloadRowView(
                            download: download,
                            onCancel: { viewModel.cancel(id: download.id) },
                            onRemove: { viewModel.remove(id: download.id) }
                        )
                    }
                }
            }
        }
        .navigationTitle("Downloads")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button(action: onAddTapped) {
                    Image(systemName: "plus")
                }
            }
        }
    }
}
