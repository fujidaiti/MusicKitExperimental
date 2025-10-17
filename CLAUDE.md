# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

MusicKit experimental app for testing and validating Apple Music API integration patterns. This is a SwiftUI-based iOS application that demonstrates various MusicKit APIs and HTTP API approaches for catalog search, resource retrieval, and music playback.

**Note**: Japanese comments are used throughout the codebase.

## Build & Development Commands

### Building the App
```bash
# Build for physical device (required for MusicKit)
xcodebuild -project MusicAlbums.xcodeproj -scheme MusicAlbums -destination 'generic/platform=iOS' build

# Build specific target
xcodebuild -project MusicAlbums.xcodeproj -scheme MusicAlbumsShare build
```

### Running the App
- **Must run on a physical iOS device** - MusicKit is not fully functional in simulator
- Open `MusicAlbums.xcodeproj` in Xcode and run on a connected device
- Requires valid Apple Developer account with MusicKit entitlement

### Project Structure
- **Targets**: `MusicAlbums` (main app), `MusicAlbumsShare` (share extension)
- **Build Configurations**: Debug, Release
- **Schemes**: MusicAlbums, MusicAlbumsShare

## Architecture

### Directory Structure
- `App/` - App entry point and configuration
- `Screens/` - Main feature screens (search, reverse lookup, mixed-type queries)
- `Components/` - Reusable UI components
- `MusicAlbumsShare/` - Share extension implementation
- `SupportingFiles/` - Info.plist, assets, preview content
- `Configuration/` - Xcode build configuration files

### Main Components

#### Test Screens (ContentView.swift:8)
The app provides four experimental screens:
1. **SearchTestView** - Catalog search using `MusicCatalogSearchRequest`
2. **SearchWithSelectionView** - Batch album lookup by IDs using `MusicCatalogResourceRequest`
3. **MixedTypeSearchView** - Mixed-type (Album/Song/Artist) batch lookup via HTTP API
4. **PlayerQueueTestView** - Queue operations and playback control with `ApplicationMusicPlayer`

#### Apple Music API Approaches

**MusicKit Framework APIs** (preferred for single-type operations):
- `MusicCatalogSearchRequest` - Keyword search for albums, songs, artists, playlists
- `MusicCatalogResourceRequest` - Batch resource retrieval by IDs
- **Type constraint**: Must request one type per API call (Album, Song, Artist separately)

**HTTP API** (AppleMusicHTTPClient.swift:61):
- Use for mixed-type batch operations
- Allows fetching Album/Song/Artist in single request
- Query format: `ids[albums]=123,456&ids[songs]=789&ids[artists]=111`
- Requires developer token management

### Key Implementation Patterns

#### Developer Token Caching (AppleMusicHTTPClient.swift:67)
```swift
private func getDeveloperToken() async throws -> String {
    // 1-hour token cache to reduce API calls
    if let cachedToken = cachedToken,
       let expiration = tokenExpiration,
       Date() < expiration {
        return cachedToken
    }
    let token = try await tokenProvider.developerToken(options: [])
    self.cachedToken = token
    self.tokenExpiration = Date().addingTimeInterval(3600)
    return token
}
```

#### Authorization Flow (WelcomeView.swift:18)
- `WelcomeView` presents on first launch if authorization not granted
- Uses `MusicAuthorization.request()` for permission
- Sheet presentation managed via `PresentationCoordinator`
- Applied to root view with `.welcomeSheet()` modifier

#### Batch Resource Retrieval
For single-type batch operations:
```swift
let albumsRequest = MusicCatalogResourceRequest<Album>(matching: \.id, memberOf: albumIDs)
let albumsResponse = try await albumsRequest.response()
```

For mixed-type operations, use HTTP API via `AppleMusicHTTPClient.fetchMixedResources()`.

### Music Playback

Uses `ApplicationMusicPlayer.shared` for in-app playback that doesn't affect Music app state:
```swift
private let player = ApplicationMusicPlayer.shared
player.queue = [album]  // or Queue(for: tracks, startingAt: track)
try await player.play()
```

