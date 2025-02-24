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
       
       isLoading = true
       
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
                   self.libraries = []
                   self.isLoading = false
                   return
               }
               
               let data = document.data()
               let createdLibraries = data?["createdLibraries"] as? [String] ?? []
               
               guard !createdLibraries.isEmpty else {
                   self.libraries = []
                   self.isLoading = false
                   return
               }
               
               // Fetch libraries that match the IDs in createdLibraries
               self.db.collection("libraries")
                   .whereField(FieldPath.documentID(), in: createdLibraries)
                   .getDocuments { snapshot, error in
                       // Switch to the main thread again for the final update
                       DispatchQueue.main.async {
                           if let error = error {
                               self.error = error.localizedDescription
                               self.isLoading = false
                               return
                           }
                           
                           self.libraries = snapshot?.documents.compactMap { document in
                               try? document.data(as: Library.self)
                           } ?? []
                           
                           self.isLoading = false
                       }
                   }
           }
       }
   }

   func createLibrary(name: String, location: String, finePerDay: Float, maxBooksPerUser: Int) async {
       await MainActor.run {
           isLoading = true
           error = nil
       }
       
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
           
           // Fetch the updated libraries after creating a new one
           await MainActor.run {
               self.isLoading = false
               // Call fetchLibraries on the main thread
               self.fetchLibraries()
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
           
           // Fetch the updated libraries after deleting
           await MainActor.run {
               // Call fetchLibraries on the main thread
               self.fetchLibraries()
           }
       } catch {
           await MainActor.run {
               self.error = error.localizedDescription
           }
       }
   }
    
   func updateLibrary(_ library: Library, name: String, location: String, finePerDay: Float, maxBooksPerUser: Int) async {
       guard let libraryId = library.id else { return }
       
       await MainActor.run {
           isLoading = true
           error = nil
       }
       
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
           
           // Fetch the updated libraries after updating
           await MainActor.run {
               self.isLoading = false
               // Call fetchLibraries on the main thread
               self.fetchLibraries()
           }
       } catch {
           await MainActor.run {
               self.error = error.localizedDescription
               self.isLoading = false
           }
       }
   }
}
