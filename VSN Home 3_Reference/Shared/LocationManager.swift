import Foundation
import Combine
import CoreLocation
import MapKit

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
        self.location = location
        self.region = MKCoordinateRegion(
            center: location.coordinate,
            span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
        )
        manager.stopUpdatingLocation()
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("Location Manager Error: \(error.localizedDescription)")
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
        manager.requestWhenInUseAuthorization()
        manager.startUpdatingLocation()
        
        // Use a temporary observer to wait for the location update
        var observer: AnyCancellable?
        observer = $location
            .compactMap { $0 }
            .first()
            .sink { location in
                self.reverseGeocode(location: location) { placemark in
                    completion(location, placemark)
                    observer?.cancel()
                }
            }
    }
}
