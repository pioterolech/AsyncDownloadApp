import Foundation

protocol DownloadTaskDelegate: AnyObject, Sendable {
    func progress(for taskID: Int, written: Int64, total: Int64) async
    func complete(for taskID: Int, tempURL: URL) async
    func fail(for taskID: Int, error: Error) async
}
