import Foundation
import Combine
import CoreLocation
import MapKit

@MainActor
class LocationManager: NSObject, ObservableObject, CLLocationManagerDelegate {

    private let manager = CLLocationManager()
    @Published var location: CLLocation?
    @Published var region = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 16.5062, longitude: 80.6480), // Default to Vijayawada/India
        span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
    )
    
    override init() {
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyBest
    }
    
    func requestLocation() {
        manager.requestWhenInUseAuthorization()
        manager.startUpdatingLocation()
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        DispatchQueue.main.async {
            self.location = location
            self.region = MKCoordinateRegion(
                center: location.coordinate,
                span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
            )
        }
        manager.stopUpdatingLocation()
    }
    
    private var currentCompletion: ((CLLocation?, CLPlacemark?) -> Void)?

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("Location Manager Error: \(error.localizedDescription)")
        
        DispatchQueue.main.async {
            #if targetEnvironment(simulator)
            // Auto-recover on simulator error immediately
            let mockLoc = CLLocation(latitude: 16.5062, longitude: 80.6480)
            self.reverseGeocode(location: mockLoc) { placemark in
                self.currentCompletion?(mockLoc, placemark)
                self.currentCompletion = nil
            }
            #else
            self.currentCompletion?(nil, nil)
            self.currentCompletion = nil
            #endif
        }
    }
    
    func reverseGeocode(location: CLLocation, completion: @escaping (CLPlacemark?) -> Void) {
        let geocoder = CLGeocoder()
        geocoder.reverseGeocodeLocation(location) { placemarks, error in
            if let error = error {
                print("Reverse Geocode Error: \(error.localizedDescription)")
                completion(nil)
                return
            }
            completion(placemarks?.first)
        }
    }
    
    func getCurrentLocationAndAddress(completion: @escaping (CLLocation?, CLPlacemark?) -> Void) {
        self.currentCompletion = completion
        
        let status = manager.authorizationStatus
        if status == .denied || status == .restricted {
            print("Location access denied/restricted")
            completion(nil, nil)
            return
        }
        
        manager.requestWhenInUseAuthorization()
        
        // If we already have a reasonably fresh location, use it immediately
        if let lastLoc = manager.location, Date().timeIntervalSince(lastLoc.timestamp) < 60 {
            self.reverseGeocode(location: lastLoc) { placemark in
                completion(lastLoc, placemark)
                self.currentCompletion = nil
            }
            return
        }
        
        manager.requestLocation() // Better for single fix than startUpdatingLocation
        
        // Use a temporary observer to wait for the location update
        var observer: AnyCancellable?
        
        // Timeout handling (15 seconds for better chance of fix)
        let timeoutTimer = Timer.scheduledTimer(withTimeInterval: 15.0, repeats: false) { _ in
            if self.currentCompletion != nil {
                print("Location Fetch Timed Out - Using fallback")
                
                #if targetEnvironment(simulator)
                // Force a success on simulator for better dev experience
                let mockLoc = CLLocation(latitude: 16.5062, longitude: 80.6480)
                self.reverseGeocode(location: mockLoc) { placemark in
                    completion(mockLoc, placemark)
                }
                #else
                if let lastLoc = self.manager.location {
                    self.reverseGeocode(location: lastLoc) { placemark in
                        completion(lastLoc, placemark)
                    }
                } else {
                    completion(nil, nil)
                }
                #endif
                
                self.currentCompletion = nil
                observer?.cancel()
            }
        }

        observer = $location
            .compactMap { $0 }
            .first()
            .sink { location in
                timeoutTimer.invalidate()
                self.reverseGeocode(location: location) { placemark in
                    completion(location, placemark)
                    self.currentCompletion = nil
                    observer?.cancel()
                }
            }
    }
}
