import SwiftUI

struct FilesPanel: View {
    @Environment(\.musicLibrary) private var appMusicLibrary
    @State private var musicLibrary = MusicLibrary()
    @State private var loadDidFail = false

    // On iOS the root folder table's navigation title already reads "Files",
    // so the panel title would duplicate it once the library is loaded.
    private var showsTitle: Bool {
        #if os(macOS)
        true
        #else
        musicLibrary.isEmpty
        #endif
    }

    var body: some View {
        Panel(title: "Files", showsTitle: showsTitle) {
            if musicLibrary.isEmpty {
                ContentUnavailableView(
                    "No music",
                    systemImage: "folder",
                    description: Text(loadDidFail
                        ? "The music library did not load."
                        : "The music library is empty.")
                )
            } else {
                #if os(macOS)
                FilesTree(musicLibrary: musicLibrary)
                #else
                FilesTableStack(musicLibrary: musicLibrary)
                #endif
            }
        }
        .onAppear {
            musicLibrary = appMusicLibrary
        }
        .onReceive(NotificationCenter.default.publisher(for: .musicLibraryDidLoad)) { notification in
            if let library = notification.object as? MusicLibrary {
                musicLibrary = library
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .musicLibraryLoadDidFail)) { _ in
            loadDidFail = true
        }
    }
}

#Preview {
    FilesPanel()
}
