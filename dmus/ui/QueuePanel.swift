import SwiftUI

struct QueuePanel: View {
    var body: some View {
        Panel(title: "Queue") {
            ContentUnavailableView(
                "No tracks",
                systemImage: "list.bullet",
                description: Text("The queue is empty.")
            )
        }
    }
}

#Preview {
    QueuePanel()
}
