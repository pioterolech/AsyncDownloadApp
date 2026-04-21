import Foundation

// sourcery: AutoMockable
protocol URLSessionProtocol {
    func downloadTask(with url: URL) -> URLSessionDownloadTask
    func allDownloadTasks() async -> [URLSessionDownloadTask]
}

extension URLSession: URLSessionProtocol {
    func allDownloadTasks() async -> [URLSessionDownloadTask] {
        await withCheckedContinuation { continuation in
            getTasksWithCompletionHandler { _, _, downloadTasks in
                continuation.resume(returning: downloadTasks)
            }
        }
    }
}
