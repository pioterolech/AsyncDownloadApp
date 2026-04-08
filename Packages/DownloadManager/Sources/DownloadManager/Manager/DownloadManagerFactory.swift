import Foundation

public final class DownloadManagerFactory {

    private let session: URLSession

    public init(session: URLSession = .shared) {
        self.session = session
    }

    public func make() -> any DownloadManagerProtocol {
        DownloadManager(
            storage: DownloadStorage(),
            streamer: NetworkBytesFetcher(session: session)
        )
    }
}
