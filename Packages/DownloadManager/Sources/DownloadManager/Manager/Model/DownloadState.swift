public enum DownloadState: Sendable, Equatable {
    case queued
    case downloading
    case completed
    case failed
    case cancelled
}
