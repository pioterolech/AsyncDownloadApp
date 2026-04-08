import Foundation

public protocol DownloadManagerProtocol {
    var downloadStream: AsyncStream<[Download]> { get }
    func add(url: URL) async
    func cancel(id: UUID) async
    func remove(id: UUID) async
}

extension DownloadManager: DownloadManagerProtocol {}
