import SwiftUI

struct AdminNotificationView: View {
    @ObservedObject var notificationStore: NotificationStore
    
    @State private var title = ""
    @State private var message = ""
    @State private var selectedType: NotificationType = .general
    @State private var showSuccess = false
    
    var body: some View {
        ScrollView {
            VStack(spacing: 32) {
                // Header section
                VStack(alignment: .leading, spacing: 6) {
                    Text("Broadcaster Portal")
                        .font(.system(size: 32, weight: .black))
                        .foregroundColor(AppColors.textPrimary)
                    Text("Deploy secure announcements to the ecosystem")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(AppColors.textSecondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 24)
                .padding(.top, 16)

                // Input Section
                VStack(spacing: 24) {
                    VStack(alignment: .leading, spacing: 10) {
                        Label("ANNOUNCEMENT DETAILS", systemImage: "text.justify")
                            .font(.system(size: 8, weight: .black))
                            .foregroundColor(AppColors.secondary)
                        
                        TextField("", text: $title, prompt: Text("Notification Headline (e.g. 50% Off Snacks)").foregroundColor(AppColors.textSecondary.opacity(0.3)))
                            .padding()
                            .background(AppColors.textPrimary.opacity(0.04))
                            .clipShape(RoundedRectangle(cornerRadius: 16))
                            .foregroundColor(AppColors.textPrimary)
                            .font(.system(size: 14, weight: .bold))
                            .overlay(RoundedRectangle(cornerRadius: 16).stroke(AppColors.textPrimary.opacity(0.08), lineWidth: 1))
                    }

                    VStack(alignment: .leading, spacing: 10) {
                        Label("BROADCAST TYPE", systemImage: "tag.fill")
                            .font(.system(size: 8, weight: .black))
                            .foregroundColor(AppColors.secondary)
                        
                        Picker("", selection: $selectedType) {
                            ForEach(NotificationType.allCases, id: \.self) { type in
                                Text(type.rawValue).tag(type)
                            }
                        }
                        .pickerStyle(.segmented)
                        .padding(4)
                        .background(AppColors.textPrimary.opacity(0.02))
                        .cornerRadius(12)
                    }

                    VStack(alignment: .leading, spacing: 10) {
                        Label("MESSAGE BODY", systemImage: "bubble.left.and.exclamationmark.bubble.right.fill")
                            .font(.system(size: 8, weight: .black))
                            .foregroundColor(AppColors.secondary)
                        
                        TextEditor(text: $message)
                            .frame(height: 120)
                            .padding(12)
                            .background(AppColors.textPrimary.opacity(0.04))
                            .clipShape(RoundedRectangle(cornerRadius: 16))
                            .foregroundColor(AppColors.textPrimary)
                            .font(.system(size: 14, weight: .semibold))
                            .scrollContentBackground(.hidden)
                            .overlay(
                                Group {
                                    if message.isEmpty {
                                        Text("Describe the update reaching all wholesale partners...")
                                            .font(.subheadline)
                                            .foregroundColor(AppColors.textSecondary.opacity(0.3))
                                            .padding(.leading, 16)
                                            .padding(.top, 20)
                                    }
                                }, alignment: .topLeading
                            )
                            .overlay(RoundedRectangle(cornerRadius: 16).stroke(AppColors.textPrimary.opacity(0.08), lineWidth: 1))
                    }

                    // Send Button
                    Button(action: {
                        HapticManager.shared.notify(.success)
                        sendNotification()
                    }) {
                        HStack(spacing: 12) {
                            Image(systemName: "antenna.radiowaves.left.and.right")
                            Text("TRANSMIT BROADCAST")
                                .font(.system(size: 14, weight: .black))
                                .tracking(1)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 20)
                        .background(title.isEmpty || message.isEmpty ? AnyShapeStyle(AppColors.textPrimary.opacity(0.05)) : AnyShapeStyle(AppColors.primaryGradient))
                        .foregroundColor(title.isEmpty || message.isEmpty ? AppColors.textSecondary.opacity(0.2) : .white)
                        .clipShape(RoundedRectangle(cornerRadius: 20))
                        .glow(color: (title.isEmpty || message.isEmpty) ? .clear : AppColors.primary, radius: 10)
                    }
                    .disabled(title.isEmpty || message.isEmpty)
                }
                .padding(32)
                .background(AppColors.textPrimary.opacity(0.02))
                .cornerRadius(40)
                .overlay(RoundedRectangle(cornerRadius: 40).stroke(AppColors.textPrimary.opacity(0.05), lineWidth: 1))
                .padding(.horizontal)

                // Live Preview (User Side)
                VStack(alignment: .leading, spacing: 12) {
                    Text("LIVE USER PREVIEW")
                        .font(.system(size: 8, weight: .black))
                        .foregroundColor(AppColors.textSecondary)
                        .padding(.leading, 4)
                    
                    HStack(spacing: 16) {
                        Circle()
                            .fill(typeColor(selectedType).gradient)
                            .frame(width: 48, height: 48)
                            .overlay(
                                Image(systemName: typeIcon(selectedType))
                                    .foregroundColor(.white)
                            )
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text(title.isEmpty ? "Notification Headline" : title)
                                .font(.system(size: 14, weight: .bold))
                                .foregroundColor(AppColors.textPrimary)
                            Text(message.isEmpty ? "Your message will appear here..." : message)
                                .font(.system(size: 12))
                                .foregroundColor(AppColors.textSecondary)
                                .lineLimit(2)
                            Text("Just Now • VSN Home")
                                .font(.system(size: 8, weight: .black))
                                .foregroundColor(AppColors.textSecondary.opacity(0.4))
                        }
                        Spacer()
                    }
                    .padding(20)
                    .background(AppColors.textPrimary.opacity(0.02))
                    .clipShape(RoundedRectangle(cornerRadius: 20))
                    .overlay(RoundedRectangle(cornerRadius: 20).stroke(typeColor(selectedType).opacity(0.2), lineWidth: 1))
                }
                .padding(.horizontal)

                // History Section
                VStack(alignment: .leading, spacing: 20) {
                    Text("TRANSMISSION HISTORY")
                        .font(.system(size: 8, weight: .black))
                        .foregroundColor(AppColors.textSecondary)
                        .padding(.leading, 4)
                    
                    if notificationStore.notifications.isEmpty {
                        ContentUnavailableView {
                            Label("Hub Silent", systemImage: "clock.badge.exclamationmark")
                                .foregroundColor(AppColors.textSecondary.opacity(0.4))
                        } description: {
                            Text("Broadcast history will appear here once protocols are initialized.")
                                .font(.caption)
                                .foregroundColor(AppColors.textSecondary.opacity(0.3))
                        }
                        .frame(height: 200)
                    } else {
                        VStack(spacing: 0) {
                            ForEach(notificationStore.notifications) { notification in
                                NotificationHistoryRow(notification: notification) {
                                    if let index = notificationStore.notifications.firstIndex(where: { $0.id == notification.id }) {
                                        notificationStore.deleteNotification(at: IndexSet(integer: index))
                                    }
                                }
                                if notification.id != notificationStore.notifications.last?.id {
                                    Divider().padding(.leading, 60).opacity(0.1)
                                }
                            }
                        }
                        .background(AppColors.textPrimary.opacity(0.02))
                        .cornerRadius(32)
                        .overlay(RoundedRectangle(cornerRadius: 32).stroke(AppColors.textPrimary.opacity(0.05), lineWidth: 1))
                    }
                }
                .padding(.horizontal)
                .padding(.bottom, 40)
            }
        }
        .atmosphericBackground()
        .onAppear {
            Task { await notificationStore.fetchNotifications(userEmail: "all") }
        }
        .alert("Transmission Successful", isPresented: $showSuccess) {
            Button("ACKNOWLEDGE") { }
        } message: {
            Text("Broadcast has been successfully securely deployed to all active wholesale users.")
        }
    }

