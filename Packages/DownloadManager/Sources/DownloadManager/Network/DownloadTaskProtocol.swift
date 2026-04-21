import Foundation

// sourcery: AutoMockable
public protocol DownloadTaskProtocol: Sendable {
    func prepareForReconnection() async
    func handleBackgroundEvents(completionHandler: @escaping @Sendable () -> Void) async
    func fetch(from url: URL) async -> AsyncThrowingStream<DownloadTaskEvent, Error>
}
