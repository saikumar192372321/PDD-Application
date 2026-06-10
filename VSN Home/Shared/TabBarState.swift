import SwiftUI
import Combine

/// Shared state to control custom bottom tab bar visibility.
/// Inject as .environmentObject into both GroceryAppView and AdminTabView.
class TabBarState: ObservableObject {
    @Published var isHidden: Bool = false
}

/// View modifier that auto-hides the custom tab bar on appear and restores it on disappear.
struct HideTabBar: ViewModifier {
    @EnvironmentObject var tabBarState: TabBarState

    func body(content: Content) -> some View {
        content
            .onAppear  { withAnimation(.easeInOut(duration: 0.2)) { tabBarState.isHidden = true  } }
            .onDisappear { withAnimation(.easeInOut(duration: 0.2)) { tabBarState.isHidden = false } }
    }
}

extension View {
    /// Call on any sub/detail view that should hide the bottom tab bar.
    func hidesTabBar() -> some View {
        modifier(HideTabBar())
    }
}