    private func typeColor(_ type: NotificationType) -> Color {
        switch type {
        case .offer: return AppColors.secondary
        case .order: return AppColors.primary
        case .general: return .blue
        }
    }

    private func typeIcon(_ type: NotificationType) -> String {
        switch type {
        case .offer: return "tag.fill"
        case .order: return "shippingbox.fill"
        case .general: return "bell.badge.fill"
        }
    }
    
    private func sendNotification() {
        Task {
            await notificationStore.sendNotification(title: title, message: message, type: selectedType)
            await MainActor.run {
                title = ""
                message = ""
                selectedType = .general
                showSuccess = true
            }
        }
    }
}

struct NotificationHistoryRow: View {
    let notification: AppNotification
    let onDelete: () -> Void

    var body: some View {
        HStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(Color.gray.opacity(0.1))
                    .frame(width: 40, height: 40)
                Image(systemName: "bell.fill")
                    .font(.caption)
                    .foregroundColor(.gray)
            }
            
            VStack(alignment: .leading, spacing: 2) {
                Text(notification.title)
                    .font(.subheadline.bold())
                Text(notification.message)
                    .font(.caption2)
                    .foregroundColor(.secondary)
                    .lineLimit(1)
                Text(notification.date.formatted(date: .abbreviated, time: .shortened))
                    .font(.system(size: 8))
                    .foregroundColor(.gray)
            }
            
            Spacer()
            
            Button(action: onDelete) {
                Image(systemName: "trash")
                    .font(.caption)
                    .foregroundColor(.red.opacity(0.5))
            }
        }
        .padding()
    }
}
