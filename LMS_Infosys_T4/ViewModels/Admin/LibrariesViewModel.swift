//
//  LibrariesViewModel.swift
//  LMS_Infosys_T4
//
//  Created by Shravan Rajput on 19/02/25.
//

import Foundation
import FirebaseFirestore
import FirebaseAuth

class LibrariesViewModel: ObservableObject {
   @Published var libraries: [Library] = []
   @Published var isLoading = false
   @Published var error: String?
   
   private let db = Firestore.firestore()
   
   init() {
       fetchLibraries()
   }
   
   func fetchLibraries() {
       guard let adminId = Auth.auth().currentUser?.uid else { return }
       
       db.collection("libraries")
           .whereField("adminuid", isEqualTo: adminId)
           .addSnapshotListener { [weak self] snapshot, error in
               if let error = error {
                   self?.error = error.localizedDescription
                   return
               }
               
               self?.libraries = snapshot?.documents.compactMap { document in
                   try? document.data(as: Library.self)
               } ?? []
           }
   }
   
   func createLibrary(name: String, location: String, finePerDay: Float, maxBooksPerUser: Int) async {
       isLoading = true
       error = nil
       
       do {
           guard let adminId = Auth.auth().currentUser?.uid else {
               throw NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "User not logged in"])
           }
           
           let newLibrary = Library(
               id: UUID().uuidString,
               adminuid: adminId,
               name: name,
               location: location,
               maxBooksPerUser: maxBooksPerUser,
               loanDuration: 14, // Default 2 weeks
               finePerDay: finePerDay,
               totalBooks: 0,
               lastUpdated: Date(),
               isActive: true
           )
           
           let batch = db.batch()
           
           let libraryRef = db.collection("libraries").document(newLibrary.id!)
           try batch.setData(from: newLibrary, forDocument: libraryRef)
           
           let adminRef = db.collection("admins").document(adminId)
           batch.updateData([
               "createdLibraries": FieldValue.arrayUnion([newLibrary.id!])
           ], forDocument: adminRef)
           
           try await batch.commit()
           
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
   
   func validateLibraryInput(name: String, location: String, finePerDay: Float) -> Bool {
       !name.isEmpty && !location.isEmpty && finePerDay > 0
   }
   
   func deleteLibrary(_ library: Library) async {
       guard let libraryId = library.id,
             let adminId = Auth.auth().currentUser?.uid else { return }
       
       do {
           let batch = db.batch()
           
           let libraryRef = db.collection("libraries").document(libraryId)
           batch.deleteDocument(libraryRef)
           
           let adminRef = db.collection("admins").document(adminId)
           batch.updateData([
               "createdLibraries": FieldValue.arrayRemove([libraryId])
           ], forDocument: adminRef)
           
           try await batch.commit()
       } catch {
           self.error = error.localizedDescription
       }
   }
    
//    updating libraries
    func updateLibrary(_ library: Library, name: String, location: String, finePerDay: Float, maxBooksPerUser: Int) async {
        guard let libraryId = library.id else { return }
        isLoading = true
        error = nil
        
        do {
            let updatedLibrary = Library(
                id: library.id,
                adminuid: library.adminuid,
                name: name,
                location: location,
                maxBooksPerUser: maxBooksPerUser,
                loanDuration: library.loanDuration,
                finePerDay: finePerDay,
                totalBooks: library.totalBooks,
                lastUpdated: Date(),
                isActive: library.isActive
            )
            
            try await db.collection("libraries").document(libraryId).setData(from: updatedLibrary)
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
    
}

