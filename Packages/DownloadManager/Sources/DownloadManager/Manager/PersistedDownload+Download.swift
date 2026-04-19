import Foundation

enum PersistedDownloadMappingError: Error {
    case invalidURL(String)
    case invalidState(String)
    case invalidFileURL(String)
}

extension Download {
    init(persisted: PersistedDownload) throws {
        guard let url = URL(string: persisted.urlString) else {
            throw PersistedDownloadMappingError.invalidURL(persisted.urlString)
        }
        guard let state = DownloadState(rawValue: persisted.stateRaw) else {
            throw PersistedDownloadMappingError.invalidState(persisted.stateRaw)
        }
        var fileURL: URL?
        if let fileURLString = persisted.fileURLString {
            guard let url = URL(string: fileURLString) else {
                throw PersistedDownloadMappingError.invalidFileURL(fileURLString)
            }
            fileURL = url
        }
        self.init(
            id: persisted.id,
            url: url,
            state: state,
            progress: persisted.progress,
            fileURL: fileURL
        )
    }
}
