import Foundation

public struct Download: Identifiable, Sendable {
    public let id: UUID
    public let url: URL
    public var state: DownloadState
    public var progress: Double // 0.0 – 1.0
    public var error: DownloadError?
    public var fileURL: URL?

    public init(id: UUID = UUID(), url: URL, state: DownloadState = .queued, progress: Double = 0, error: DownloadError? = nil, fileURL: URL? = nil) {
        self.id = id
        self.url = url
        self.state = state
        self.progress = progress
        self.error = error
        self.fileURL = fileURL
    }
}
