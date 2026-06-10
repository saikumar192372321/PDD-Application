import SwiftUI
import MapKit
import CoreLocation

struct MapPickerView: View {
    @StateObject private var locationManager = LocationManager()
    @Binding var street: String
    @Binding var city: String
    @Binding var pincode: String
    @Binding var latitude: Double
    @Binding var longitude: Double
    
    @Environment(\.dismiss) private var dismiss
    @State private var region = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 21.1458, longitude: 79.0882),
        span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
    )
    
    @State private var searchText = ""
    @State private var isSearching = false
    
    var body: some View {
        ZStack {
            Map(coordinateRegion: $region, showsUserLocation: true)
                .ignoresSafeArea()
            
            // Center Pin Indicator
            Image(systemName: "mappin")
                .font(.system(size: 30, weight: .bold))
                .foregroundColor(AppColors.secondary)
                .offset(y: -15)
                .animation(.spring(), value: region.center.latitude)
            
            VStack {
                // Search Bar & Controls
                VStack(spacing: 12) {
                    HStack(spacing: 12) {
                        Button(action: { dismiss() }) {
                            Image(systemName: "xmark")
                                .font(.system(size: 14, weight: .bold))
                                .foregroundColor(.white)
                                .padding(12)
                                .background(Color.black.opacity(0.6))
                                .clipShape(Circle())
                        }
                        
                        // New Search Input
                        HStack {
                            Image(systemName: "magnifyingglass")
                                .foregroundColor(AppColors.secondary)
                            TextField("", text: $searchText, prompt: Text("Search location...").foregroundColor(.white.opacity(0.3)))
                                .font(.subheadline)
                                .foregroundColor(.white)
                                .submitLabel(.search)
                                .onSubmit { performSearch() }
                            
                            if !searchText.isEmpty {
                                Button(action: { searchText = "" }) {
                                    Image(systemName: "xmark.circle.fill")
                                        .foregroundColor(.white.opacity(0.3))
                                }
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
                        .background(Color.black.opacity(0.6))
                        .cornerRadius(12)
                        .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.white.opacity(0.1), lineWidth: 1))
                        
                        Button(action: { locationManager.requestLocation() }) {
                            Image(systemName: "location.fill")
                                .font(.system(size: 14))
                                .foregroundColor(.white)
                                .padding(12)
                                .background(Color.black.opacity(0.6))
                                .clipShape(Circle())
                        }
                    }
                }
                .padding()
                
                Spacer()
                
                VStack(spacing: 16) {
                    Text("Align the marker to your location")
                        .font(.caption2.bold())
                        .foregroundColor(AppColors.textPrimary.opacity(0.6))
                    
                    Button(action: {
                        let location = CLLocation(latitude: region.center.latitude, longitude: region.center.longitude)
                        locationManager.reverseGeocode(location: location) { placemark in
                            if let pm = placemark {
                                street = [pm.subThoroughfare, pm.thoroughfare, pm.subLocality].compactMap { $0 }.joined(separator: ", ")
                                city = pm.locality ?? ""
                                pincode = pm.postalCode ?? ""
                                latitude = region.center.latitude
                                longitude = region.center.longitude
                                dismiss()
                            }
                        }
                    }) {
                        HStack {
                            Text("CONFIRM LOCATION")
                                .font(.system(size: 14, weight: .black))
                                .tracking(2)
                            Image(systemName: "checkmark")
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 18)
                        .background(AppColors.primaryGradient)
                        .cornerRadius(20)
                        .glow(color: AppColors.primary, radius: 10)
                    }
                }
                .padding(24)
                .background(
                    BlurView(style: .systemThinMaterialLight)
                        .clipShape(RoundedRectangle(cornerRadius: 30))
                )
                .padding()
                .padding(.bottom, 20)
            }
        }
        .onAppear {
            locationManager.requestLocation()
        }
        .onChange(of: locationManager.location) { newLocation in
            if let loc = newLocation {
                DispatchQueue.main.async {
                    withAnimation {
                        region = MKCoordinateRegion(
                            center: loc.coordinate,
                            span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
                        )
                    }
                }
            }
        }
    }
    
    private func performSearch() {
        guard !searchText.isEmpty else { return }
        let request = MKLocalSearch.Request()
        request.naturalLanguageQuery = searchText
        request.region = region
        
        let search = MKLocalSearch(request: request)
        search.start { response, error in
            guard let response = response else { return }
            if let firstItem = response.mapItems.first {
                withAnimation(.spring()) {
                    region = MKCoordinateRegion(
                        center: firstItem.placemark.coordinate,
                        span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
                    )
                }
            }
        }
    }
}
