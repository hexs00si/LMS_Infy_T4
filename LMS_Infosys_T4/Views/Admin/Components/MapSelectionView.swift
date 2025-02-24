import SwiftUI
import MapKit
import CoreLocation

struct MapSelectionView: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var coordinate: CLLocationCoordinate2D?
    @Binding var locationName: String
    @Binding var customLocation: String
    
    @State private var region: MKCoordinateRegion
    @State private var mapType: MKMapType = .standard
    @State private var searchText = ""
    @State private var searchResults: [MKMapItem] = []
    @State private var showSearchResults = false
    
    @StateObject private var locationManager = LocationManager()
    private let geocoder = CLGeocoder()
    
    init(coordinate: Binding<CLLocationCoordinate2D?>, locationName: Binding<String>, customLocation: Binding<String>, initialRegion: MKCoordinateRegion? = nil) {
        self._coordinate = coordinate
        self._locationName = locationName
        self._customLocation = customLocation
        
        // Default to user's location if possible, or fallback to default location
        if let initialRegion = initialRegion {
            self._region = State(initialValue: initialRegion)
        } else if let coord = coordinate.wrappedValue {
            self._region = State(initialValue: MKCoordinateRegion(
                center: coord,
                span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
            ))
        } else {
            // Default to Mumbai
            self._region = State(initialValue: MKCoordinateRegion(
                center: CLLocationCoordinate2D(latitude: 19.0760, longitude: 72.8777),
                span: MKCoordinateSpan(latitudeDelta: 0.1, longitudeDelta: 0.1)
            ))
        }
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                VStack(spacing: 0) {
                    // Search bar
                    HStack {
                        Image(systemName: "magnifyingglass")
                            .foregroundColor(.gray)
                            .padding(.leading, 8)
                        
                        TextField("Search for a location", text: $searchText)
                            .disableAutocorrection(true)
                            .onSubmit {
                                performSearch()
                                showSearchResults = true
                            }
                            .padding(.vertical, 10)
                        
                        if !searchText.isEmpty {
                            Button(action: {
                                searchText = ""
                                searchResults = []
                                showSearchResults = false
                            }) {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundColor(.gray)
                            }
                            .padding(.horizontal, 8)
                        }
                    }
                    .background(Color(.systemGray6))
                    .cornerRadius(10)
                    .padding(.horizontal)
                    .padding(.top, 8)
                    
                    // Map type selector
                    Picker("Map Type", selection: $mapType) {
                        Text("Standard").tag(MKMapType.standard)
                        Text("Satellite").tag(MKMapType.satellite)
                        Text("Hybrid").tag(MKMapType.hybrid)
                    }
                    .pickerStyle(SegmentedPickerStyle())
                    .padding(.horizontal)
                    .padding(.vertical, 8)
                    
                    // The map
                    ZStack {
                        Map(coordinateRegion: $region,
                            interactionModes: .all,
                            showsUserLocation: true,
                            userTrackingMode: .constant(.none),
                            annotationItems: annotationItems()) { item in
                            MapMarker(coordinate: item.coordinate, tint: .red)
                        }
                        .mapStyle(mapType == .standard ? .standard :
                                  mapType == .hybrid ? .hybrid : .imagery)
                        
                        // Centered pin
                        VStack {
                            Spacer()
                                .frame(height: 30)
                            Image(systemName: "mappin.circle.fill")
                                .font(.title)
                                .foregroundColor(.red)
                            
                            Image(systemName: "arrowtriangle.down.fill")
                                .font(.caption)
                                .foregroundColor(.red)
                                .offset(y: -5)
                            Spacer()
                        }
                        
                        // Bottom control buttons
                        VStack {
                            Spacer()
                            HStack {
                                // Use my current location button
                                Button(action: {
                                    useCurrentLocation()
                                }) {
                                    Image(systemName: "location.fill")
                                        .foregroundColor(.blue)
                                        .padding(12)
                                        .background(Color.white)
                                        .clipShape(Circle())
                                        .shadow(color: Color.black.opacity(0.2), radius: 4, x: 0, y: 2)
                                }
                                .padding()
                                
                                Spacer()
                            }
                        }
                    }
                    
                    // Selected location and custom name fields
                    VStack(spacing: 12) {
                        if !locationName.isEmpty {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Selected Location:")
                                    .font(.subheadline)
                                    .foregroundColor(.gray)
                                Text(locationName)
                                    .font(.headline)
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.top, 8)
                        }
                        
                        TextField("Custom Location Name (Optional)", text: $customLocation)
                            .padding(12)
                            .background(Color(.systemGray6))
                            .cornerRadius(8)
                    }
                    .padding(.horizontal)
                    .padding(.vertical, 12)
                    
                    // Action buttons
                    HStack {
                        Button(action: {
                            dismiss()
                        }) {
                            Text("Cancel")
                                .fontWeight(.medium)
                                .foregroundColor(.primary)
                                .frame(height: 50)
                                .frame(maxWidth: .infinity)
                                .background(Color(.systemGray5))
                                .cornerRadius(10)
                        }
                        
                        Button(action: {
                            // Update the coordinate and dismiss
                            coordinate = region.center
                            if customLocation.isEmpty {
                                updateLocationName(for: region.center)
                            }
                            dismiss()
                        }) {
                            Text("Select This Location")
                                .fontWeight(.medium)
                                .foregroundColor(.white)
                                .frame(height: 50)
                                .frame(maxWidth: .infinity)
                                .background(Color.blue)
                                .cornerRadius(10)
                        }
                    }
                    .padding(.horizontal)
                    .padding(.bottom, 16)
                }
                
                // Search results overlay
                if showSearchResults && !searchResults.isEmpty {
                    VStack {
                        VStack(alignment: .leading, spacing: 0) {
                            ForEach(searchResults, id: \.self) { item in
                                Button(action: {
                                    selectSearchResult(item)
                                    showSearchResults = false
                                }) {
                                    HStack {
                                        VStack(alignment: .leading, spacing: 4) {
                                            Text(item.name ?? "Unknown Location")
                                                .font(.headline)
                                                .foregroundColor(.primary)
                                            if let address = item.placemark.formattedAddress {
                                                Text(address)
                                                    .font(.subheadline)
                                                    .foregroundColor(.gray)
                                                    .lineLimit(1)
                                            }
                                        }
                                        Spacer()
                                    }
                                    .padding(.vertical, 10)
                                    .padding(.horizontal)
                                }
                                
                                if item != searchResults.last {
                                    Divider()
                                        .padding(.leading)
                                }
                            }
                        }
                        .background(Color(.systemBackground))
                        .cornerRadius(10)
                        .shadow(color: Color.black.opacity(0.2), radius: 5, x: 0, y: 5)
                        .padding(.horizontal)
                        
                        Spacer()
                    }
                    .padding(.top, 116) // Position below the search field
                }
            }
            .navigationTitle("Select Location")
            .navigationBarTitleDisplayMode(.inline)
            .onAppear {
                // When view appears, start location services
                locationManager.requestLocation()
                
                // If location is already provided, update the name
                if let coord = coordinate, locationName.isEmpty {
                    updateLocationName(for: coord)
                }
            }
            .onTapGesture {
                // Dismiss search results when tapping anywhere on the screen
                showSearchResults = false
                UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
            }
        }
    }
    
    // Helper function to create annotation items
    private func annotationItems() -> [MapAnnotationItem] {
        if let location = coordinate {
            return [MapAnnotationItem(coordinate: location)]
        }
        return []
    }
    
    // Get location name from coordinates using reverse geocoding
    private func updateLocationName(for coordinate: CLLocationCoordinate2D) {
        let location = CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)
        
        geocoder.reverseGeocodeLocation(location) { placemarks, error in
            if let error = error {
                print("Reverse geocoding error: \(error.localizedDescription)")
                return
            }
            
            if let placemark = placemarks?.first {
                let name = [
                    placemark.name,
                    placemark.locality,
                    placemark.administrativeArea,
                    placemark.country
                ].compactMap { $0 }.joined(separator: ", ")
                
                DispatchQueue.main.async {
                    locationName = name
                }
            }
        }
    }
    
    // Use the device's current location
    private func useCurrentLocation() {
        if let userLocation = locationManager.location?.coordinate {
            region = MKCoordinateRegion(
                center: userLocation,
                span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
            )
            updateLocationName(for: userLocation)
        } else {
            // If location is not available, request it again
            locationManager.requestLocation()
        }
    }
    
    // Search for locations
    private func performSearch() {
        guard !searchText.isEmpty else {
            searchResults = []
            return
        }
        
        let request = MKLocalSearch.Request()
        request.naturalLanguageQuery = searchText
        request.region = region
        
        let search = MKLocalSearch(request: request)
        search.start { response, error in
            guard let response = response, error == nil else {
                searchResults = []
                return
            }
            
            DispatchQueue.main.async {
                searchResults = response.mapItems
            }
        }
    }
    
    // Select a search result
    private func selectSearchResult(_ mapItem: MKMapItem) {
        let coordinate = mapItem.placemark.coordinate
        region = MKCoordinateRegion(
            center: coordinate,
            span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
        )
        
        if let name = mapItem.name {
            locationName = name
        }
        
        if let address = mapItem.placemark.formattedAddress {
            if !locationName.contains(address) {
                locationName = "\(locationName), \(address)"
            }
        }
        
        searchText = ""
        searchResults = []
    }
}

// Location Manager to handle location services
class LocationManager: NSObject, ObservableObject, CLLocationManagerDelegate {
    private let locationManager = CLLocationManager()
    @Published var location: CLLocation?
    
    override init() {
        super.init()
        self.locationManager.delegate = self
        self.locationManager.desiredAccuracy = kCLLocationAccuracyBest
    }
    
    func requestLocation() {
        locationManager.requestWhenInUseAuthorization()
        locationManager.requestLocation()
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        self.location = location
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("Location manager failed with error: \(error.localizedDescription)")
    }
}

// Helper struct for map annotations
struct MapAnnotationItem: Identifiable {
    let id = UUID()
    let coordinate: CLLocationCoordinate2D
}

// Helper for formatted address
extension MKPlacemark {
    var formattedAddress: String? {
        let components = [
            thoroughfare,
            subThoroughfare,
            locality,
            administrativeArea,
            postalCode,
            country
        ]
        return components.compactMap { $0 }.joined(separator: ", ")
    }
}
