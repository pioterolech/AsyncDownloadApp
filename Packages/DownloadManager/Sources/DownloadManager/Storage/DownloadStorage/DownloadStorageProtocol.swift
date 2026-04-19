import Foundation

// sourcery: AutoMockable
public protocol DownloadStorageProtocol: Sendable {
    func save(_ download: Download) async throws
    func delete(id: UUID) async throws
    func fetchAll() async throws -> [Download]
}
