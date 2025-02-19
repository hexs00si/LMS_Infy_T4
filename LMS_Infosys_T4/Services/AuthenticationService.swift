//
//  AuthenticationService.swift
//  LMS_Infosys_T4
//
//  Created by Shravan Rajput on 18/02/25.
//

import Foundation
import FirebaseAuth
import FirebaseFirestore

class AuthenticationService: ObservableObject {
    private let auth = Auth.auth()
    private let db = Firestore.firestore()
    
    func signIn(email: String, password: String) async throws -> AuthUser {
        print("Attempting to sign in with email: \(email)")
        let result = try await auth.signIn(withEmail: email, password: password)
        print("Sign-in successful for user: \(result.user.uid)")
        let uid = result.user.uid
        
        print("Querying Firestore for document: authUsers/\(uid)")
        let authDoc = try await db.collection("authUsers").document(uid).getDocument()
        print("Document data: \(String(describing: authDoc.data()))")
        
        guard let authData = authDoc.data(),
              let userType = authData["userType"] as? String,
              let userTypeEnum = UserType(rawValue: userType),
              let isFirstLogin = authData["isFirstLogin"] as? Bool else {
            throw AuthError.invalidUserData
        }
        
        print("Parsed user data: userType = \(userTypeEnum), isFirstLogin = \(isFirstLogin)")
        
        // Create respective documents if needed
        if isFirstLogin {
            let batch = db.batch()
            
            switch userTypeEnum {
            case .admin:
                let adminData: [String: Any] = [
                    "uid": uid,
                    "email": email,
                    "createdLibraries": []
                ]
                let adminRef = db.collection("admins").document(uid)
                batch.setData(adminData, forDocument: adminRef)
                
            case .librarian:
                let librarianData: [String: Any] = [
                    "uid": uid,
                    "email": email,
                    "name": "",
                    "gender": "",
                    "phoneNumber": "",
                    "image": "",
                    "joinDate": Date()
                ]
                let librarianRef = db.collection("librarians").document(uid)
                batch.setData(librarianData, forDocument: librarianRef)
                
            case .member:
                let userData: [String: Any] = [
                    "uid": uid,
                    "name": "",
                    "email": email,
                    "gender": "",
                    "phoneNumber": "",
                    "joinDate": Date(),
                    "issuedBooks": [],
                    "currentlyIssuedCount": 0
                ]
                let userRef = db.collection("users").document(uid)
                batch.setData(userData, forDocument: userRef)
            }
            
            try await batch.commit()
        }
        
        return AuthUser(
            id: uid,
            email: email,
            userType: userTypeEnum,
            isFirstLogin: isFirstLogin,
            createdAt: Date()
        )
    }
    
    func updatePassword(newPassword: String) async throws {
        guard let user = auth.currentUser else {
            throw AuthError.notAuthenticated
        }
        
        try await user.updatePassword(to: newPassword)
        
        // Update isFirstLogin in AuthUsers
        try await db.collection("authUsers").document(user.uid).updateData([
            "isFirstLogin": false
        ])
    }
}

enum AuthError: Error {
    case invalidUserData
    case notAuthenticated
    case notAuthorized
}

