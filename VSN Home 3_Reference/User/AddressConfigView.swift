import SwiftUI
import CoreLocation

struct AddressConfigView: View {
    @Binding var shopName: String
    @Binding var shopNumber: String
    @Binding var street: String
    @Binding var landmark: String
    @Binding var city: String
    @Binding var pincode: String
    @Binding var latitude: Double
    @Binding var longitude: Double
    var onSave: () -> Void
    
    @StateObject private var locationManager = LocationManager()
    @State private var showingMapPicker = false
    
    @Environment(\.dismiss) private var dismiss
    
    var isFormValid: Bool {
        !shopName.isEmpty && !street.isEmpty && !city.isEmpty && pincode.count >= 6
    }
    
    var body: some View {
        ZStack {
            AppBackground()
            
            // Intelligence Data Flourish
            RadialGradient(
                colors: [AppColors.secondary.opacity(0.1), .clear],
                center: .topLeading,
                startRadius: 0,
                endRadius: 500
            )
            .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Strategic Header
                HStack {
                    Button(action: { 
                        HapticManager.shared.trigger(.light)
                        dismiss() 
                    }) {
                        Image(systemName: "xmark")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(AppColors.textPrimary)
                            .padding(12)
                            .background(AppColors.textPrimary.opacity(0.05))
                            .clipShape(Circle())
                    }
                    
                    Spacer()
                    
                    VStack(spacing: 4) {
                        Text("Edit Delivery Address")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(AppColors.textSecondary)
                    }
                    
                    Spacer()
                    
                    // Empty spacer to center correctly
                    Color.clear.frame(width: 44)
                }
                .padding(.horizontal, 24)
                .padding(.top, 20)
                .padding(.bottom, 32)
                
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 32) {
                        // Section 1: Identity
                        VStack(alignment: .leading, spacing: 20) {
                            labelView(text: "BUSINESS IDENTITY")
                            
                            VStack(spacing: 16) {
                                vanguardInput(label: "SHOP NAME / ENTITY", text: $shopName, icon: "building.2.fill")
                                vanguardInput(label: "PLOT / SHOP NUMBER", text: $shopNumber, icon: "number")
                            }
                        }
                        
                        // Section 2: Geospatial Coordinates
                        VStack(alignment: .leading, spacing: 20) {
                            HStack {
                                labelView(text: "GEOSPATIAL COORDINATES")
                                
                                HStack(spacing: 8) {
                                    // Auto-detect button
                                    Button(action: {
                                        HapticManager.shared.notify(.success)
                                        locationManager.getCurrentLocationAndAddress { location, placemark in
                                            if let pm = placemark, let loc = location {
                                                street = [pm.subThoroughfare, pm.thoroughfare, pm.subLocality].compactMap { $0 }.joined(separator: ", ")
                                                city = pm.locality ?? ""
                                                pincode = pm.postalCode ?? ""
                                                latitude = loc.coordinate.latitude
                                                longitude = loc.coordinate.longitude
                                            }
                                        }
                                    }) {
                                        HStack(spacing: 4) {
                                            Image(systemName: "location.viewfinder")
                                            Text("AUTO-DETECT")
                                                .font(.system(size: 8, weight: .black))
                                        }
                                        .padding(.horizontal, 10)
                                        .padding(.vertical, 8)
                                        .background(AppColors.primary.opacity(0.1))
                                        .foregroundColor(AppColors.primary)
                                        .clipShape(Capsule())
                                        .overlay(Capsule().stroke(AppColors.primary.opacity(0.3), lineWidth: 1))
                                    }
                                    
                                    Button(action: {
                                        HapticManager.shared.trigger(.medium)
                                        showingMapPicker = true
                                    }) {
                                        HStack(spacing: 6) {
                                            Image(systemName: "map.fill")
                                            Text("PICK ON MAP")
                                                .font(.system(size: 8, weight: .black))
                                        }
                                        .padding(.horizontal, 10)
                                        .padding(.vertical, 8)
                                        .background(AppColors.secondary.opacity(0.1))
                                        .foregroundColor(AppColors.secondary)
                                        .clipShape(Capsule())
                                        .overlay(Capsule().stroke(AppColors.secondary.opacity(0.3), lineWidth: 1))
                                    }
                                }
                            }
                            
                            VStack(spacing: 16) {
                                vanguardInput(label: "STREET / AREA", text: $street, icon: "map.fill")
                                vanguardInput(label: "LANDMARK (OPTIONAL)", text: $landmark, icon: "mappin.and.ellipse")
                                
                                HStack(spacing: 16) {
                                    vanguardInput(label: "CITY", text: $city, icon: "building.columns.fill")
                                    vanguardInput(label: "PINCODE", text: $pincode, icon: "mailbox.fill")
                                        .keyboardType(.numberPad)
                                }
                                
                                if latitude != 0 {
                                    HStack {
                                        Image(systemName: "location.north.circle.fill")
                                            .foregroundColor(AppColors.success)
                                        Text("Coordinates Locked: \(latitude, specifier: "%.4f"), \(longitude, specifier: "%.4f")")
                                            .font(.system(size: 8, weight: .bold))
                                            .foregroundColor(AppColors.textSecondary.opacity(0.6))
                                        Spacer()
                                    }
                                    .padding(.top, 4)
                                }
                            }
                        }
                        
                        // Form Validation Message
                        if !isFormValid && (!shopName.isEmpty || !street.isEmpty) {
                            HStack {
                                Image(systemName: "exclamationmark.shield.fill")
                                Text("Incomplete data packets detected in the transmission.")
                                    .font(.caption2.bold())
                            }
                            .foregroundColor(.orange.opacity(0.7))
                            .padding(.top, 10)
                        }
                    }
                    .padding(24)
                    .padding(.bottom, 120)
                }
            }
            
            // Floating Action Button
            VStack {
                Spacer()
                
                Button(action: {
                    HapticManager.shared.trigger(.medium)
                    onSave()
                    dismiss()
                }) {
                    HStack(spacing: 12) {
                        Text("COMMIT COORDINATES")
                            .font(.system(size: 14, weight: .black))
                            .tracking(2)
                        Image(systemName: "arrow.right")
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 22)
                    .background(isFormValid ? AnyShapeStyle(AppColors.primaryGradient) : AnyShapeStyle(Color.white.opacity(0.05)))
                    .clipShape(RoundedRectangle(cornerRadius: 24))
                    .glow(color: isFormValid ? AppColors.primary : .clear, radius: 15)
                    .overlay(
                        RoundedRectangle(cornerRadius: 24)
                            .stroke(Color.white.opacity(isFormValid ? 0.2 : 0.05), lineWidth: 1)
                    )
                }
                .disabled(!isFormValid)
                .padding(24)
                .background(
                    LinearGradient(
                        colors: [.clear, AppColors.background.opacity(0.9), AppColors.background],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                    .ignoresSafeArea()
                )
            }
        }
        .fullScreenCover(isPresented: $showingMapPicker) {
            MapPickerView(
                street: $street,
                city: $city,
                pincode: $pincode,
                latitude: $latitude,
                longitude: $longitude
            )
        }
    }
    
    private func labelView(text: String) -> some View {
        HStack {
            Text(text)
                .font(.system(size: 10, weight: .black))
                .tracking(2)
                .foregroundColor(AppColors.textSecondary.opacity(0.4))
            Spacer()
            Rectangle()
                .fill(AppColors.textPrimary.opacity(0.05))
                .frame(height: 1)
        }
    }
    
    private func vanguardInput(label: String, text: Binding<String>, icon: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(label)
                .font(.system(size: 8, weight: .black))
                .foregroundColor(AppColors.secondary.opacity(0.8))
            
            HStack(spacing: 16) {
                Image(systemName: icon)
                    .font(.system(size: 14))
                    .foregroundColor(text.wrappedValue.isEmpty ? AppColors.textPrimary.opacity(0.1) : AppColors.secondary)
                    .frame(width: 20)
                
                TextField("", text: text)
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(AppColors.textPrimary)
            }
            .padding(18)
            .background(AppColors.textPrimary.opacity(0.03))
            .cornerRadius(20)
            .overlay(
                RoundedRectangle(cornerRadius: 20)
                    .stroke(text.wrappedValue.isEmpty ? AppColors.textPrimary.opacity(0.05) : AppColors.secondary.opacity(0.2), lineWidth: 1)
            )
        }
    }
}

#Preview {
    AddressConfigView(
        shopName: .constant("Vanguard Vijayawada Retail"),
        shopNumber: .constant("VIJ-520"),
        street: .constant("Benz Circle MG Road"),
        landmark: .constant("Near PVP Square"),
        city: .constant("Vijayawada"),
        pincode: .constant("520010"),
        latitude: .constant(0),
        longitude: .constant(0),
        onSave: {}
    )
}
