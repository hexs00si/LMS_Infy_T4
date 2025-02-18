//
//  AuthUser.swift
//  LMS_Infosys_T4
//
//  Created by Shravan Rajput on 18/02/25.
//

import Foundation
import FirebaseFirestore

enum UserType: String, Codable {
    case admin
    case librarian
    case member
}

struct AuthUser: Identifiable, Codable {
    var id: String?  // Changed from @DocumentID since we're not using FirebaseFirestoreSwift
    let email: String
    let userType: UserType
    var isFirstLogin: Bool
    let createdAt: Date
    
    enum CodingKeys: String, CodingKey {
        case id
        case email
        case userType
        case isFirstLogin
        case createdAt
    }
}

