//
//  Book.swift
//  LMS_Infosys_T4
//
//  Created by Gaganveer Bawa on 27/02/25.
//

import Foundation
import FirebaseFirestore
import FirebaseAuth

// Book model matching the ER diagram
struct Book: Identifiable, Codable, Hashable {
    @DocumentID var id: String?  // This will store the Firestore document ID
    let libraryID: String
    let addedByLibrarian: String
    let title: String
    let author: String
    let isbn: String
    var availabilityStatus: AvailabilityStatus
    let publishYear: Int
    let genre: String
    let coverImage: String?
    let description: String
    let quantity: Int
    var bookIssueCount = 0
    let availableCopies: Int
    
    // Add this function to decode base64 to UIImage
    func getCoverImage() -> UIImage? {
        guard let base64String = coverImage,
              let imageData = Data(base64Encoded: base64String) else {
            return nil
        }
        return UIImage(data: imageData)
    }

    enum CodingKeys: String, CodingKey {
        case id
        case libraryID
        case addedByLibrarian
        case title
        case author
        case isbn
        case availabilityStatus
        case publishYear
        case genre
        case coverImage
        case description
        case quantity
        case availableCopies
    }
}

// Enum for availabilityStatus
enum AvailabilityStatus: Int, Codable {
    case available = 1
    case checkedOut = 2
    case reserved = 3
    
    var description: String {
        switch self {
        case .available: return "Available"
        case .checkedOut: return "Checked Out"
        case .reserved: return "Reserved"
        }
    }
}

// Add this BookRequest model
struct BookRequest: Identifiable, Codable {
    @DocumentID var id: String?
    let requestId: String
    let userId: String
    let bookId: String
    let libraryuId: String
    let approvedByLibrarianId: String
    let requestDate: Date
    let status: String
    
    enum CodingKeys: String, CodingKey {
        case id
        case requestId
        case userId
        case bookId
        case libraryuId
        case approvedByLibrarianId
        case requestDate
        case status
    }
}

struct BookReservation: Identifiable, Codable {
    @DocumentID var id: String?
    let reservationId: String
    let userId: String
    let bookId: String  // This should be the book copy barcode
    let libraryId: String
    let reservationDate: Date
    let expirationDate: Date  // When the reservation expires if not picked up
    let status: ReservationStatus
    
    enum CodingKeys: String, CodingKey {
        case id
        case reservationId
        case userId
        case bookId
        case libraryId
        case reservationDate
        case expirationDate
        case status
    }
}

enum ReservationStatus: String, Codable {
    case active = "active"       // Reservation is currently active
    case expired = "expired"     // User didn't pick up in time
    case fulfilled = "fulfilled" // Book was picked up and issued
    case cancelled = "cancelled" // User or librarian cancelled
}
