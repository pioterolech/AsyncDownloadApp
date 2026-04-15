import Foundation

public enum DownloadTaskEvent {
    case progress(Int64, Int64)
    case completed(URL)
}
