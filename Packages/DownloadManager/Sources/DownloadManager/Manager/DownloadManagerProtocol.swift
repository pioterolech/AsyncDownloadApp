import Foundation

// sourcery: AutoMockable
public protocol DownloadManagerProtocol: Sendable {
    var downloadStream: AsyncStream<[Download]> { get }
    func add(url: URL) async
    func cancel(id: UUID) async
    func remove(id: UUID) async throws
}
