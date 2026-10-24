import SwiftUI

struct FilesPanel: View {
    var body: some View {
        Panel(title: "Files") {
            ContentUnavailableView(
                "No Music",
                systemImage: "folder",
                description: Text("The music library is empty.")
            )
        }
    }
}

#Preview {
    FilesPanel()
}
