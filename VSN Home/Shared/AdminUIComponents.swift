import SwiftUI

// MARK: - Shared Admin UI Components

struct SectionHeader: View {
    let title: String
    var body: some View {
        Text(title)
            .font(.system(size: 8, weight: .black))
            .tracking(1)
            .foregroundColor(AppColors.textSecondary)
            .padding(.top, 8)
    }
}

struct VanguardInput: View {
    let label: String
    @Binding var text: String
    var placeholder: String = ""
    let icon: String
    var keyboard: UIKeyboardType = .default
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Label(label, systemImage: icon)
                .font(.system(size: 8, weight: .black))
                .tracking(1)
                .foregroundColor(AppColors.secondary)
            
            TextField(placeholder, text: $text)
                .font(.system(size: 15, weight: .bold))
                .foregroundColor(AppColors.textPrimary)
                .padding(16)
                .background(AppColors.background)
                .cornerRadius(8)
                .overlay(RoundedRectangle(cornerRadius: 8).stroke(AppColors.primary.opacity(0.15), lineWidth: 2))
                .keyboardType(keyboard)
        }
    }
}
