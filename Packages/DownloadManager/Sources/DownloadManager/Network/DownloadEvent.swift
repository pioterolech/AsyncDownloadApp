import Foundation

public enum DownloadEvent {
    case progress(Int64, Int64)
    case completed(URL)
}
