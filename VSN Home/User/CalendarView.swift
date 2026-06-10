import SwiftUI

struct CalendarView: View {
    @Environment(\.dismiss) var dismiss
    @State private var selectedDate = Date()
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Business Calendar")
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(AppColors.textPrimary)
                    Text("Track deliveries & deals")
                        .font(.system(size: 12))
                        .foregroundColor(AppColors.textSecondary)
                }
                Spacer()
                Button(action: { dismiss() }) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.title2)
                        .foregroundColor(AppColors.textSecondary)
                }
            }
            .padding(20)
            .background(AppColors.surfaceLight)
            
            ScrollView {
                VStack(spacing: 24) {
                    // Modern Calendar Card
                    VStack {
                        DatePicker(
                            "Select Date",
                            selection: $selectedDate,
                            displayedComponents: [.date]
                        )
                        .datePickerStyle(.graphical)
                        .tint(AppColors.primary)
                        .padding()
                    }
                    .background(AppColors.surfaceLight)
                    .cornerRadius(20)
                    .padding(.horizontal)
                    .shadow(color: Color.black.opacity(0.04), radius: 10, x: 0, y: 4)
                    
                    // Selected Date Info
                    VStack(alignment: .leading, spacing: 16) {
                        HStack {
                            Image(systemName: "calendar.badge.clock")
                                .foregroundColor(AppColors.primary)
                            Text(formatDate(selectedDate))
                                .font(.system(size: 16, weight: .bold))
                                .foregroundColor(AppColors.textPrimary)
                            Spacer()
                        }
                        
                        Divider()
                        
                        // Fake events for demonstration (e.g., predicted demand, restocks)
                        VStack(alignment: .leading, spacing: 12) {
                            CalendarEventRow(
                                title: "Bulk Restock Scheduled",
                                time: "09:00 AM",
                                type: .delivery
                            )
                            CalendarEventRow(
                                title: "Flash Sale: Rice & Grains",
                                time: "11:30 AM",
                                type: .offer
                            )
                            CalendarEventRow(
                                title: "Inventory Audit",
                                time: "04:00 PM",
                                type: .business
                            )
                        }
                    }
                    .padding(20)
                    .background(AppColors.surfaceLight)
                    .cornerRadius(20)
                    .padding(.horizontal)
                    .shadow(color: Color.black.opacity(0.04), radius: 10, x: 0, y: 4)
                }
                .padding(.vertical, 20)
            }
        }
        .background(AppBackground())
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .long
        return formatter.string(from: date)
    }
}

enum CalendarEventType {
    case delivery, offer, business
    
    var color: Color {
        switch self {
        case .delivery: return .blue
        case .offer: return .orange
        case .business: return .purple
        }
    }
    
    var icon: String {
        switch self {
        case .delivery: return "shippingbox.fill"
        case .offer: return "tag.fill"
        case .business: return "briefcase.fill"
        }
    }
}

struct CalendarEventRow: View {
    let title: String
    let time: String
    let type: CalendarEventType
    
    var body: some View {
        HStack(spacing: 12) {
            Circle()
                .fill(type.color.opacity(0.1))
                .frame(width: 40, height: 40)
                .overlay(
                    Image(systemName: type.icon)
                        .font(.system(size: 16))
                        .foregroundColor(type.color)
                )
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(AppColors.textPrimary)
                Text(time)
                    .font(.system(size: 12))
                    .foregroundColor(AppColors.textSecondary)
            }
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .font(.system(size: 10, weight: .bold))
                .foregroundColor(AppColors.textSecondary.opacity(0.3))
        }
    }
}
