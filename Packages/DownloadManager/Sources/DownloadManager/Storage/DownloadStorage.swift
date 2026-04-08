import Foundation

// sourcery: AutoMockable
public protocol DownloadStorageProtocol {
    func createTempFile(for id: UUID) -> URL
    func deleteTempFile(for id: UUID)
    func moveToDocuments(from tempURL: URL, id: UUID, sourceURL: URL) throws -> URL
}

final class DownloadStorage: DownloadStorageProtocol {

    private let fileManager: FileManager

    init(fileManager: FileManager = .default) {
        self.fileManager = fileManager
    }

    func createTempFile(for id: UUID) -> URL {
        let url = tempURL(for: id)
        fileManager.createFile(atPath: url.path, contents: nil)
        return url
    }

    func deleteTempFile(for id: UUID) {
        try? fileManager.removeItem(at: tempURL(for: id))
    }

    func moveToDocuments(from tempURL: URL, id: UUID, sourceURL: URL) throws -> URL {
        let documentsURL = try fileManager.url(
            for: .documentDirectory,
            in: .userDomainMask,
            appropriateFor: nil,
            create: false
        )

        let filename = sourceURL.lastPathComponent.isEmpty ? id.uuidString : sourceURL.lastPathComponent
        var destURL = documentsURL.appendingPathComponent(filename)

        if fileManager.fileExists(atPath: destURL.path) {
            let name = (filename as NSString).deletingPathExtension
            let ext = (filename as NSString).pathExtension
            let unique = ext.isEmpty
                ? "\(name)-\(id.uuidString)"
                : "\(name)-\(id.uuidString).\(ext)"
            destURL = documentsURL.appendingPathComponent(unique)
        }

        try fileManager.moveItem(at: tempURL, to: destURL)
        return destURL
    }

    // MARK: - Private

    private func tempURL(for id: UUID) -> URL {
        fileManager.temporaryDirectory.appendingPathComponent("\(id.uuidString).download")
    }
}
