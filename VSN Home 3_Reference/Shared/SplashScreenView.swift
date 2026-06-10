import SwiftUI

struct SplashScreenView: View {
    @StateObject private var session = SessionManager.shared
    @State private var isActive = false
    @State private var scale: CGFloat = 0.72
    @State private var opacity: Double = 0.0

    var body: some View {
        Group {
            if isActive {
                if session.isLoggedIn {
                    // Pass bindings controlled by the SessionManager
                    GroceryAppView(
                        isLoggedIn: Binding(get: { session.isLoggedIn }, set: { if !$0 { session.clearSession() } }),
                        isAdmin: Binding(get: { session.isAdmin }, set: { session.isAdmin = $0 }),
                        userEmail: Binding(get: { session.userEmail }, set: { session.userEmail = $0 })
                    )
                } else {
                    LoginView(
                        isLoggedIn: Binding(get: { session.isLoggedIn }, set: { session.isLoggedIn = $0 }), 
                        isAdmin: Binding(get: { session.isAdmin }, set: { session.isAdmin = $0 }),
                        userEmail: Binding(get: { session.userEmail }, set: { session.userEmail = $0 })
                    )
                }
            } else {
                ZStack {
                    AppColors.background.ignoresSafeArea()

                    VStack(spacing: 20) {
                        Image("AppLogo")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 140, height: 140)
                            .clipShape(RoundedRectangle(cornerRadius: 28))
                            .shadow(color: AppColors.primary.opacity(0.18), radius: 24, x: 0, y: 10)
                            .scaleEffect(scale)
                            .opacity(opacity)

                        Text("VSN Home")
                            .font(.system(size: 22, weight: .bold, design: .rounded))
                            .foregroundColor(AppColors.textPrimary)
                            .opacity(opacity)

                        Text("Wholesale Platform")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(AppColors.textSecondary)
                            .opacity(opacity)
                    }

                    VStack {
                        Spacer()
                        Text("VIJAYAWADA HUB · EST. 2024")
                            .font(.system(size: 10, weight: .semibold))
                            .tracking(1.5)
                            .foregroundColor(AppColors.textSecondary.opacity(0.5))
                            .padding(.bottom, 40)
                            .opacity(opacity)
                    }
                }
                .onAppear {
                    withAnimation(.spring(response: 0.7, dampingFraction: 0.65)) {
                        scale = 1.0
                        opacity = 1.0
                    }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2.2) {
                        withAnimation(.easeInOut(duration: 0.5)) {
                            isActive = true
                        }
                    }
                }
            }
        }
    }
}
