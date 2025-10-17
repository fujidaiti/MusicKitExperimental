# MusicKit Queue & Playback Operations Tutorial

This tutorial explains how to perform common queue and playback operations using MusicKit's `ApplicationMusicPlayer`.

## Table of Contents
- [Player Selection](#player-selection)
- [Observing Player State](#observing-player-state)
- [Starting Playback](#starting-playback)
- [Basic Playback Controls](#basic-playback-controls)
- [Queue Manipulation](#queue-manipulation)

---

## Player Selection

MusicKit provides two music player classes:

| Player | Use Case |
|--------|----------|
| `ApplicationMusicPlayer` | Playback within your app only. Doesn't affect the Music app's state. |
| `SystemMusicPlayer` | Controls the system Music app. Shares state with Music app. |

**API:** `ApplicationMusicPlayer.shared`

```swift
// Access the shared application music player
let player = ApplicationMusicPlayer.shared
```

---

## Observing Player State

To observe playback state and queue changes in SwiftUI, use `@ObservedObject` with the player's observable properties.

**API:**
- `ApplicationMusicPlayer.shared.state` - Observes playback status, repeat mode, shuffle mode
- `ApplicationMusicPlayer.shared.queue` - Observes queue entries and current playing track

```swift
struct MyPlayerView: View {
    // Observe player state changes
    @ObservedObject private var playerState = ApplicationMusicPlayer.shared.state
    @ObservedObject private var playerQueue = ApplicationMusicPlayer.shared.queue
    private let player = ApplicationMusicPlayer.shared

    var body: some View {
        VStack {
            // Access current playback status
            Text("Status: \(playerState.playbackStatus == .playing ? "Playing" : "Paused")")

            // Access queue count
            Text("Tracks in queue: \(playerQueue.entries.count)")

            // Access currently playing track
            if let currentEntry = playerQueue.currentEntry {
                Text("Now playing: \(currentEntry.title ?? "Unknown")")
            }
        }
    }
}
```

---

## Starting Playback

### Initialize Queue with Tracks

**API:** `ApplicationMusicPlayer.Queue(for:startingAt:)`

```swift
// Initialize queue with an array of tracks
let tracks: [Track] = // ... your tracks
player.queue = ApplicationMusicPlayer.Queue(for: tracks, startingAt: nil)

// Prepare the player to populate the queue
try await player.prepareToPlay()

// Start playback
try await player.play()
```

### Initialize Queue with an Album

**API:** `ApplicationMusicPlayer.Queue(album:startingAt:)`

```swift
let album: Album = // ... your album
let firstTrack = album.tracks?.first

// Set queue to play entire album
player.queue = ApplicationMusicPlayer.Queue(
    album: album,
    startingAt: firstTrack
)

try await player.play()
```

### Initialize Queue with a Playlist

**API:** `ApplicationMusicPlayer.Queue(playlist:startingAt:)`

```swift
let playlist: Playlist = // ... your playlist
let firstEntry = playlist.entries?.first

// Set queue to play entire playlist
player.queue = ApplicationMusicPlayer.Queue(
    playlist: playlist,
    startingAt: firstEntry
)

try await player.play()
```

---

## Basic Playback Controls

### Play

**API:** `player.play()`

```swift
try await player.play()
```

### Pause

**API:** `player.pause()`

```swift
player.pause()
```

### Toggle Play/Pause

```swift
if playerState.playbackStatus == .playing {
    player.pause()
} else {
    try await player.play()
}
```

### Skip to Next Track

**API:** `player.skipToNextEntry()`

```swift
try await player.skipToNextEntry()
```

### Skip to Previous Track

**API:** `player.skipToPreviousEntry()`

```swift
try await player.skipToPreviousEntry()
```

### Stop Playback

**API:** `player.stop()`

```swift
player.stop()
```

---

## Queue Manipulation

### Insert Single Track at Specific Position

**API:** `ApplicationMusicPlayer.Queue.Entry(track)` and `playerQueue.entries.insert(_:at:)`

```swift
let track: Track = // ... track to insert
let insertPosition = 2

// Create a queue entry
let entry = ApplicationMusicPlayer.Queue.Entry(track)

// Insert at position
player.queue.entries.insert(entry, at: insertPosition)
```

### Insert Multiple Tracks After Current Track

```swift
let songsToInsert: [Song] = // ... songs to insert

// Find current track position
guard let currentEntry = player.queue.currentEntry,
      let currentIndex = player.queue.entries.firstIndex(where: { $0.id == currentEntry.id }) else {
    return
}

// Insert position is right after current track
let insertPosition = currentIndex + 1

// Insert songs one by one
for (offset, song) in songsToInsert.enumerated() {
    let entry = ApplicationMusicPlayer.Queue.Entry(song)
    let position = insertPosition + offset
    if position <= player.queue.entries.count {
        player.queue.entries.insert(entry, at: position)
    }
}
```

### Remove Track at Specific Index

**API:** `playerQueue.entries.remove(at:)`

```swift
let indexToRemove = 3
player.queue.entries.remove(at: indexToRemove)
```

### Remove Multiple Tracks by ID

```swift
let trackIDsToRemove: Set<ApplicationMusicPlayer.Queue.Entry.ID> = // ... IDs to remove

// Get indices in reverse order (to maintain correct indices during removal)
let indicesToRemove = player.queue.entries.enumerated()
    .filter { trackIDsToRemove.contains($0.element.id) }
    .map { $0.offset }
    .sorted(by: >)

// Remove tracks
for index in indicesToRemove {
    player.queue.entries.remove(at: index)
}
```

### Protect Currently Playing Track from Removal

```swift
let trackIDsToRemove: Set<ApplicationMusicPlayer.Queue.Entry.ID> = // ... IDs

// Get current playing entry ID
let currentPlayingID = player.queue.currentEntry?.id

// Filter out currently playing track
let safeToRemove = trackIDsToRemove.filter { $0 != currentPlayingID }

// Remove tracks (using pattern from above)
let indicesToRemove = player.queue.entries.enumerated()
    .filter { safeToRemove.contains($0.element.id) }
    .map { $0.offset }
    .sorted(by: >)

for index in indicesToRemove {
    player.queue.entries.remove(at: index)
}
```

### Clear Queue

**API:** `ApplicationMusicPlayer.Queue([])` (empty array)

```swift
player.queue = ApplicationMusicPlayer.Queue([])
```

---

## Understanding Transient Entries

When you insert an entry into the queue, it may initially be marked as **transient** (`isTransient = true`). This means:

- The entry hasn't been fully processed by the playback engine
- The entry has a temporary identifier
- You should wait for it to resolve before performing additional operations

**Check if entry is transient:**

```swift
let entry = ApplicationMusicPlayer.Queue.Entry(track)
player.queue.entries.insert(entry, at: 2)

if entry.isTransient {
    print("Entry is transient - waiting for playback engine to resolve")
    // Avoid additional insertions until resolved
}
```

---

## Best Practices

### 1. Always Prepare the Player

When setting a new queue, call `prepareToPlay()` before playing:

```swift
player.queue = ApplicationMusicPlayer.Queue(for: tracks, startingAt: nil)
try await player.prepareToPlay()  // Ensures queue is ready
try await player.play()
```

### 2. Handle Async Operations Properly

Most playback operations are asynchronous. Always use `await` and handle errors:

```swift
do {
    try await player.play()
} catch {
    print("Playback failed: \(error)")
}
```

### 3. Observe State Changes in SwiftUI

Use `@ObservedObject` to automatically update your UI when player state changes:

```swift
@ObservedObject private var playerState = ApplicationMusicPlayer.shared.state
@ObservedObject private var playerQueue = ApplicationMusicPlayer.shared.queue
```

### 4. Remove Tracks in Reverse Order

When removing multiple tracks by index, always remove in reverse order to maintain correct indices:

```swift
let indices = [2, 5, 8].sorted(by: >)  // [8, 5, 2]
for index in indices {
    player.queue.entries.remove(at: index)
}
```

---

## API Reference

For complete API documentation, see:
- [MusicPlayerAPI.md](./MusicPlayerAPI.md) - Detailed API reference for all music player classes
- [Apple MusicKit Documentation](https://developer.apple.com/documentation/musickit)
