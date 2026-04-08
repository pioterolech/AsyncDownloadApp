// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "DownloadManager",
    platforms: [.iOS(.v17), .macOS(.v14)],
    products: [
        .library(name: "DownloadManager", targets: ["DownloadManager"]),
    ],
    targets: [
        .target(name: "DownloadManager"),
        .testTarget(
            name: "DownloadManagerTests",
            dependencies: ["DownloadManager"]
        ),
    ]
)
