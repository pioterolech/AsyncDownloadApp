import Foundation

public enum DownloadTaskEvent: Sendable {
    case progress(Int64, Int64)
    case completed(URL)
}
