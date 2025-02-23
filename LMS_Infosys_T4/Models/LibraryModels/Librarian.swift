//
//  Librarian.swift
//  LMS
//
//  Created by Gaganveer Bawa on 13/02/25.
//

import Foundation
import FirebaseFirestore

//struct Librarian: Codable, Identifiable {
//    @DocumentID var id: String?
//    let libraryID: String
//    let image: String
//    let email: String
//    let password: String
//    let name: String
//    let gender: String
//    let phoneNumber: String
//    let joinDate: Date
//    
//    enum CodingKeys: String, CodingKey {
//        case id = "uid"
//        case libraryID, image, email, password
//        case name, gender, phoneNumber, joinDate
//    }
//}


struct Librarian: Identifiable {
    let id: UUID
    var name: String
    var library: String
    var email: String
    var contactNumber: String
    var image: String?
    
    init(id: UUID = UUID(), name: String, library: String, email: String, contactNumber: String, image: String? = nil) {
        self.id = id
        self.name = name
        self.library = library
        self.email = email
        self.contactNumber = contactNumber
        self.image = image
    }
}
