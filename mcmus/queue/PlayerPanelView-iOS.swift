#if os(iOS)
import DeveloperToolsSupport
import UIKit

final class PlayerPanelView: UIView {
    private static let buttonWidth: CGFloat = 68
    private static let playStopButtonWidth = buttonWidth * 1.2
    private static let buttonSpacing: CGFloat = 8
    private static let padding: CGFloat = 16

    private let player: Player
    private let backButton = makeButton(systemImage: "backward.fill", accessibilityLabel: "Back")
    private let playStopButton = makeButton(systemImage: "play.fill", accessibilityLabel: "Play")
    private let nextButton = makeButton(systemImage: "forward.fill", accessibilityLabel: "Next")

    init(player: Player) {
        self.player = player
        super.init(frame: .zero)
        backButton.addAction(UIAction { [player] _ in player.back() }, for: .primaryActionTriggered)
        playStopButton.addAction(UIAction { [player] _ in
            if player.isPlaying {
                player.stop()
            } else {
                player.play()
            }
        }, for: .primaryActionTriggered)
        nextButton.addAction(UIAction { [player] _ in player.next() }, for: .primaryActionTriggered)

        let stack = UIStackView(arrangedSubviews: [backButton, playStopButton, nextButton])
        stack.spacing = Self.buttonSpacing
        stack.translatesAutoresizingMaskIntoConstraints = false
        addSubview(stack)
        directionalLayoutMargins = NSDirectionalEdgeInsets(
            top: Self.padding,
            leading: Self.padding,
            bottom: Self.padding,
            trailing: Self.padding
        )
        NSLayoutConstraint.activate([
            backButton.widthAnchor.constraint(equalToConstant: Self.buttonWidth),
            playStopButton.widthAnchor.constraint(equalToConstant: Self.playStopButtonWidth),
            nextButton.widthAnchor.constraint(equalToConstant: Self.buttonWidth),
            stack.centerXAnchor.constraint(equalTo: layoutMarginsGuide.centerXAnchor),
            stack.topAnchor.constraint(equalTo: layoutMarginsGuide.topAnchor),
            stack.bottomAnchor.constraint(equalTo: layoutMarginsGuide.bottomAnchor),
        ])

        // The buttons have fixed widths, and at larger sizes than this the
        // symbols outgrow them.
        maximumContentSizeCategory = .accessibilityLarge

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(update),
            name: Queue.didChangeNotification,
            object: player.queue
        )
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(update),
            name: Player.didChangeNotification,
            object: player
        )
        update()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) is not supported")
    }

    @objc private func update() {
        let isEnabled = !player.queue.isEmpty
        for button in [backButton, playStopButton, nextButton] {
            button.isEnabled = isEnabled
        }
        if player.isPlaying {
            playStopButton.configuration?.image = UIImage(systemName: "stop.fill")
            playStopButton.accessibilityLabel = "Stop"
        } else {
            playStopButton.configuration?.image = UIImage(systemName: "play.fill")
            playStopButton.accessibilityLabel = "Play"
        }
    }

    private static func makeButton(systemImage: String, accessibilityLabel: String) -> UIButton {
        var configuration = UIButton.Configuration.bordered()
        configuration.image = UIImage(systemName: systemImage)
        configuration.preferredSymbolConfigurationForImage = UIImage.SymbolConfiguration(textStyle: .body, scale: .medium)
        let button = UIButton(configuration: configuration)
        button.accessibilityLabel = accessibilityLabel
        // The buttons' height sets the panel's, so the queue table below
        // has to be what stretches to fill the queue panel.
        button.setContentHuggingPriority(.required, for: .vertical)
        button.setContentCompressionResistancePriority(.required, for: .vertical)
        return button
    }
}

#Preview("Empty") {
    PlayerPanelView(player: Player())
}

#Preview("Queued") {
    let player = Player()
    player.queue.add(Track(trackName: "Song", albumName: "Album", artistName: "Artist", path: "/Music/Artist/Album/Song.mp3"))
    return PlayerPanelView(player: player)
}
#endif
