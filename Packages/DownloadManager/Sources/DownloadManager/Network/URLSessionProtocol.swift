import Foundation

protocol URLSessionProtocol {
    func downloadTask(with url: URL) -> URLSessionDownloadTask
}

extension URLSession: URLSessionProtocol {}
