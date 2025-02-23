//
//  User.swift
//  LMS
//
//  Created by Gaganveer Bawa on 13/02/25.
//

import Foundation
import FirebaseFirestore
//import FirebaseFirestoreSwift

struct User: Codable, Identifiable {
    @DocumentID var id: String?
    let name: String
    let email: String
    let password: String
    let gender: String
    let phoneNumber: String
    let joinDate: Date
    var issuedBooks: [String]
    var currentlyIssuedCount: Int
    
    enum CodingKeys: String, CodingKey {
        case id = "uid"
        case name, email, password, gender
        case phoneNumber, joinDate, issuedBooks
        case currentlyIssuedCount
    }
}
