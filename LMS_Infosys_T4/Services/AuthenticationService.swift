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
            case .librarian:
                print("dakki")
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
    
    // Add sign out method
    func signOut() throws {
        do {
            try auth.signOut()
            print("✅ Successfully signed out user")
        } catch {
            print("❌ Error signing out: \(error.localizedDescription)")
            throw error
        }
    }
    
    func completeSignUp(password: String, user: User, organizationID: String, completion: @escaping (Bool, String?) -> Void) {
        auth.createUser(withEmail: user.email, password: password) { [weak self] authResult, error in
            if let error = error {
                print("❌ Firebase Auth user creation failed: \(error.localizedDescription)")
                completion(false, error.localizedDescription)
                return
            }
            
            guard let userId = authResult?.user.uid else {
                print("❌ User ID not found after authentication")
                completion(false, "User authentication failed.")
                return
            }
            
            print("✅ User created in Firebase Auth, now storing in Firestore (authUsers)...")
            
            // Firestore Reference
            let db = Firestore.firestore()
            let authUserRef = db.collection("authUsers").document(userId)
            let memberRef = db.collection("members").document(userId)
            
            let memberData: [String: Any] = [
                "name": user.name,
                "email": user.email,
                "gender": user.gender,
                "phoneNumber": user.phoneNumber,
                "organizationID": organizationID,
                "joinDate": Timestamp(date: Date()),  // Firestore Timestamp
                "issuedBooks": [],
                "issuedCount": 0
            ]
            
            let authUserData: [String: Any] = [
                "email": user.email,
                "isFirstLogin": false,
                "userType": "member",
                "createdAt": Timestamp(date: Date())  // Firestore Timestamp
            ]
            
            print("📌 Writing data to Firestore: \(authUserData)")
            print("📌 Writing data to Firestore: \(memberData) (members)")
            
            // Save both documents using batch
            let batch = db.batch()
            batch.setData(authUserData, forDocument: authUserRef)
            batch.setData(memberData, forDocument: memberRef)
            
            batch.commit { error in
                if let error = error {
                    print("❌ Firestore batch write failed: \(error.localizedDescription)")
                    completion(false, "Error saving user data: \(error.localizedDescription)")
                } else {
                    print("✅ Firestore write successful (authUsers & members)")
                    completion(true, nil)
                }
            }
        }
    }
    
    private func storeUserInDatabase(userId: String, user: User, organizationID: String, completion: @escaping (Bool, String?) -> Void) {
        print("➡️ Storing user in Firestore (authUsers only) for testing: \(userId)")
        
        let authUserRef = db.collection("authUsers").document(userId)
        
        let authUserData: [String: Any] = [
            "email": user.email,
            "isFirstLogin": true,
            "userType": "member",
            "createdAt": Timestamp(date: Date())  // Firestore Timestamp
        ]
        
        authUserRef.setData(authUserData) { error in
            if let error = error {
                print("❌ Firestore write failed: \(error.localizedDescription)")
                completion(false, "Error saving user data: \(error.localizedDescription)")
            } else {
                print("✅ Firestore write successful (authUsers only)")
                completion(true, nil)
            }
        }
    }
}

enum AuthError: Error {
    case invalidUserData
    case notAuthenticated
    case notAuthorized
}
