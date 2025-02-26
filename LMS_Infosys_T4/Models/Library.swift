import Foundation
import FirebaseFirestore
import CoreLocation

struct Library: Identifiable, Codable {
    var id: String?  // This satisfies Identifiable protocol
    let adminuid: String
    let name: String
    let location: String
    // Add coordinates for map location
    let latitude: Double
    let longitude: Double
    let maxBooksPerUser: Int
    let loanDuration: Int
    let finePerDay: Float
    var totalBooks: Int
    var lastUpdated: Date
    var isActive: Bool
    
    enum CodingKeys: String, CodingKey {
        case id = "libraryID"  // Map 'id' to 'libraryID' in Firestore
        case adminuid
        case name
        case location
        case latitude
        case longitude
        case maxBooksPerUser
        case loanDuration
        case finePerDay
        case totalBooks
        case lastUpdated
        case isActive
    }
    
    // Computed property to get CLLocationCoordinate2D for MapKit
    var coordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }
}
