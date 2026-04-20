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
                        DownloadRowView(download: download)
                            .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                                Button(role: .destructive) {
                                    viewModel.remove(id: download.id)
                                } label: {
                                    Label("Delete", systemImage: "trash")
                                }
                                if download.state == .downloading || download.state == .queued {
                                    Button {
                                        viewModel.cancel(id: download.id)
                                    } label: {
                                        Label("Cancel", systemImage: "xmark")
                                    }
                                    .tint(.orange)
                                }
                            }
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
