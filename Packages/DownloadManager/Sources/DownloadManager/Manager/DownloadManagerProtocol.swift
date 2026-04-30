import Foundation

// sourcery: AutoMockable
public protocol DownloadManagerProtocol: Sendable {
    var downloadStream: AsyncStream<[Download]> { get }
    func startup() async throws
    func add(url: URL) async
    func cancel(id: UUID) async
    func remove(id: UUID) async throws
    func handleBackgroundEvents(completionHandler: @escaping @Sendable () -> Void) async
}
