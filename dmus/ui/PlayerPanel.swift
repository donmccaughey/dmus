import Model
import SwiftUI
import Wrappers

struct PlayerPanel: View {
    @Environment(Player.self) private var player

    // An iPhone in portrait is too narrow for regular-size controls: the
    // centered group would overlap the clear button at the trailing edge.
    #if os(macOS)
    private static let controlSize = ControlSize.regular
    private static let buttonWidth: CGFloat = 44
    #else
    private static let controlSize = ControlSize.small
    private static let buttonWidth: CGFloat = 36
    #endif
    private static let playStopButtonWidth = buttonWidth * 1.2

    var body: some View {
        ZStack {
            HStack {
                controlButton("Back", systemImage: "backward.fill", action: player.back)
                playStopButton
                controlButton("Next", systemImage: "forward.fill", action: player.next)
            }
            Button(action: player.clear) {
                Text("clear")
                    .frame(width: Self.buttonWidth)
            }
            .frame(maxWidth: .infinity, alignment: .trailing)
        }
        .buttonStyle(.bordered)
        .controlSize(Self.controlSize)
        .disabled(player.queue.isEmpty)
        .padding()
        .fixedSize(horizontal: false, vertical: true)
    }

    private var playStopButton: some View {
        controlButton(
            player.isPlaying ? "Stop" : "Play",
            systemImage: player.isPlaying ? "stop.fill" : "play.fill",
            width: Self.playStopButtonWidth
        ) {
            if player.isPlaying {
                player.stop()
            } else {
                player.play()
            }
        }
    }

    private func controlButton(
        _ title: LocalizedStringKey,
        systemImage: String,
        width: CGFloat = Self.buttonWidth,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            Label(title, systemImage: systemImage)
                .labelStyle(.iconOnly)
                .frame(width: width)
        }
    }
}

#Preview("Empty") {
    PlayerPanel().environment(Player(audio: AudioReal()))
}

#Preview("Queued") {
    let player = Player(audio: AudioReal())
    player.queue.add(Track(trackName: "Song", albumName: "Album", artistName: "Artist", path: "/Music/Artist/Album/Song.mp3"))
    return PlayerPanel().environment(player)
}
