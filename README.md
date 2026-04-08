# AsyncDownload

An iOS app built to exercise modern Swift concurrency within a file downloading scenario — and to explore Claude's capabilities as a coding assistant.

## Features

- Add downloads by URL
- Live progress tracking per download
- Cancel in-progress downloads
- Remove completed, failed, or cancelled downloads
- Files saved to the Documents directory on completion

## How to run

**Requirements:** Xcode 16+, iOS 17+, [Mint](https://github.com/yonaskolb/Mint)

```bash
# Install Mint
brew install mint

# Install dependencies
mint bootstrap

# Generate Xcode project
mint run xcodegen

# Open in Xcode
open AsyncDownload.xcodeproj
```

**Run tests**
```bash
cd Packages/DownloadManager
swift test
```

> Mocks are regenerated automatically as a pre-build script on every Xcode build.

## What's inside

**Async/await throughout**
- `URLSession.bytes(from:)` for streaming downloads with live progress
- Structured concurrency — one unbroken task chain from `DownloadManager` down to URLSession, enabling cooperative cancellation without manual wiring
- Swift `actor` for `DownloadManager` to protect shared state across concurrent downloads
- `AsyncStream` to broadcast download state changes to the UI

**Architecture**
- MVVM+C with `NavigationPath`-based coordinator
- Local Swift Package (`DownloadManager`) isolating all download logic
- Dependency injection via protocols (`DownloadStorageProtocol`, `NetworkBytesFetcherProtocol`, `DownloadManagerProtocol`)
- Composition root (`DependencyContainer`) wiring dependencies at the app boundary

**Testing**
- Swift Testing (`@Suite`, `@Test`, `#expect`, `#require`)
- Sourcery-generated mocks from protocol annotations (`// sourcery: AutoMockable`)
