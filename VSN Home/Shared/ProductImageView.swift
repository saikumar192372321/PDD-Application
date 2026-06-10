import SwiftUI

struct ProductImageView: View {
    let imageName: String
    var selectedLanguage: AppLanguage = .english

    var body: some View {
        Group {
            if imageName.isEmpty {
                placeholder
            } else if imageName.starts(with: "http") {
                AsyncImage(url: URL(string: imageName)) { phase in
                    switch phase {
                    case .empty:
                        ProgressView()
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                    case .success(let image):
                        image.resizable().scaledToFit()
                    case .failure:
                        placeholder
                    @unknown default:
                        placeholder
                    }
                }
            } else if let uiImage = decodeBase64Image(imageName) {
                // ✅ Uploaded product photo (base64)
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFit()
            } else if UIImage(systemName: imageName) != nil {
                // System SF Symbol (mock data)
                Image(systemName: imageName)
                    .resizable()
                    .scaledToFit()
                    .foregroundColor(AppColors.primary.opacity(0.5))
            } else if UIImage(named: imageName) != nil {
                // Local asset
                Image(imageName)
                    .resizable()
                    .scaledToFit()
            } else {
                placeholder
            }
        }
    }

    // Strip whitespace/newlines before decoding — fixes silent base64 failures
    private func decodeBase64Image(_ string: String) -> UIImage? {
        let cleaned = string
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: "\n", with: "")
            .replacingOccurrences(of: "\r", with: "")
            .replacingOccurrences(of: " ", with: "")
        guard let data = Data(base64Encoded: cleaned, options: .ignoreUnknownCharacters) else { return nil }
        return UIImage(data: data)
    }

    private var placeholder: some View {
        VStack(spacing: 6) {
            Image(systemName: "photo")
                .resizable()
                .scaledToFit()
                .frame(width: 44, height: 44)
                .foregroundColor(.gray.opacity(0.35))
            Text(AppText.get("no_image", lang: selectedLanguage))
                .font(.system(size: 9, weight: .medium))
                .foregroundColor(.gray.opacity(0.4))
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
