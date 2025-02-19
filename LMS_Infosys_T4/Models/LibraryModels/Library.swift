//
//  Library.swift
//  LMS_Infosys_T4
//
//  Created by Shravan Rajput on 19/02/25.
//
import Foundation
import FirebaseFirestore

struct Library: Identifiable, Codable {
    var id: String?  // This satisfies Identifiable protocol
    let adminuid: String
    let name: String
    let location: String
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
        case maxBooksPerUser
        case loanDuration
        case finePerDay
        case totalBooks
        case lastUpdated
        case isActive
    }
}
