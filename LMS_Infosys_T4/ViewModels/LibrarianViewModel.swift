//
//  LibrarianViewModel.swift
//  LMS_Infosys_T4
//

import Foundation
import FirebaseFirestore
import FirebaseAuth

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
        isLoading = true
        error = nil
        
        guard let adminId = Auth.auth().currentUser?.uid else {
            DispatchQueue.main.async {
                self.librarians = []
                self.isLoading = false
            }
            return
        }
        
        // First, get the admin document to check which libraries they manage
        let adminRef = db.collection("admins").document(adminId)
        
        adminRef.getDocument { [weak self] document, error in
            guard let self = self else { return }
            
            // Switch to the main thread for UI updates
            DispatchQueue.main.async {
                if let error = error {
                    self.error = error.localizedDescription
                    self.isLoading = false
                    return
                }
                
                guard let document = document, document.exists else {
                    self.librarians = []
                    self.isLoading = false
                    return
                }
                
                let data = document.data()
                let createdLibraries = data?["createdLibraries"] as? [String] ?? []
                
                guard !createdLibraries.isEmpty else {
                    self.librarians = []
                    self.isLoading = false
                    return
                }
                
                // First, fetch all libraries to create a lookup dictionary
                self.db.collection("libraries")
                    .whereField(FieldPath.documentID(), in: createdLibraries)
                    .getDocuments { [weak self] librarySnapshot, libraryError in
                        guard let self = self else { return }
                        
                        if let libraryError = libraryError {
                            DispatchQueue.main.async {
                                self.error = libraryError.localizedDescription
                                self.isLoading = false
                            }
                            return
                        }
                        
                        // Create a dictionary to map library IDs to library names and locations
                        var libraryLookup: [String: (name: String, location: String)] = [:]
                        
                        for document in librarySnapshot?.documents ?? [] {
                            let data = document.data()
                            let libraryID = document.documentID
                            let name = data["name"] as? String ?? "Unknown Library"
                            let location = data["location"] as? String ?? "Unknown Location"
                            
                            libraryLookup[libraryID] = (name: name, location: location)
                        }
                        
                        // Now, fetch all librarians who belong to these libraries
                        self.db.collection("librarians")
                            .whereField("libraryID", in: createdLibraries)
                            .getDocuments { snapshot, error in
                                // Switch to the main thread again for the final update
                                DispatchQueue.main.async {
                                    if let error = error {
                                        self.error = error.localizedDescription
                                        self.isLoading = false
                                        return
                                    }
                                    
                                    // Parse librarians and add library information
                                    var librarians = snapshot?.documents.compactMap { document in
                                        try? document.data(as: Librarian.self)
                                    } ?? []
                                    
                                    // Enhance librarians with library information
                                    for i in 0..<librarians.count {
                                        let libraryID = librarians[i].libraryID
                                        if let libraryInfo = libraryLookup[libraryID] {
                                            librarians[i].libraryName = libraryInfo.name
                                            librarians[i].libraryLocation = libraryInfo.location
                                        }
                                    }
                                    
                                    self.librarians = librarians
                                    self.isLoading = false
                                }
                            }
                    }
            }
        }
    }
    
    func createLibrarian(email: String, name: String, gender: String, phoneNumber: String, libraryID: String) async throws {
        await MainActor.run {
            isLoading = true
            error = nil
        }
        
        do {
            // 1. Generate temporary password
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
                // Call fetchLibrarians on the main thread
                self.fetchLibrarians()
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
        
        await MainActor.run {
            isLoading = true
            error = nil
        }
        
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
                // Call fetchLibrarians on the main thread
                self.fetchLibrarians()
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
        
        await MainActor.run {
            isLoading = true
            error = nil
        }
        
        do {
            let batch = db.batch()
            
            // Delete from librarians collection
            let librarianRef = db.collection("librarians").document(librarianId)
            batch.deleteDocument(librarianRef)
            
            // Delete from authUsers collection
            let authUserRef = db.collection("authUsers").document(librarianId)
            batch.deleteDocument(authUserRef)
            
            try await batch.commit()
            
            await MainActor.run {
                self.isLoading = false
                // Call fetchLibrarians on the main thread
                self.fetchLibrarians()
            }
        } catch {
            await MainActor.run {
                self.error = error.localizedDescription
                self.isLoading = false
            }
        }
    }
    
    func updateLibrarianWithFullObject(_ librarian: Librarian) async {
        guard let librarianId = librarian.id else { return }
        
        await MainActor.run {
            isLoading = true
            error = nil
        }
        
        do {
            // Use setData(from:) to update the entire librarian object
            try await db.collection("librarians").document(librarianId).setData(from: librarian)
            
            // Fetch the updated librarians after updating
            await MainActor.run {
                self.isLoading = false
                // Call fetchLibrarians on the main thread
                self.fetchLibrarians()
            }
        } catch {
            await MainActor.run {
                self.error = error.localizedDescription
                self.isLoading = false
            }
        }
    }
}
