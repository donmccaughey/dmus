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
                    .background(.panelTitleBackground)
                Divider()
            }
            content()
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }
}

extension ShapeStyle where Self == AnyShapeStyle {
    // On iOS this style also backs the folder table's navigation bar, where
    // rows scroll underneath it, so it must be a solid color: a material
    // would let the rows show through.
    static var panelTitleBackground: AnyShapeStyle {
        #if os(macOS)
        AnyShapeStyle(.bar)
        #else
        AnyShapeStyle(Color(.secondarySystemBackground))
        #endif
    }
}

#Preview {
    Panel(title: "Panel") {
        Text("Content")
    }
}
