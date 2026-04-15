import Foundation

public protocol DownloadTaskProtocol {
    func fetch(from url: URL) async -> AsyncThrowingStream<DownloadTaskEvent, Error>
}
