import SwiftUI

struct UserNotificationsView: View {
    @Environment(\.dismiss) var dismiss
    @ObservedObject var notificationStore: NotificationStore
    let userEmail: String
    @State private var showClearConfirmation = false
    
    var body: some View {
        VStack(spacing: 0) {
            // Strategic Header
            HStack {
                Button(action: { 
                    HapticManager.shared.trigger(.light)
                    dismiss() 
                }) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 16, weight: .black))
                        .foregroundColor(AppColors.textPrimary)
                        .padding(14)
                        .background(AppColors.textPrimary.opacity(0.04))
                        .clipShape(Circle())
                        .overlay(Circle().stroke(AppColors.textPrimary.opacity(0.1), lineWidth: 1))
                }
                
                Spacer()
                
                VStack(spacing: 4) {
                    Text("VANGUARD COMMUNIQUE")
                        .font(.system(size: 10, weight: .black))
                        .tracking(3)
                        .foregroundColor(AppColors.secondary)
                    
                    if notificationStore.unreadCount > 0 {
                        Text("\(notificationStore.unreadCount) Unread Alerts")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(AppColors.secondary)
                    } else {
                        Text("Intelligence Feed")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(AppColors.textSecondary)
                    }
                }
                
                Spacer()
                
                if !notificationStore.notifications.isEmpty {
                    HStack(spacing: 16) {
                        Button {
                            notificationStore.markAllAsRead(for: userEmail)
                            HapticManager.shared.notify(.success)
                        } label: {
                            Image(systemName: "checklist")
                                .font(.system(size: 18))
                                .foregroundColor(AppColors.secondary)
                                .glow(color: AppColors.secondary, radius: 2)
                        }
                        
                        Button {
                            showClearConfirmation = true
                        } label: {
                            Image(systemName: "trash")
                                .font(.system(size: 18))
                                .foregroundColor(.red)
                        }
                    }
                } else {
                    Color.clear.frame(width: 44)
                }
            }
            .padding(.horizontal, 24)
            .padding(.top, 20)
            .padding(.bottom, 32)
            
            ScrollView(showsIndicators: false) {
                if notificationStore.notifications.isEmpty {
                    VStack(spacing: 40) {
                        Spacer(minLength: 120)
                        
                        ZStack {
                            Circle()
                                .fill(AppColors.secondary.opacity(0.03))
                                .frame(width: 160, height: 160)
                            
                            Image(systemName: "antenna.radiowaves.left.and.right")
                                .font(.system(size: 64))
                                .foregroundStyle(AppColors.goldGradient)
                                .glow(color: AppColors.secondary, radius: 15)
                        }
                        
                        VStack(spacing: 16) {
                            Text("HUB SILENT")
                                .font(.system(size: 20, weight: .black))
                                .foregroundColor(AppColors.textPrimary)
                            
                            Text("No incoming logistics data or wholesale intelligence detected in the terminal.")
                                .font(.subheadline)
                                .foregroundColor(AppColors.textSecondary)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, 60)
                        }
                        
                        Spacer()
                    }
                } else {
                    VStack(spacing: 20) {
                        ForEach(notificationStore.notifications) { notification in
                            AdvancedNotificationCard(notification: notification)
                        }
                    }
                    .padding(24)
                }
            }
            .refreshable {
                HapticManager.shared.trigger(.medium)
                await notificationStore.fetchNotifications(userEmail: userEmail)
            }
        }
        .atmosphericBackground()
        .navigationBarHidden(true)
        .hidesTabBar()
        .alert("Clear All Notifications?", isPresented: $showClearConfirmation) {
            Button("Cancel", role: .cancel) {}
            Button("Clear All", role: .destructive) {
                notificationStore.clearAll()
                HapticManager.shared.notify(.warning)
            }
        } message: {
            Text("This will remove all alerts from your feed. This cannot be undone.")
        }
        .onAppear {
            Task {
                await notificationStore.fetchNotifications(userEmail: userEmail)
            }
        }
    }
}

struct AdvancedNotificationCard: View {
    let notification: AppNotification
    
    var body: some View {
        HStack(alignment: .top, spacing: 20) {
            // Priority Indicator
            ZStack {
                if !notification.isRead {
                    Circle()
                        .stroke(AppColors.secondary.opacity(0.5), lineWidth: 2)
                        .frame(width: 56, height: 56)
                        .glow(color: AppColors.secondary, radius: 8)
                } else {
                    Circle()
                        .fill(AppColors.textPrimary.opacity(0.03))
                        .frame(width: 56, height: 56)
                }
                
                Image(systemName: iconForType(notification.type))
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(notification.isRead ? AppColors.textPrimary.opacity(0.2) : AppColors.secondary)
            }
            
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text(notification.title.uppercased())
                        .font(.system(size: 10, weight: .black))
                        .tracking(1)
                        .foregroundColor(notification.isRead ? AppColors.textSecondary.opacity(0.5) : AppColors.secondary)
                    
                    Spacer()
                    
                    Text(notification.date.formatted(.dateTime.hour().minute()))
                        .font(.system(size: 9, weight: .black))
                        .foregroundColor(AppColors.textSecondary.opacity(0.5))
                }
                
                Text(notification.message)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(notification.isRead ? AppColors.textSecondary : AppColors.textPrimary)
                    .lineLimit(3)
                    .lineSpacing(4)
                
                HStack {
                    Image(systemName: "calendar")
                        .font(.system(size: 10))
                    Text(notification.date.formatted(date: .abbreviated, time: .omitted))
                        .font(.system(size: 9, weight: .black))
                }
                .foregroundColor(AppColors.textSecondary.opacity(0.4))
                .padding(.top, 4)
            }
        }
        .padding(24)
        .background(AppColors.textPrimary.opacity(notification.isRead ? 0.01 : 0.04))
        .cornerRadius(32)
        .overlay(
            RoundedRectangle(cornerRadius: 32)
                .stroke(notification.isRead ? AppColors.textPrimary.opacity(0.05) : AppColors.secondary.opacity(0.2), lineWidth: 1)
        )
    }
    
    private func iconForType(_ type: NotificationType) -> String {
        switch type {
        case .offer: return "tag.fill"
        case .order: return "shippingbox.fill"
        case .general: return "bolt.fill"
        }
    }
}
