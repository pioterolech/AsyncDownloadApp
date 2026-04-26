import SwiftUI
import QuickLook
import DownloadManager

struct DownloadListView: View {
    @State private var viewModel: DownloadListViewModel
    let onAddTapped: () -> Void

    init(viewModel: DownloadListViewModel, onAddTapped: @escaping () -> Void) {
        _viewModel = State(wrappedValue: viewModel)
        self.onAddTapped = onAddTapped
    }

    @State private var previewURL: URL?

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
                            .contentShape(Rectangle())
                            .onTapGesture {
                                if let fileURL = download.fileURL {
                                    previewURL = fileURL
                                }
                            }
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
                Button("Add Download", systemImage: "plus", action: onAddTapped)
            }
        }
        .quickLookPreview($previewURL)
    }
}
