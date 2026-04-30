import Foundation

// sourcery: AutoMockable
public protocol DownloadTaskProtocol: Sendable {
    func fetch(from url: URL, id: UUID) async -> AsyncThrowingStream<DownloadTaskEvent, Error>
}
