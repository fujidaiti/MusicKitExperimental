/*
ApplicationMusicPlayer キュー操作とプレイバック制御のデモ
Queue Operations and Playback Control Demo
*/

import MusicKit
import SwiftUI

struct PlayerQueueTestView: View {
    @State private var searchTerm = ""
    @State private var searchResults: [Album] = []
    @State private var selectedAlbum: Album?
    @State private var albumTracks: [Track] = []
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var showError = false
    @State private var queueUpdateTrigger = 0

    // Player observables
    @ObservedObject private var playerState = ApplicationMusicPlayer.shared.state
    @ObservedObject private var playerQueue = ApplicationMusicPlayer.shared.queue
    private let player = ApplicationMusicPlayer.shared

    // Operation logs
    @State private var operationLogs: [String] = []

    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                // Search section
                searchSection

                Divider()

                // Current playback info
                currentPlaybackSection

                Divider()

                // Queue controls
                queueControlsSection

                Divider()

                // Operation logs
                operationLogsSection
            }
        }
        .id(queueUpdateTrigger)
        .navigationTitle("Player Queue Operations")
        .navigationBarTitleDisplayMode(.inline)
        .alert("Error", isPresented: $showError) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(errorMessage ?? "Unknown error")
        }
    }

    // MARK: - Search Section

    private var searchSection: some View {
        VStack(spacing: 8) {
            Text("1. Search for Album and Load Tracks")
                .font(.subheadline)
                .fontWeight(.semibold)
                .frame(maxWidth: .infinity, alignment: .leading)

            HStack {
                TextField("Search albums", text: $searchTerm)
                    .textFieldStyle(RoundedBorderTextFieldStyle())

                Button("Search") {
                    performSearch()
                }
                .buttonStyle(.prominent)
                .disabled(searchTerm.isEmpty || isLoading)
            }

            if !searchResults.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(searchResults, id: \.id) { album in
                            AlbumCard(album: album, isSelected: selectedAlbum?.id == album.id) {
                                loadAlbumTracks(album)
                            }
                        }
                    }
                    .padding(.horizontal, 2)
                }
                .frame(height: 100)
            }

            if !albumTracks.isEmpty {
                HStack {
                    Text("Loaded tracks: \(albumTracks.count)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Spacer()
                    Button("Set Queue") {
                        initializeQueue()
                    }
                    .font(.caption)
                    .buttonStyle(.bordered)
                }
            }
        }
        .padding()
    }

    // MARK: - Current Playback Section

    private var currentPlaybackSection: some View {
        VStack(spacing: 8) {
            Text("2. Current Playback Status")
                .font(.subheadline)
                .fontWeight(.semibold)
                .frame(maxWidth: .infinity, alignment: .leading)

            HStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Status")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                    Text(playbackStatusText)
                        .font(.caption)
                        .fontWeight(.medium)
                }

                Divider()

                VStack(alignment: .leading, spacing: 2) {
                    Text("Tracks in Queue")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                    Text("\(playerQueue.entries.count)")
                        .font(.caption)
                        .fontWeight(.medium)
                }
            }
            .frame(height: 44)
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(Color(.systemGray6))
            .cornerRadius(6)

            if let currentEntry = playerQueue.currentEntry {
                CurrentTrackCard(entry: currentEntry)
            } else {
                Text("No track playing")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
    }

    // MARK: - Queue Controls Section

    private var queueControlsSection: some View {
        VStack(spacing: 8) {
            Text("3. Queue Operations and Playback Control")
                .font(.subheadline)
                .fontWeight(.semibold)
                .frame(maxWidth: .infinity, alignment: .leading)

            // Playback controls
            HStack(spacing: 8) {
                Button {
                    skipToPrevious()
                } label: {
                    Image(systemName: "backward.fill")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
                .disabled(playerQueue.entries.isEmpty)

                Button {
                    togglePlayPause()
                } label: {
                    Image(systemName: isPlaying ? "pause.fill" : "play.fill")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .disabled(playerQueue.entries.isEmpty)

                Button {
                    skipToNext()
                } label: {
                    Image(systemName: "forward.fill")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
                .disabled(playerQueue.entries.isEmpty)
            }

            // Queue manipulation controls
            VStack(spacing: 8) {
                Button("Insert Track at Index 2") {
                    insertTracksAtPosition()
                }
                .frame(maxWidth: .infinity)
                .buttonStyle(.bordered)
                .disabled(albumTracks.count < 3 || playerQueue.entries.isEmpty)

                Button("Remove Last 2 Tracks") {
                    removeMultipleTracks()
                }
                .frame(maxWidth: .infinity)
                .buttonStyle(.bordered)
                .disabled(playerQueue.entries.count < 3)

                Button("Clear Queue") {
                    clearQueue()
                }
                .frame(maxWidth: .infinity)
                .buttonStyle(.bordered)
                .tint(.red)
                .disabled(playerQueue.entries.isEmpty)
            }
        }
        .padding()
    }

    // MARK: - Operation Logs Section

    private var operationLogsSection: some View {
        VStack(spacing: 8) {
            Text("4. Operation Logs")
                .font(.subheadline)
                .fontWeight(.semibold)
                .frame(maxWidth: .infinity, alignment: .leading)

            if operationLogs.isEmpty {
                Text("Logs will appear here when operations are executed")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical, 8)
            } else {
                VStack(alignment: .leading, spacing: 2) {
                    ForEach(Array(operationLogs.prefix(10).enumerated()), id: \.offset) { index, log in
                        Text(log)
                            .font(.caption2)
                            .foregroundColor(.primary)
                            .lineLimit(2)
                            .padding(.vertical, 1)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.vertical, 4)

                Button("Clear Logs") {
                    operationLogs.removeAll()
                }
                .font(.caption)
            }
        }
        .padding()
    }

    // MARK: - Computed Properties

    private var isPlaying: Bool {
        return playerState.playbackStatus == .playing
    }

    private var playbackStatusText: String {
        switch playerState.playbackStatus {
        case .playing: return "Playing"
        case .paused: return "Paused"
        case .stopped: return "Stopped"
        case .interrupted: return "Interrupted"
        case .seekingForward: return "Seeking Forward"
        case .seekingBackward: return "Seeking Backward"
        @unknown default: return "Unknown"
        }
    }

    // MARK: - Search & Setup Methods

    private func performSearch() {
        Task {
            isLoading = true
            defer { isLoading = false }

            do {
                var searchRequest = MusicCatalogSearchRequest(term: searchTerm, types: [Album.self])
                searchRequest.limit = 5
                let response = try await searchRequest.response()

                await MainActor.run {
                    searchResults = Array(response.albums)
                    addLog("🔍 Search complete: Found \(response.albums.count) albums")
                }
            } catch {
                await MainActor.run {
                    errorMessage = "Search failed: \(error.localizedDescription)"
                    showError = true
                    addLog("❌ Search error: \(error.localizedDescription)")
                }
            }
        }
    }

    private func loadAlbumTracks(_ album: Album) {
        Task {
            isLoading = true
            defer { isLoading = false }

            do {
                let detailedAlbum = try await album.with([.tracks])

                await MainActor.run {
                    selectedAlbum = album
                    albumTracks = Array(detailedAlbum.tracks ?? [])
                    addLog("📀 Loaded tracks from '\(album.title)': \(albumTracks.count) tracks")
                }
            } catch {
                await MainActor.run {
                    errorMessage = "Failed to load tracks: \(error.localizedDescription)"
                    showError = true
                    addLog("❌ Track loading error: \(error.localizedDescription)")
                }
            }
        }
    }

    private func initializeQueue() {
        guard !albumTracks.isEmpty else { return }

        Task {
            // Use first 5 tracks or all if less than 5
            let tracksToQueue = Array(albumTracks.prefix(5))

            await MainActor.run {
                addLog("🔄 Before queue setup: \(player.queue.entries.count) tracks")
            }

            do {
                // Set queue - this is async and entries won't be populated immediately
                player.queue = ApplicationMusicPlayer.Queue(for: tracksToQueue, startingAt: nil)

                // Prepare the player by calling prepareToPlay - this should populate the queue
                try await player.prepareToPlay()

                await MainActor.run {
                    addLog("✅ Queue initialized: \(tracksToQueue.count) tracks")
                    addLog("   After prepareToPlay: \(player.queue.entries.count) tracks")
                    addLog("   - Tracks: \(tracksToQueue.map { $0.title }.joined(separator: ", "))")

                    // Force UI update
                    queueUpdateTrigger += 1
                }
            } catch {
                await MainActor.run {
                    addLog("❌ Queue initialization error: \(error.localizedDescription)")
                    errorMessage = "Failed to initialize queue: \(error.localizedDescription)"
                    showError = true
                }
            }
        }
    }

    // MARK: - Playback Control Methods

    private func togglePlayPause() {
        Task {
            do {
                if isPlaying {
                    player.pause()
                    addLog("⏸️ Paused")
                } else {
                    try await player.play()
                    addLog("▶️ Playing")
                }
            } catch {
                await MainActor.run {
                    errorMessage = "Playback failed: \(error.localizedDescription)"
                    showError = true
                    addLog("❌ Playback error: \(error.localizedDescription)")
                }
            }
        }
    }

    private func skipToNext() {
        Task {
            do {
                try await player.skipToNextEntry()
                addLog("⏭️ Skipped to next track")

                if let currentEntry = playerQueue.currentEntry {
                    addLog("   Current: \(currentEntry.title ?? "Unknown")")
                }
            } catch {
                await MainActor.run {
                    errorMessage = "Failed to skip to next track: \(error.localizedDescription)"
                    showError = true
                    addLog("❌ Skip error: \(error.localizedDescription)")
                }
            }
        }
    }

    private func skipToPrevious() {
        Task {
            do {
                try await player.skipToPreviousEntry()
                addLog("⏮️ Skipped to previous track")

                if let currentEntry = playerQueue.currentEntry {
                    addLog("   Current: \(currentEntry.title ?? "Unknown")")
                }
            } catch {
                await MainActor.run {
                    errorMessage = "Failed to skip to previous track: \(error.localizedDescription)"
                    showError = true
                    addLog("❌ Skip back error: \(error.localizedDescription)")
                }
            }
        }
    }

    // MARK: - Queue Manipulation Methods

    private func insertTracksAtPosition() {
        guard albumTracks.count >= 3 else { return }
        guard !playerQueue.entries.isEmpty else { return }

        // Get tracks that aren't in the current queue
        let currentTrackIDs = Set(playerQueue.entries.compactMap { $0.item?.id })
        let availableTracks = albumTracks.filter { !currentTrackIDs.contains($0.id) }

        guard let trackToInsert = availableTracks.first else {
            addLog("⚠️ No available tracks to insert")
            return
        }

        let insertPosition = min(2, playerQueue.entries.count)

        // Insert track at position
        let entry = ApplicationMusicPlayer.Queue.Entry(trackToInsert)
        playerQueue.entries.insert(entry, at: insertPosition)

        addLog("➕ Inserted track at position \(insertPosition): \(trackToInsert.title)")
        addLog("   Tracks in queue: \(playerQueue.entries.count)")

        // Note about transient entries
        if entry.isTransient {
            addLog("   ⚠️ Entry is transient (isTransient=true)")
            addLog("   Waiting for playback engine to resolve")
        }
    }

    private func removeMultipleTracks() {
        guard playerQueue.entries.count >= 3 else { return }

        let countBefore = playerQueue.entries.count

        // Remove last 2 entries
        let removeCount = min(2, playerQueue.entries.count - 1) // Keep at least 1 track

        for _ in 0..<removeCount {
            let lastIndex = playerQueue.entries.count - 1
            if lastIndex > 0 { // Don't remove if it's the only/currently playing track
                playerQueue.entries.remove(at: lastIndex)
            }
        }

        let countAfter = playerQueue.entries.count
        addLog("➖ Removed \(countBefore - countAfter) tracks")
        addLog("   Remaining tracks: \(countAfter)")
    }

    private func clearQueue() {
        player.queue = ApplicationMusicPlayer.Queue([])
        addLog("🗑️ Queue cleared")
    }

    // MARK: - Helper Methods

    private func addLog(_ message: String) {
        let timestamp = DateFormatter.localizedString(from: Date(), dateStyle: .none, timeStyle: .medium)
        let logMessage = "[\(timestamp)] \(message)"
        operationLogs.insert(logMessage, at: 0)

        // Also print to console
        print("🎵 PlayerQueue: \(logMessage)")

        // Keep only last 50 logs
        if operationLogs.count > 50 {
            operationLogs.removeLast()
        }
    }
}

// MARK: - Supporting Views

struct AlbumCard: View {
    let album: Album
    let isSelected: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 3) {
                if let artwork = album.artwork {
                    ArtworkImage(artwork, width: 60)
                        .cornerRadius(4)
                } else {
                    Rectangle()
                        .fill(Color.gray.opacity(0.3))
                        .frame(width: 60, height: 60)
                        .cornerRadius(4)
                }

                Text(album.title)
                    .font(.caption2)
                    .lineLimit(1)
                    .frame(width: 60)
            }
            .padding(3)
            .background(isSelected ? Color.blue.opacity(0.2) : Color.clear)
            .cornerRadius(6)
        }
    }
}

struct CurrentTrackCard: View {
    let entry: ApplicationMusicPlayer.Queue.Entry

    var body: some View {
        HStack(spacing: 10) {
            if let artwork = entry.artwork {
                ArtworkImage(artwork, width: 40)
                    .cornerRadius(4)
            } else {
                Rectangle()
                    .fill(Color.gray.opacity(0.3))
                    .frame(width: 40, height: 40)
                    .cornerRadius(4)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(entry.title ?? "Unknown Track")
                    .font(.caption)
                    .fontWeight(.medium)
                    .lineLimit(1)

                if let subtitle = entry.subtitle {
                    Text(subtitle)
                        .font(.caption2)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }

                if entry.isTransient {
                    Label("Transient Entry", systemImage: "exclamationmark.triangle.fill")
                        .font(.system(size: 9))
                        .foregroundColor(.orange)
                }
            }

            Spacer()
        }
        .padding(8)
        .background(Color(.systemGray6))
        .cornerRadius(6)
    }
}

// MARK: - Preview

struct PlayerQueueTestView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            PlayerQueueTestView()
        }
    }
}
