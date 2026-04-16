import Foundation

public protocol DownloadTaskProtocol: Sendable {
    func fetch(from url: URL) async -> AsyncThrowingStream<DownloadTaskEvent, Error>
}
