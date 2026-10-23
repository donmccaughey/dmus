import SwiftUI

/// The queue panel displays the queue of tracks to play.
struct QueuePanel: View {
    var body: some View {
        Panel(title: "Queue") {
            ContentUnavailableView(
                "Queue Is Empty",
                systemImage: "list.bullet",
                description: Text("Add tracks from the files panel to play them.")
            )
        }
    }
}

#Preview {
    QueuePanel()
}
