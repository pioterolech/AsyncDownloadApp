import SwiftUI
import DownloadManager

struct DownloadRowView: View {
    let download: Download
    let onCancel: () -> Void
    let onRemove: () -> Void

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

            HStack {
                stateLabel
                Spacer()
                actionButtons
            }
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

    @ViewBuilder
    private var actionButtons: some View {
        HStack(spacing: 12) {
            if download.state == .downloading || download.state == .queued {
                Button(action: onCancel) {
                    Image(systemName: "xmark")
                }.buttonStyle(.borderless).foregroundStyle(.red)
            }
            Button(action: onRemove) {
                Image(systemName: "trash")
            }.buttonStyle(.borderless).foregroundStyle(.secondary)
        }
    }
}
