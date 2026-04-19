import Foundation

public enum DownloadError: Error, Sendable {
    case invalidURL
    case networkError(underlying: Error)
    case cancelled
    case unknown
}
