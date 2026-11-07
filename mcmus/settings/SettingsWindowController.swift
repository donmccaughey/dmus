#if os(macOS)
import AppKit
import UniformTypeIdentifiers

final class SettingsWindowController: NSWindowController {
    private static let contentWidth: CGFloat = 600
    private static let padding: CGFloat = 16

    private let store: MusicLibraryStore
    private let pathField = ReadOnlyTextField()
    private let chooseButton = NSButton(title: "Choose…", target: nil, action: nil)

    init(store: MusicLibraryStore) {
        self.store = store
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: Self.contentWidth, height: 0),
            styleMask: [.titled, .closable],
            backing: .buffered,
            defer: false
        )
        window.title = "MC Mus Settings"
        window.isRestorable = false
        window.isReleasedWhenClosed = false
        super.init(window: window)

        chooseButton.bezelStyle = .push
        chooseButton.target = self
        chooseButton.action = #selector(chooseMusicRootDirectory)
        let contentView = makeContentView()
        window.setContentSize(contentView.fittingSize)
        window.contentView = contentView
        window.center()

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(update),
            name: MusicLibraryStore.musicRootDirectoryDidChangeNotification,
            object: store
        )
        update()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) is not supported")
    }

    private func makeContentView() -> NSView {
        let label = NSTextField(labelWithString: "Music Files:")
        let row = NSStackView(views: [label, pathField, chooseButton])
        row.orientation = .horizontal
        row.alignment = .firstBaseline
        row.translatesAutoresizingMaskIntoConstraints = false

        let contentView = NSView()
        contentView.addSubview(row)
        NSLayoutConstraint.activate([
            contentView.widthAnchor.constraint(equalToConstant: Self.contentWidth),
            row.topAnchor.constraint(equalTo: contentView.topAnchor, constant: Self.padding),
            row.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: Self.padding),
            row.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -Self.padding),
            row.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -Self.padding),
        ])
        return contentView
    }

    @objc private func update() {
        pathField.setText(store.musicRootDirectory?.url.path ?? "")
    }

    @objc private func chooseMusicRootDirectory() {
        let panel = NSOpenPanel()
        panel.canChooseDirectories = true
        panel.canChooseFiles = false
        panel.allowsMultipleSelection = false
        panel.directoryURL = store.musicRootDirectory?.url
        // Dims files that are not music so the user can see which directories hold music.
        panel.allowedContentTypes = [.mp3, .mpeg4Audio]
        guard panel.runModal() == .OK, let url = panel.url else { return }
        store.changeMusicRootDirectory(to: url)
    }
}
#endif
