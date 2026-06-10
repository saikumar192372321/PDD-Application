import SwiftUI

struct AppBackground: View {
    var body: some View {
        LinearGradient(
            colors: [Color(UIColor.systemGroupedBackground), Color(UIColor.secondarySystemGroupedBackground)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .ignoresSafeArea()
    }
}

struct AppBackgroundModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .background(AppBackground())
    }
}

extension View {
    func appBackground() -> some View {
        modifier(AppBackgroundModifier())
    }
}

