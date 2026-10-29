#if os(macOS)
import AppKit
import SwiftUI
import UniformTypeIdentifiers

struct SettingsView: View {
    @Environment(MusicLibraryStore.self) private var store

    var body: some View {
        Form {
            LabeledContent("Music Files:") {
                HStack {
                    ReadOnlyTextField(text: musicRootDirectoryPath)
                    Button("Choose…", action: chooseMusicRootDirectory)
                }
            }
        }
        .padding()
        .frame(width: 600)
    }

    private var musicRootDirectoryPath: String {
        store.musicRootDirectory?.path ?? ""
    }

    private func chooseMusicRootDirectory() {
        let panel = NSOpenPanel()
        panel.canChooseDirectories = true
        panel.canChooseFiles = false
        panel.allowsMultipleSelection = false
        panel.directoryURL = store.musicRootDirectory
        // Dims files that are not music so the user can see which directories hold music.
        panel.allowedContentTypes = [.mp3, .mpeg4Audio]
        guard panel.runModal() == .OK, let url = panel.url else { return }
        store.changeMusicRootDirectory(to: url)
    }
}

#Preview {
    SettingsView().environment(MusicLibraryStore())
}
#endif
