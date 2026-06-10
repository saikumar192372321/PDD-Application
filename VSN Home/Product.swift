import SwiftUI

// MARK: - Product Model
struct Product: Identifiable {
    let id = UUID()
    let name: String
    let price: Double
    let image: String
}

struct HomeView: View {

    @State private var searchText = ""

    // Sample Products (replace with API data)
    let products: [Product] = [
        Product(name: "Cement Bag", price: 450, image: "product1"),
        Product(name: "Steel Rod", price: 1200, image: "product2"),
        Product(name: "Bricks", price: 8, image: "product3"),
        Product(name: "Sand", price: 900, image: "product4"),
        Product(name: "Paint", price: 650, image: "product5"),
        Product(name: "Tiles", price: 55, image: "product6")
    ]

    // Grid Layout
    let columns = [
        GridItem(.flexible()),
        GridItem(.flexible())
    ]

    var filteredProducts: [Product] {
        if searchText.isEmpty {
            return products
        } else {
            return products.filter {
                $0.name.localizedCaseInsensitiveContains(searchText)
            }
        }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color(.systemGroupedBackground)
                    .ignoresSafeArea()

                ScrollView {

                    // Search Bar
                    HStack {
                        Image(systemName: "magnifyingglass")
                        TextField("Search products", text: $searchText)
                    }
                    .padding()
                    .background(Color.white)
                    .cornerRadius(12)
                    .padding()

                    // Product Grid
                    LazyVGrid(columns: columns, spacing: 16) {
                        ForEach(filteredProducts) { product in
                            ProductCard(product: product)
                        }
                    }
                    .padding(.horizontal)
                }
                .navigationTitle("All Products")
            }
        }
    }
}

// MARK: - Product Card
struct ProductCard: View {

    let product: Product

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {

            Image(product.image)
                .resizable()
                .scaledToFit()
                .frame(height: 120)
                .frame(maxWidth: .infinity)
                .background(Color.white)
                .cornerRadius(12)

            Text(product.name)
                .font(.headline)

            Text("₹\(product.price, specifier: "%.2f")")
                .font(.subheadline)
                .foregroundColor(.gray)

            Button("Add to Cart") {
                print("Added \(product.name)")
            }
            .font(.footnote)
            .frame(maxWidth: .infinity)
            .padding(8)
            .background(Color.blue)
            .foregroundColor(.white)
            .cornerRadius(10)
        }
        .padding()
        .background(Color.white)
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.05), radius: 5)
    }
}
