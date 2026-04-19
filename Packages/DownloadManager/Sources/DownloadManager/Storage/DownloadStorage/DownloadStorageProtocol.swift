import Foundation

// sourcery: AutoMockable
public protocol DownloadStorageProtocol: Sendable {
    func save(_ record: PersistedDownload) async throws
    func delete(id: UUID) async throws
    func fetchAll() async throws -> [PersistedDownload]
}
