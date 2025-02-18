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
    
    func staffSignIn(email: String, password: String) async throws -> AuthUser {
        print("Attempting to sign in with email: \(email)")
        let result = try await auth.signIn(withEmail: email, password: password)
        print("Sign-in successful for user: \(result.user.uid)")
        let uid = result.user.uid
        
        // 2. Get user data from AuthUsers
        let authDoc = try await db.collection("authUsers").document(uid).getDocument()
        
        guard let authData = authDoc.data(),
              let userType = authData["userType"] as? String,
              let userTypeEnum = UserType(rawValue: userType),
              let isFirstLogin = authData["isFirstLogin"] as? Bool else {
            throw AuthError.invalidUserData
        }
        
        // 3. If it's admin and first login, create admin document
        if userTypeEnum == .admin && isFirstLogin {
            let adminData: [String: Any] = [
                "uid": uid,
                "email": email,
                "createdLibraries": []
            ]
            
            try await db.collection("admins").document(uid).setData(adminData)
        }
        
        return AuthUser(
            id: uid,
            email: email,
            userType: userTypeEnum,
            isFirstLogin: isFirstLogin,
            createdAt: Date()
        )
    }
//    heelo
    
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

