# Async Download Manager — Specification

## Overview

An iOS app for managing file downloads, built as an exercise in Swift async/await concurrency. No persistence layer.

---

## Architecture

- **Pattern:** MVVM+C (Model-View-ViewModel + Coordinator)
- **Download logic:** Extracted into an isolated Swift Package (local package)
- **Concurrency:** async/await throughout — no completion handlers or Combine where avoidable

---

## Swift Package: `DownloadManager`

A standalone Swift package containing all core download logic, decoupled from the app layer.

### Responsibilities
- Managing concurrent downloads using `URLSession` with async/await
- Exposing an `AsyncStream` or `AsyncSequence` for download progress updates
- Supporting pause, resume, cancel per download task
- Error handling and propagation

### Public API (outline)
```swift
public actor DownloadManager {
    public func add(url: URL) async -> Download
    public func pause(id: UUID) async
    public func resume(id: UUID) async
    public func cancel(id: UUID) async
    public func remove(id: UUID) async
    public var downloads: AsyncStream<[Download]> { get }
}

public struct Download: Identifiable, Sendable {
    public let id: UUID
    public let url: URL
    public var state: DownloadState
    public var progress: Double // 0.0 – 1.0
    public var error: DownloadError?
}

public enum DownloadState: Sendable {
    case queued
    case downloading
    case paused
    case completed
    case failed
    case cancelled
}

public enum DownloadError: Error, Sendable {
    case invalidURL
    case networkError(underlying: Error)
    case cancelled
    case unknown
}
```

### Concurrency model
- Downloads run in parallel using Swift's structured concurrency (`TaskGroup` or individual `Task`s)
- The `DownloadManager` is an `actor` to protect shared state
- Progress is streamed via `AsyncStream`

---

## iOS App

### Screens

#### 1. Downloads List Screen
- Shows all current downloads (active, paused, completed, failed, cancelled)
- Each row displays:
  - URL / filename
  - Download state label
  - Progress bar (for active/paused downloads)
  - Error message (if failed)
- Per-row actions:
  - **Pause** (active downloads)
  - **Resume** (paused downloads)
  - **Cancel** (active or paused downloads)
  - **Remove** (any state)
- Navigation bar button to open the Add Link screen

#### 2. Add Link Screen
- Text field for entering a URL
- **Add** button to start the download
- Inline validation error if the URL is malformed
- Dismisses on successful add

---

## Error Handling

- Invalid URL entered by the user → shown inline on the Add Link screen
- Network errors during download → download moves to `failed` state, error shown in the list row
- Errors are surfaced via `DownloadError` from the package and displayed in the UI via the ViewModel

---

## What's Out of Scope

- Persistence (no CoreData, UserDefaults, or file caching between app launches)
- Authentication / headers
- Background downloads (URLSession background configuration)
- File management after download completes

---

## Project Structure

```
async-download/
├── AsyncDownloadApp/          # iOS app target
│   ├── App/
│   │   └── AsyncDownloadApp.swift
│   ├── Coordinators/
│   │   └── AppCoordinator.swift
│   ├── Screens/
│   │   ├── DownloadList/
│   │   │   ├── DownloadListView.swift
│   │   │   └── DownloadListViewModel.swift
│   │   └── AddLink/
│   │       ├── AddLinkView.swift
│   │       └── AddLinkViewModel.swift
│   └── Views/
│       └── DownloadRowView.swift
└── Packages/
    └── DownloadManager/       # Isolated Swift Package
        ├── Package.swift
        └── Sources/
            └── DownloadManager/
                ├── DownloadManager.swift
                ├── Download.swift
                ├── DownloadState.swift
                └── DownloadError.swift
```
