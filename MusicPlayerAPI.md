# Music Players

> Source: Multiple Apple MusicKit documentation pages

This group contains the core music playback classes in MusicKit, providing different approaches to playing music content within your app.

## MusicPlayer
- **Swift Declaration**: `class MusicPlayer`
- **Purpose**: An object your app uses to play music - the base class for all music players
- **Source**: [Apple MusicKit Documentation](https://developer.apple.com/documentation/musickit/musicplayer)
- **Properties**:
  - `var isPreparedToPlay: Bool` - A Boolean value that indicates whether a music player is ready to play
  - `var playbackTime: TimeInterval` - The current playback time, in seconds, of the current entry
  - `let state: MusicPlayer.State` - An object that exposes the observable properties of the music player
- **Methods**:
  - `func beginSeekingBackward()` - Begins seeking backward through the music content
  - `func beginSeekingForward()` - Begins seeking forward through the music content
  - `func endSeeking()` - Ends forward and backward seeking through the music content
  - `func pause()` - Pauses playback of the current entry
  - `func play() async throws` - Initiates playback from the current queue
  - `func prepareToPlay() async throws` - Prepares the current queue for playback, interrupting any active (nonmixable) audio sessions
  - `func restartCurrentEntry()` - Restarts playback at the beginning of the currently playing entry
  - `func skipToNextEntry() async throws` - Starts playback of the next entry in the playback queue
  - `func skipToPreviousEntry() async throws` - Starts playback of the previous entry in the playback queue
  - `func stop()` - Ends playback of the current entry
- **Nested Types**:
  - `class Queue` - A representation of the playback queue for a music player
  - `class State` - An object that exposes the observable properties of a music player
  - `enum PlaybackStatus` - The music player playback status modes (interrupted, paused, playing, seekingBackward, seekingForward, stopped)
  - `enum RepeatMode` - The repeat modes for the music player
  - `enum ShuffleMode` - The shuffle modes for the music player
  - `enum Transition` - The transition applied between playing items
- **Usage**: This is the base class inherited by ApplicationMusicPlayer and SystemMusicPlayer

## ApplicationMusicPlayer
- **Swift Declaration**: `class ApplicationMusicPlayer`
- **Purpose**: An object your app uses to play music in a way that doesn't affect the Music app's state
- **Source**: [Apple MusicKit Documentation](https://developer.apple.com/documentation/musickit/applicationmusicplayer)
- **Properties**:
  - `var queue: ApplicationMusicPlayer.Queue` - The playback queue for the application music player
  - `var transition: MusicPlayer.Transition` - The transition between items for the application music player
- **Type Properties**:
  - `static let shared: ApplicationMusicPlayer` - The shared application music player, which plays music specifically for your app
- **Nested Types**:
  - `class Queue` - Specialized queue implementation that inherits from MusicPlayer.Queue
- **Usage**: The application music player plays music specifically for your app, and doesn't affect the Music app's state. If your app includes a background audio mode in your Info.plist file, the application music player continues playing the current music item when your app moves to the background.
- **Inheritance**: Inherits from [MusicPlayer](#musicplayer)

## SystemMusicPlayer
- **Swift Declaration**: `class SystemMusicPlayer`
- **Purpose**: An object your app uses to play music by controlling the Music app's state
- **Source**: [Apple MusicKit Documentation](https://developer.apple.com/documentation/musickit/systemmusicplayer)
- **Properties**:
  - `var queue: MusicPlayer.Queue` - The playback queue for the system music player
- **Type Properties**:
  - `static let shared: SystemMusicPlayer` - The shared system music player, which controls the Music app's state
- **Usage**: The system music player employs the Music app on your behalf. When your app accesses the system music player for the first time, it assumes the current Music app state and controls it as your app runs. The shared state includes:
  - Repeat mode (see [MusicPlayer.RepeatMode](#musicplayer))
  - Shuffle mode (see [MusicPlayer.ShuffleMode](#musicplayer))
  - Playback status (see `MusicPlayer/PlaybackStatus`)

  The system music player doesn't share other aspects of the Music app's state. Music that's playing continues to play when your app moves to the background.
- **Inheritance**: Inherits from [MusicPlayer](#musicplayer)

## ApplicationMusicPlayer.Queue
- **Swift Declaration**: `class Queue`
- **Purpose**: Specialized queue implementation for ApplicationMusicPlayer
- **Source**: [Apple MusicKit Documentation](https://developer.apple.com/documentation/musickit/applicationmusicplayer/queue-swift.class)
- **Properties**:
  - `var entries: ApplicationMusicPlayer.Queue.Entries` - The queue entries
- **Initializers**:
  - `init<S>(S, startingAt: S.Element?)` - Creates a playback queue with playback queue entries
  - `init(album: Album, startingAt: Track)` - Creates a playback queue with an album and a specific track for the player to start playback
  - `init(arrayLiteral: any PlayableMusicItem...)` - Array literal initializer
  - `init<S, PlayableMusicItemType>(for: S, startingAt: S.Element?)` - Creates a playback queue with playable music items
  - `init(playlist: Playlist, startingAt: Playlist.Entry)` - Creates a playback queue with a playlist and a specific playlist entry for the player to start playback
- **Nested Types**:
  - `struct Entries` - Queue entries structure
- **Inheritance**: Inherits from [MusicPlayer.Queue](#musicplayer)
- **Conformances**: [`Equatable`](/documentation/Swift/Equatable), [`ExpressibleByArrayLiteral`](/documentation/Swift/ExpressibleByArrayLiteral), [`Hashable`](/documentation/Swift/Hashable), [`ObservableObject`](/documentation/Combine/ObservableObject)

## Related Types

### MusicPlayer.PlaybackStatus
The music player playback status modes:
- `case interrupted` - The music player is in an interrupted state, such as from an incoming phone call
- `case paused` - The music player is in a paused state
- `case playing` - The music player is playing
- `case seekingBackward` - The music player is seeking backward
- `case seekingForward` - The music player is seeking forward
- `case stopped` - The music player is in a stopped state

### See Also
- [protocol PlayableMusicItem](../protocols/PlaybackProtocols.md#playablemusicitem) - A set of properties that a music player uses to initiate playback for a music item
- [struct PlayParameters](../utilities/CoreDataTypes.md#playparameters) - An opaque object that represents parameters to initiate playback of a playable music item using a music player
