import SwiftUI

struct Panel<Content: View>: View {
    let title: LocalizedStringKey
    var showsTitle = true
    @ViewBuilder let content: () -> Content

    var body: some View {
        VStack(spacing: 0) {
            if showsTitle {
                Text(title)
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
                    .background(.bar)
                Divider()
            }
            content()
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }
}

#Preview {
    Panel(title: "Panel") {
        Text("Content")
    }
}
