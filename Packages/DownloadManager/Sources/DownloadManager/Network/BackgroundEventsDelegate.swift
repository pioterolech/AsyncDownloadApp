import Foundation

protocol BackgroundEventsDelegate: AnyObject, Sendable {
    func urlSessionDidFinishEvents() async
}
