import Model
import SwiftUI

struct FilesPanel: View {
    @Environment(MusicLibraryStore.self) private var store

    // On iOS the root folder table's navigation bar already shows the "Files"
    // title and a find button, so the panel title would duplicate them once
    // the library is loaded.
    private var showsTitle: Bool {
        #if os(macOS)
        true
        #else
        store.library.isEmpty
        #endif
    }

    var body: some View {
        Panel(title: "Files", showsTitle: showsTitle) {
            if store.library.isEmpty {
                ContentUnavailableView(
                    "No music",
                    systemImage: "folder",
                    description: Text(store.loadDidFail
                        ? "The music library did not load."
                        : "The music library is empty.")
                )
            } else {
                #if os(macOS)
                FilesTree(musicLibrary: store.library)
                #else
                FilesTableStack(musicLibrary: store.library)
                #endif
            }
        } accessory: {
            findButton
        }
    }

    private var findButton: some View {
        FindButton()
            .disabled(store.library.isEmpty)
    }
}

#Preview {
    FilesPanel().environment(MusicLibraryStore())
}
