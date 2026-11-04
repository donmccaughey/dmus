#if os(macOS)
import AppKit
import DeveloperToolsSupport
import Model
import Wrappers

final class PlayerPanelView: NSView {
    private static let buttonWidth: CGFloat = 60
    private static let playStopButtonWidth = buttonWidth * 1.2
    private static let padding: CGFloat = 16

    private let player: Player
    private let backButton = makeButton(systemImage: "backward.fill", title: "Back")
    private let playStopButton = makeButton(systemImage: "play.fill", title: "Play")
    private let nextButton = makeButton(systemImage: "forward.fill", title: "Next")

    init(player: Player) {
        self.player = player
        super.init(frame: .zero)
        backButton.target = self
        backButton.action = #selector(back)
        playStopButton.target = self
        playStopButton.action = #selector(playOrStop)
        nextButton.target = self
        nextButton.action = #selector(next)

        let stack = NSStackView(views: [backButton, playStopButton, nextButton])
        stack.orientation = .horizontal
        stack.translatesAutoresizingMaskIntoConstraints = false
        addSubview(stack)
        NSLayoutConstraint.activate([
            backButton.widthAnchor.constraint(equalToConstant: Self.buttonWidth),
            playStopButton.widthAnchor.constraint(equalToConstant: Self.playStopButtonWidth),
            nextButton.widthAnchor.constraint(equalToConstant: Self.buttonWidth),
            stack.centerXAnchor.constraint(equalTo: centerXAnchor),
            stack.topAnchor.constraint(equalTo: topAnchor, constant: Self.padding),
            stack.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -Self.padding),
        ])
        setContentHuggingPriority(.required, for: .vertical)

        observeChanges { [weak self] in
            self?.update()
        }
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) is not supported")
    }

    private func update() {
        let isEnabled = !player.queue.isEmpty
        for button in [backButton, playStopButton, nextButton] {
            button.isEnabled = isEnabled
        }
        if player.isPlaying {
            playStopButton.image = Self.symbolImage("stop.fill", title: "Stop")
            playStopButton.setAccessibilityTitle("Stop")
        } else {
            playStopButton.image = Self.symbolImage("play.fill", title: "Play")
            playStopButton.setAccessibilityTitle("Play")
        }
    }

    @objc private func back() {
        player.back()
    }

    @objc private func playOrStop() {
        if player.isPlaying {
            player.stop()
        } else {
            player.play()
        }
    }

    @objc private func next() {
        player.next()
    }

    private static func makeButton(systemImage: String, title: String) -> NSButton {
        let button = NSButton(image: symbolImage(systemImage, title: title), target: nil, action: nil)
        button.bezelStyle = .push
        button.setAccessibilityTitle(title)
        return button
    }

    private static func symbolImage(_ systemImage: String, title: String) -> NSImage {
        NSImage(systemSymbolName: systemImage, accessibilityDescription: title)!
    }
}

#Preview("Empty") {
    let view = PlayerPanelView(player: Player(audio: AudioReal()))
    view.frame = NSRect(x: 0, y: 0, width: 400, height: 60)
    return view
}

#Preview("Queued") {
    let player = Player(audio: AudioReal())
    player.queue.add(Track(trackName: "Song", albumName: "Album", artistName: "Artist", path: "/Music/Artist/Album/Song.mp3"))
    let view = PlayerPanelView(player: player)
    view.frame = NSRect(x: 0, y: 0, width: 400, height: 60)
    return view
}
#endif
