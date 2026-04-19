public enum DownloadState: String, Sendable, Equatable {
    case queued
    case downloading
    case completed
    case failed
    case cancelled
}