Alternative: `SystemMusicPlayer.shared` controls the system Music app state.

### Queue Operations (PlayerQueueTestView.swift)

`ApplicationMusicPlayer` provides advanced queue manipulation capabilities beyond simple playback:

#### Observing Player State
```swift
@ObservedObject private var playerState = ApplicationMusicPlayer.shared.state
@ObservedObject private var playerQueue = ApplicationMusicPlayer.shared.queue

// Access current playback status
playerState.playbackStatus // .playing, .paused, .stopped, etc.

// Access currently playing track
if let currentEntry = playerQueue.currentEntry {
    let title = currentEntry.title
    let isTransient = currentEntry.isTransient
}

// Access all queue entries
let allEntries = playerQueue.entries
```

#### Inserting Tracks
```swift
// Insert track at specific position
let entry = ApplicationMusicPlayer.Queue.Entry(track)
playerQueue.entries.insert(entry, at: 2)

// Check if entry is transient (not yet resolved by playback engine)
if entry.isTransient {
    // Entry is temporary - wait for playback engine to resolve
    // Cannot perform additional insertions until resolved
}
```

#### Removing Tracks
```swift
// Remove single track
playerQueue.entries.remove(at: index)

// Remove multiple tracks
for _ in 0..<count {
    playerQueue.entries.remove(at: playerQueue.entries.count - 1)
}
```

#### Playback Navigation
```swift
// Skip to next track
try await player.skipToNextEntry()

// Skip to previous track
try await player.skipToPreviousEntry()

// Pause/resume
player.pause()
try await player.play()
```

#### Important Considerations

**Transient Entries**: When you insert an item into the queue, the entry is initially marked as "transient" (`isTransient = true`). This indicates it hasn't been fully inserted into the playback queue and has a temporary identifier. Wait for the entry to be resolved before performing additional queue operations.

**Initial Queue Setup**: Always set the queue initially as completely as possible using the queue setter before performing insertions/deletions:
```swift
// Good: Set complete initial queue
player.queue = ApplicationMusicPlayer.Queue(for: tracks, startingAt: nil)

// Then perform insertions once player is prepared
player.queue.entries.insert(entry, at: position)
```

**Queue vs. State Observation**: Both `player.queue` and `player.state` conform to `ObservableObject` and can be used with `@ObservedObject` in SwiftUI for reactive UI updates.

## Setup Requirements

### MusicKit Entitlements
1. Create App ID at [developer.apple.com/account/resources](https://developer.apple.com/account/resources)
2. Enable MusicKit checkbox in App Services tab
3. Use unique bundle identifier (reverse-DNS format)
4. Update Signing & Capabilities in Xcode

### Info.plist Requirements
- MusicKit usage description for authorization prompt
- Background audio mode capability (if needed for background playback)

### Device Requirements
- Physical iOS device required (not simulator)
- Signed in to Apple ID with Apple Music subscription (for catalog playback)

## API Usage Guidelines

### When to Use MusicKit APIs
- Single-type resource queries (all albums, all songs, etc.)
- Search operations
- Accessing user library
- Simple playback scenarios

### When to Use HTTP API
- Mixed-type batch operations (fetching albums + songs + artists together)
- Need for specific query patterns not supported by MusicKit
- Fine-grained control over API responses

### Error Handling
HTTP API errors are typed in `HTTPAPIError` enum:
- `.tokenError` - Developer token issues
- `.networkError` - Network connectivity
- `.apiError` - HTTP status codes
- `.decodingError` - JSON parsing failures

All async operations use Swift concurrency (async/await).

## Testing Approach

This codebase is experimental/validation-focused:
- Each screen tests specific API patterns
- Response times and result counts displayed in UI
- Extensive debug logging with emoji prefixes (🔑, 🚀, ✅, ❌)
- No formal unit tests - manual validation via UI

## Documentation Files

- `MUSICKIT_USAGE.md` - Detailed MusicKit API usage patterns (Japanese)
- `MusicPlayerAPI.md` - Music player class documentation
- `README.md` - Original WWDC sample project setup instructions
