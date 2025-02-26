//
//  Librarian.swift
//  LMS_Infosys_T4
//
//  Created by Gaganveer Bawa on 27/02/25.
//

import Foundation
import FirebaseFirestore
import FirebaseAuth


struct Librarian: Identifiable, Codable {
    @DocumentID var id: String?
    let uid: String
    let libraryID: String
    let email: String
    var name: String
    var gender: String
    var phoneNumber: String
    var image: String?
    let joinDate: Date
    
    // Library information - not stored in Firestore, but populated after fetch
    var libraryName: String?
    var libraryLocation: String?
    
    enum CodingKeys: String, CodingKey {
        case id
        case uid
        case libraryID
        case email
        case name
        case gender
        case phoneNumber
        case image
        case joinDate
        // libraryName and libraryLocation are not included in CodingKeys
        // as they are not stored in Firestore
    }
}
