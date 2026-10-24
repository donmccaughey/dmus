#if os(iOS)
import SwiftUI

struct FilesTableStack: View {
    let musicLibrary: MusicLibrary

    var body: some View {
        NavigationStack {
            FolderTable(folder: musicLibrary.rootFolder)
                .navigationDestination(for: Folder.self) { folder in
                    FolderTable(folder: folder)
                }
        }
    }
}

struct FolderTable: View {
    let folder: Folder

    var body: some View {
        List(folder.children) { node in
            switch node {
            case .folder(let folder):
                FolderRow(folder: folder)
            case .track(let track):
                TrackRow(track: track)
            }
        }
        .navigationTitle(folder.name)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            AddButton {}
                .disabled(folder.children.isEmpty)
        }
    }
}

struct FolderRow: View {
    let folder: Folder

    var body: some View {
        NavigationLink(value: folder) {
            HStack {
                Text(folder.name)
                Spacer()
                AddButton {}
            }
        }
    }
}

struct TrackRow: View {
    let track: Track

    var body: some View {
        HStack {
            Text(track.trackName)
            Spacer()
            AddButton {}
        }
    }
}

private struct AddButton: View {
    let action: () -> Void

    var body: some View {
        Button("Add", systemImage: "plus", action: action)
            .labelStyle(.iconOnly)
            // Borderless keeps a tap on the button from also triggering the
            // enclosing NavigationLink.
            .buttonStyle(.borderless)
    }
}

#Preview {
    FilesTableStack(musicLibrary: MusicLibrary(rootFolder: Folder(
        path: "/Music",
        name: Folder.rootName,
        children: [
            .folder(Folder(path: "/Music/Artist", name: "Artist", children: [
                .folder(Folder(path: "/Music/Artist/Album", name: "Album", children: [
                    .track(Track(trackName: "Song", albumName: "Album", artistName: "Artist", path: "/Music/Artist/Album/Song.mp3")),
                ])),
                .folder(Folder(path: "/Music/Artist/Empty", name: "Empty", children: [])),
            ])),
            .track(Track(trackName: "Loose", albumName: "(no album)", artistName: "(no artist)", path: "/Music/Loose.m4a")),
        ]
    )))
}
#endif
