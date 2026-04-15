import Foundation

protocol DownloadTaskDelegate: AnyObject {
    func progress(for taskID: Int, written: Int64, total: Int64) async
    func complete(for taskID: Int, location: URL) async
    func fail(for taskID: Int, error: Error) async
}
