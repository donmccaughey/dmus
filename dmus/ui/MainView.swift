import SwiftUI

struct MainView: View {
    var body: some View {
        #if os(macOS)
        panels(arrangement: .sideBySide)
        #else
        GeometryReader { proxy in
            panels(arrangement: proxy.size.width > proxy.size.height ? .sideBySide : .stacked)
        }
        #endif
    }

    private enum Arrangement {
        case sideBySide
        case stacked
    }

    @ViewBuilder
    private func panels(arrangement: Arrangement) -> some View {
        let layout = switch arrangement {
        case .sideBySide: AnyLayout(HStackLayout(spacing: 0))
        case .stacked: AnyLayout(VStackLayout(spacing: 0))
        }
        layout {
            FilesPanel()
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            Divider()
            QueuePanel()
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }
}

#Preview {
    MainView()
}
