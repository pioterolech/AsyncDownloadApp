import Foundation

extension DownloadError: LocalizedError {
    public var errorDescription: String? {
        switch self {
        case .invalidURL:
            "Invalid URL"
        case .networkError(let underlying):
            underlying.localizedDescription
        case .cancelled:
            "Download cancelled"
        case .unknown:
            "An unknown error occurred"
        }
    }
}
