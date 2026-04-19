import Foundation
import SwiftData

@ModelActor
public actor DownloadStorage: DownloadStorageProtocol {

    public static func makeContainer() throws -> ModelContainer {
        try ModelContainer(for: PersistedDownload.self)
    }

    public func save(_ download: Download) throws {
        if let existing = try fetchRecord(id: download.id) {
            existing.stateRaw = download.state.rawValue
            existing.progress = download.progress
            existing.fileURLString = download.fileURL?.absoluteString
        } else {
            modelContext.insert(PersistedDownload(
            id: download.id,
            urlString: download.url.absoluteString,
            stateRaw: download.state.rawValue,
            progress: download.progress,
            fileURLString: download.fileURL?.absoluteString
        ))
        }
        try modelContext.save()
    }

    public func delete(id: UUID) throws {
        guard let record = try fetchRecord(id: id) else { return }
        modelContext.delete(record)
        try modelContext.save()
    }

    public func fetchAll() throws -> [Download] {
        try modelContext.fetch(FetchDescriptor<PersistedDownload>()).compactMap(Download.init)
    }

    // MARK: - Private

    private func fetchRecord(id: UUID) throws -> PersistedDownload? {
        try modelContext.fetch(FetchDescriptor<PersistedDownload>()).first { $0.id == id }
    }
}
