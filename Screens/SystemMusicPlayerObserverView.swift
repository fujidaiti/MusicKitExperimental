/*
SystemMusicPlayerによるApple Musicアプリの状態監視画面
System Music Player State Observer - Observes the Music app's playback state
*/

import MusicKit
import SwiftUI

struct SystemMusicPlayerObserverView: View {
    // SystemMusicPlayer observables
    @ObservedObject private var playerState = SystemMusicPlayer.shared.state
    private let player = SystemMusicPlayer.shared

    // Timer for updating playback time
    @State private var currentTime: TimeInterval = 0
    @State private var timer: Timer?
    @State private var currentEntry: MusicPlayer.Queue.Entry?

    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                // Playback status section
                playbackStatusSection

                Divider()

                // Current track section
                currentTrackSection

                Spacer()
            }
        }
        .navigationTitle("System Music Player Observer")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            startTimer()
        }
        .onDisappear {
            stopTimer()
        }
    }

    // MARK: - Playback Status Section

    private var playbackStatusSection: some View {
        VStack(spacing: 8) {
            Text("Playback Status")
                .font(.subheadline)
                .fontWeight(.semibold)
                .frame(maxWidth: .infinity, alignment: .leading)

            VStack(spacing: 12) {
                // Playback status indicator
                HStack {
                    Image(systemName: playbackStatusIcon)
                        .foregroundColor(playbackStatusColor)
                        .font(.title2)

                    VStack(alignment: .leading, spacing: 2) {
                        Text("Status")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                        Text(playbackStatusText)
                            .font(.body)
                            .fontWeight(.medium)
                    }

                    Spacer()
                }

                // Playback time
                if playerState.playbackStatus == .playing || playerState.playbackStatus == .paused {
                    HStack {
                        Image(systemName: "clock")
                            .foregroundColor(.blue)
                            .font(.title2)

                        VStack(alignment: .leading, spacing: 2) {
                            Text("Playback Time")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                            Text(formatTime(currentTime))
                                .font(.body)
                                .fontWeight(.medium)
                                .monospacedDigit()
                        }

                        Spacer()
                    }
                }
            }
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(8)
        }
        .padding()
    }

    // MARK: - Current Track Section

    private var currentTrackSection: some View {
        VStack(spacing: 8) {
            Text("Currently Playing")
                .font(.subheadline)
                .fontWeight(.semibold)
                .frame(maxWidth: .infinity, alignment: .leading)

            if let entry = currentEntry {
                HStack(spacing: 12) {
                    // Artwork
                    if let artwork = entry.artwork {
                        ArtworkImage(artwork, width: 80)
                            .cornerRadius(8)
                    } else {
                        Rectangle()
                            .fill(Color.gray.opacity(0.3))
                            .frame(width: 80, height: 80)
                            .cornerRadius(8)
                    }

                    // Track information
                    VStack(alignment: .leading, spacing: 4) {
                        Text(entry.title)
                            .font(.headline)
                            .lineLimit(2)

                        if let subtitle = entry.subtitle {
                            Text(subtitle)
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                                .lineLimit(1)
                        }
                    }

                    Spacer()
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(8)
            } else {
                VStack(spacing: 8) {
                    Image(systemName: "music.note.list")
                        .font(.system(size: 40))
                        .foregroundColor(.secondary)
                    Text("No track is currently playing")
                        .font(.body)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 40)
                .background(Color(.systemGray6))
                .cornerRadius(8)
            }
        }
        .padding()
    }

    // MARK: - Computed Properties

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

    private var playbackStatusIcon: String {
        switch playerState.playbackStatus {
        case .playing: return "play.circle.fill"
        case .paused: return "pause.circle.fill"
        case .stopped: return "stop.circle.fill"
        case .interrupted: return "exclamationmark.triangle.fill"
        case .seekingForward: return "forward.circle.fill"
        case .seekingBackward: return "backward.circle.fill"
        @unknown default: return "questionmark.circle.fill"
        }
    }

    private var playbackStatusColor: Color {
        switch playerState.playbackStatus {
        case .playing: return .green
        case .paused: return .orange
        case .stopped: return .red
        case .interrupted: return .yellow
        case .seekingForward, .seekingBackward: return .blue
        @unknown default: return .gray
        }
    }

    // MARK: - Helper Methods

    private func formatTime(_ timeInterval: TimeInterval) -> String {
        let totalSeconds = Int(timeInterval)
        let minutes = totalSeconds / 60
        let seconds = totalSeconds % 60
        return String(format: "%d:%02d", minutes, seconds)
    }

    private func startTimer() {
        // Update current time and entry immediately
        currentTime = player.playbackTime
        currentEntry = player.queue.currentEntry

        // Create timer to update playback time and current entry every 0.5 seconds
        timer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { _ in
            currentTime = player.playbackTime
            currentEntry = player.queue.currentEntry
        }
    }

    private func stopTimer() {
        timer?.invalidate()
        timer = nil
    }
}

// MARK: - Preview

struct SystemMusicPlayerObserverView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            SystemMusicPlayerObserverView()
        }
    }
}
