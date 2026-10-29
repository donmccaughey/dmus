#if os(macOS)
import SwiftUI

struct FilesTree: View {
    let musicLibrary: MusicLibrary

    var body: some View {
        List(musicLibrary.rootFolder.children, children: \.children) { node in
            label(for: node)
                .frame(maxWidth: .infinity, alignment: .leading)
                .contentShape(Rectangle())
                .draggable(node)
        }
    }

    @ViewBuilder
    private func label(for node: FolderChild) -> some View {
        switch node {
        case .folder(let folder):
            Label(folder.name, systemImage: "folder")
        case .track(let track):
            Label(track.trackName, systemImage: "music.note")
        }
    }
}

#Preview {
    FilesTree(musicLibrary: MusicLibrary(rootFolder: Folder(
        path: "/Music",
        name: Folder.rootName,
        children: [
            .folder(Folder(path: "/Music/Artist", name: "Artist", children: [
                .folder(Folder(path: "/Music/Artist/Album", name: "Album", children: [
                    .track(Track(trackName: "Song", albumName: "Album", artistName: "Artist", path: "/Music/Artist/Album/Song.mp3")),
                ])),
            ])),
            .track(Track(trackName: "Loose", albumName: "(no album)", artistName: "(no artist)", path: "/Music/Loose.m4a")),
        ]
    )))
}
#endif
