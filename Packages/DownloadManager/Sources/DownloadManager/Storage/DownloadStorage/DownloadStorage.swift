import Foundation
import SwiftData

@ModelActor
public actor DownloadStorage: DownloadStorageProtocol {

    public static func makeContainer() throws -> ModelContainer {
        try ModelContainer(for: PersistedDownload.self)
    }

    public func save(_ record: PersistedDownload) throws {
        if let existing = try fetchRecord(id: record.id) {
            existing.stateRaw = record.stateRaw
            existing.progress = record.progress
            existing.fileURLString = record.fileURLString
        } else {
            modelContext.insert(record)
        }
        try modelContext.save()
    }

    public func delete(id: UUID) throws {
        guard let record = try fetchRecord(id: id) else { return }
        modelContext.delete(record)
        try modelContext.save()
    }

    public func fetchAll() throws -> [PersistedDownload] {
        try modelContext.fetch(FetchDescriptor<PersistedDownload>())
    }

    // MARK: - Private

    private func fetchRecord(id: UUID) throws -> PersistedDownload? {
        var descriptor = FetchDescriptor<PersistedDownload>(predicate: #Predicate { $0.id == id })
        descriptor.fetchLimit = 1
        return try modelContext.fetch(descriptor).first
    }
}
