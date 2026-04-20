import SwiftUI
import DownloadManager

struct DownloadRowView: View {
    let download: Download

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(download.url.lastPathComponent.isEmpty ? download.url.absoluteString : download.url.lastPathComponent)
                .font(.body)
                .lineLimit(1)
                .truncationMode(.middle)

            Text(download.url.absoluteString)
                .font(.caption2)
                .foregroundStyle(.secondary)
                .lineLimit(1)
                .truncationMode(.middle)

            if download.state == .downloading {
                ProgressView(value: download.progress)
            }

            stateLabel
        }
        .padding(.vertical, 4)
    }

    @ViewBuilder
    private var stateLabel: some View {
        switch download.state {
        case .queued:
            Label("Queued", systemImage: "clock")
                .font(.caption).foregroundStyle(.secondary)
        case .downloading:
            Label(String(format: "%.0f%%", download.progress * 100), systemImage: "arrow.down.circle.fill")
                .font(.caption).foregroundStyle(.blue)
        case .completed:
            VStack(alignment: .leading, spacing: 2) {
                Label("Completed", systemImage: "checkmark.circle.fill")
                    .font(.caption).foregroundStyle(.green)
                if let fileURL = download.fileURL {
                    Text(fileURL.lastPathComponent)
                        .font(.caption2).foregroundStyle(.secondary)
                }
            }
        case .failed:
            VStack(alignment: .leading, spacing: 2) {
                Label("Failed", systemImage: "xmark.circle.fill")
                    .font(.caption).foregroundStyle(.red)
                if let error = download.error {
                    Text(error.localizedDescription)
                        .font(.caption2).foregroundStyle(.red)
                }
            }
        case .cancelled:
            Label("Cancelled", systemImage: "slash.circle.fill")
                .font(.caption).foregroundStyle(.secondary)
        }
    }
}
