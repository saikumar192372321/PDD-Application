import SwiftUI

struct ProductImageView: View {
    let imageName: String
    
    var body: some View {
        if imageName.isEmpty {
            Image(systemName: "photo")
                .resizable()
                .scaledToFit()
                .foregroundColor(.gray)
        } else if imageName.starts(with: "http") {
            AsyncImage(url: URL(string: imageName)) { phase in
                switch phase {
                case .empty:
                    ProgressView()
                case .success(let image):
                    image.resizable()
                        .scaledToFit()
                case .failure:
                    Image(systemName: "exclamationmark.triangle")
                        .foregroundColor(.red)
                @unknown default:
                    EmptyView()
                }
            }
        } else if let data = Data(base64Encoded: imageName), let uiImage = UIImage(data: data) {
            Image(uiImage: uiImage)
                .resizable()
                .scaledToFit()
        } else {
            // Check if it's a system image or a local asset
            if UIImage(systemName: imageName) != nil {
                Image(systemName: imageName)
                    .resizable()
                    .scaledToFit()
                    .foregroundColor(.secondary)
            } else {
                // Try to load as asset, if it fails, show prominent placeholder
                if UIImage(named: imageName) != nil {
                    Image(imageName)
                        .resizable()
                        .scaledToFit()
                } else {
                    VStack {
                        Image(systemName: "photo.artframe")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 60, height: 60)
                            .foregroundColor(.gray.opacity(0.4))
                        Text("No Image")
                            .font(.caption2)
                            .foregroundColor(.gray.opacity(0.5))
                    }
                }
            }
        }
    }
}
