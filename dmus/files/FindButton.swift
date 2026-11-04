#if os(iOS)
import SwiftUI

struct FindButton: View {
    var body: some View {
        Button("Find") {}
            .buttonStyle(.bordered)
            .controlSize(.regular)
    }
}

#Preview {
    FindButton()
}
#endif
