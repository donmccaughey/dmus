#if os(iOS)
import Model
import SwiftUI

struct FilesPanel: View {
    @Environment(MusicLibraryStore.self) private var store

    var body: some View {
        // The root folder table's navigation bar already shows the "Files"
        // title and a find button, so the panel title would duplicate them once
        // the library is loaded.
        Panel(title: "Files", showsTitle: store.library.isEmpty) {
            if store.library.isEmpty {
                ContentUnavailableView(
                    "No music",
                    systemImage: "folder",
                    description: Text(store.loadDidFail
                        ? "The music library did not load."
                        : "The music library is empty.")
                )
            } else {
                FilesTableStack(musicLibrary: store.library)
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
#endif
