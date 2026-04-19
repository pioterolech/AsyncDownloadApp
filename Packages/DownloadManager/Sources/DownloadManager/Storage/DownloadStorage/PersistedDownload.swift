import Foundation
import SwiftData

@Model
final class PersistedDownload {
    var id: UUID
    var urlString: String
    var stateRaw: String
    var progress: Double
    var fileURLString: String?

    init(id: UUID, urlString: String, stateRaw: String, progress: Double, fileURLString: String?) {
        self.id = id
        self.urlString = urlString
        self.stateRaw = stateRaw
        self.progress = progress
        self.fileURLString = fileURLString
    }
}

extension Download {
    init?(_ record: PersistedDownload) {
        guard let url = URL(string: record.urlString),
              let state = DownloadState(rawValue: record.stateRaw) else { return nil }
        let fileURL = record.fileURLString.flatMap { URL(string: $0) }
        self.init(id: record.id, url: url, state: state, progress: record.progress, fileURL: fileURL)
    }
}
