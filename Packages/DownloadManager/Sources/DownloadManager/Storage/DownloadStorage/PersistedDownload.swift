import Foundation
import SwiftData

@Model
public final class PersistedDownload {
    @Attribute(.unique) public var id: UUID
    public var urlString: String
    public var stateRaw: String
    public var progress: Double
    public var fileURLString: String?

    public init(id: UUID, urlString: String, stateRaw: String, progress: Double, fileURLString: String?) {
        self.id = id
        self.urlString = urlString
        self.stateRaw = stateRaw
        self.progress = progress
        self.fileURLString = fileURLString
    }
}
