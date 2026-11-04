#if os(iOS)
import SwiftUI

struct Panel<Content: View, Accessory: View>: View {
    let title: LocalizedStringKey
    var showsTitle = true
    @ViewBuilder let content: () -> Content
    @ViewBuilder let accessory: () -> Accessory

    var body: some View {
        VStack(spacing: 0) {
            if showsTitle {
                Text(title)
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .overlay(alignment: .trailing) {
                        accessory()
                            .padding(.trailing, 8)
                    }
                    .background(.panelTitleBackground)
                Divider()
            }
            content()
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }
}

extension Panel where Accessory == EmptyView {
    init(
        title: LocalizedStringKey,
        showsTitle: Bool = true,
        @ViewBuilder content: @escaping () -> Content
    ) {
        self.init(title: title, showsTitle: showsTitle, content: content) {
            EmptyView()
        }
    }
}

extension ShapeStyle where Self == AnyShapeStyle {
    // On iOS this style also backs the folder table's navigation bar, where
    // rows scroll underneath it, so it must be a solid color: a material
    // would let the rows show through.
    static var panelTitleBackground: AnyShapeStyle {
        AnyShapeStyle(Color(.secondarySystemBackground))
    }
}

#Preview {
    Panel(title: "Panel") {
        Text("Content")
    }
}

#Preview("Accessory") {
    Panel(title: "Panel") {
        Text("Content")
    } accessory: {
        Button("Action") {}
            .buttonStyle(.bordered)
            .controlSize(.small)
    }
}
#endif
