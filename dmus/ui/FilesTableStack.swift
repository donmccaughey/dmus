#if os(iOS)
import SwiftUI

struct FilesTableStack: View {
    let musicLibrary: MusicLibrary
    @State private var path: [Folder] = []

    var body: some View {
        NavigationStack(path: $path) {
            FolderTable(folder: musicLibrary.rootFolder, push: push)
                .navigationDestination(for: Folder.self) { folder in
                    FolderTable(folder: folder, push: push)
                }
        }
    }

    private func push(_ folder: Folder) {
        path.append(folder)
    }
}

struct FolderTable: View {
    let folder: Folder
    let push: (Folder) -> Void

    var body: some View {
        List(folder.children) { node in
            switch node {
            case .folder(let folder):
                FolderRow(folder: folder, push: push)
            case .track(let track):
                TrackRow(track: track)
            }
        }
        .listStyle(.plain)
        .navigationTitle(folder.name)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            SearchButton()
                .disabled(folder.children.isEmpty)
        }
    }
}

struct FolderRow: View {
    @Environment(Queue.self) private var queue
    let folder: Folder
    let push: (Folder) -> Void

    var body: some View {
        HStack {
            Text(folder.name)
            Spacer()
            RowButton("Add", systemImage: "plus.square") { queue.add(folder) }
            RowButton("Open", systemImage: "chevron.right") { push(folder) }
                .foregroundStyle(.tertiary)
        }
        // A visible NavigationLink draws its own chevron next to ours and
        // swallows taps on buttons inside its label, so hide it behind the row
        // to keep the whole row tappable without the duplicate chevron.
        .background(NavigationLink(value: folder) { EmptyView() }.opacity(0))
    }
}

struct TrackRow: View {
    @Environment(Queue.self) private var queue
    let track: Track

    var body: some View {
        HStack {
            Text(track.trackName)
            Spacer()
            RowButton("Add", systemImage: "plus.circle") { queue.add(track) }
        }
    }
}

private struct SearchButton: View {
    var body: some View {
        Button("Search", systemImage: "magnifyingglass") {}
            .labelStyle(.iconOnly)
    }
}

private struct RowButton: View {
    let title: String
    let systemImage: String
    let action: () -> Void

    init(_ title: String, systemImage: String, action: @escaping () -> Void) {
        self.title = title
        self.systemImage = systemImage
        self.action = action
    }

    var body: some View {
        Button(title, systemImage: systemImage, action: action)
            .labelStyle(.iconOnly)
            // In a List row the default style makes the whole row fire the
            // button; borderless limits it to the button itself.
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
    .environment(Queue())
}
#endif
