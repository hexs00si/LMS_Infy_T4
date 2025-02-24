//
//  LibrarianViewModel.swift
//  LMS_Infosys_T4
//
//  Created by Gaganveer Bawa on 23/02/25.
//
// LibrarianViewModel.swift
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
    }
}

class LibrarianViewModel: ObservableObject {
    @Published var librarians: [Librarian] = []
    @Published var isLoading = false
    @Published var error: String?
    
    private let db = Firestore.firestore()
    private let nodeServerURL = "http://localhost:3000"
    
    init() {
        fetchLibrarians()
    }
    
    func fetchLibrarians() {

        db.collection("librarians")
            .addSnapshotListener { [weak self] snapshot, error in
                if let error = error {
                    self?.error = error.localizedDescription
                    return
                }
                
                self?.librarians = snapshot?.documents.compactMap { document in
                    try? document.data(as: Librarian.self)
                } ?? []
            }
    }
    
    func createLibrarian(email: String, name: String, gender: String, phoneNumber: String, libraryID: String) async throws {
        isLoading = true
        error = nil
        
        do {
            // 1. Generate temporary password
//            let tempPassword = UUID().uuidString.prefix(8).string
            let tempPassword = String(UUID().uuidString.prefix(8))
            
            // 2. Create Auth user
            let authResult = try await Auth.auth().createUser(withEmail: email, password: tempPassword)
            
            // 3. Create Librarian document
            let newLibrarian = Librarian(
                uid: authResult.user.uid,
                libraryID: libraryID,
                email: email,
                name: name,
                gender: gender,
                phoneNumber: phoneNumber,
                joinDate: Date()
            )
            
            let batch = db.batch()
            
            // Add to librarians collection
            let librarianRef = db.collection("librarians").document(authResult.user.uid)
            try batch.setData(from: newLibrarian, forDocument: librarianRef)
            
            // Add to authUsers collection with firstLogin flag
            let authUserRef = db.collection("authUsers").document(authResult.user.uid)
            batch.setData([
                "userType": "librarian",
                "isFirstLogin": true,
                "email": email,
                "createdAt": Date()
            ], forDocument: authUserRef)
            
            try await batch.commit()
            
            // 4. Send email with temporary password
            try await sendTemporaryPassword(email: email, password: tempPassword)
            
            await MainActor.run {
                self.isLoading = false
            }
        } catch {
            await MainActor.run {
                self.error = error.localizedDescription
                self.isLoading = false
            }
            throw error
        }
    }
    
    private func sendTemporaryPassword(email: String, password: String) async throws {
        guard let url = URL(string: "\(nodeServerURL)/send-credentials") else {
            throw URLError(.badURL)
        }
        
        let body = [
            "email": email,
            "password": password
        ]
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        
        let (_, response) = try await URLSession.shared.data(for: request)
        guard (response as? HTTPURLResponse)?.statusCode == 200 else {
            throw NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Failed to send credentials"])
        }
    }
    
    func updateLibrarian(_ librarian: Librarian, name: String, gender: String, phoneNumber: String) async {
        guard let librarianId = librarian.id else { return }
        isLoading = true
        
        do {
            let updatedLibrarian = Librarian(
                id: librarian.id,
                uid: librarian.uid,
                libraryID: librarian.libraryID,
                email: librarian.email,
                name: name,
                gender: gender,
                phoneNumber: phoneNumber,
                image: librarian.image,
                joinDate: librarian.joinDate
            )
            
            try await db.collection("librarians").document(librarianId).setData(from: updatedLibrarian)
            
            await MainActor.run {
                self.isLoading = false
            }
        } catch {
            await MainActor.run {
                self.error = error.localizedDescription
                self.isLoading = false
            }
        }
    }
    
    func deleteLibrarian(_ librarian: Librarian) async {
        guard let librarianId = librarian.id else { return }
        
        do {
            let batch = db.batch()
            
            // Delete from librarians collection
            let librarianRef = db.collection("librarians").document(librarianId)
            batch.deleteDocument(librarianRef)
            
            // Delete from authUsers collection
            let authUserRef = db.collection("authUsers").document(librarianId)
            batch.deleteDocument(authUserRef)
            
            // Delete Auth user
//            try await Auth.auth().deleteUser(withEmail: librarian.email)
            
            try await batch.commit()
        } catch {
            self.error = error.localizedDescription
        }
    }
}
