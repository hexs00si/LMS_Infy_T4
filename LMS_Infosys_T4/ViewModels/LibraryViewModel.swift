import Foundation
import FirebaseFirestore
import FirebaseAuth


class LibraryViewModel: ObservableObject {
    @Published var books: [Book] = []
    @Published var isLoading = false
    @Published var error: String?
    @Published var pendingRequests: [BookRequest] = []
    @Published var activeReservations: [BookReservation] = []
    
    private let db = Firestore.firestore()
    
    func addBook(_ book: Book) async throws {
        await MainActor.run {
            isLoading = true
            error = nil
        }
        
        do {
            // Create a new document reference to get the auto-generated ID
            let newBookRef = db.collection("books").document()
            
            // Create the book with the document ID
            var newBook = book
            newBook.id = newBookRef.documentID
            
            // Convert book to dictionary
            let bookData = try Firestore.Encoder().encode(newBook)
            
            // Reference the library document
            let libraryRef = db.collection("libraries").document(book.libraryID)
            
            // Create a batch
            let batch = db.batch()
            
            // Add the main book document
            batch.setData(bookData, forDocument: newBookRef)
            
            // Create individual copies in the bookCopies subcollection
            for copyNumber in 1...book.quantity {
                let barcode = generateBarcode(bookID: newBookRef.documentID, copyNumber: copyNumber)
                let copyRef = newBookRef.collection("bookCopies").document(barcode)
                
                let copyData: [String: Any] = [
                    "barcode": barcode,
                    "status": "available",
                    "libraryID": book.libraryID
                ]
                
                batch.setData(copyData, forDocument: copyRef)
            }
            
            // Increment totalBooks in the libraries collection by the book's quantity
            batch.updateData([
                "totalBooks": FieldValue.increment(Int64(book.quantity))
            ], forDocument: libraryRef)
            
            // Commit the batch
            try await batch.commit()
            
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
    
    func fetchPendingBookRequests() async throws {
//        isLoading = true
//        error = nil
        await MainActor.run {
            isLoading = true
            error = nil
        }
        
        do {
            // Get the current logged-in user
            guard let currentUser = Auth.auth().currentUser else {
                throw NSError(domain: "AuthError", code: 401, userInfo: [NSLocalizedDescriptionKey: "No user is currently logged in"])
            }
            
            // First, get the librarian document to find which library they're assigned to
            let librarianDoc = try await db.collection("librarians").document(currentUser.uid).getDocument()
            
            guard let librarianData = librarianDoc.data(),
                  let assignedLibraryID = librarianData["libraryID"] as? String else {
                throw NSError(domain: "LibraryError", code: 401, userInfo: [NSLocalizedDescriptionKey: "User is not a librarian or not assigned to any library"])
            }
            
            // Now get pending book requests for this library
            let requestsSnapshot = try await db.collection("bookRequests")
                .whereField("libraryuId", isEqualTo: assignedLibraryID)
                .whereField("status", isEqualTo: "pending")
                .getDocuments()
            
            // Process the pending requests
            let pendingRequests = requestsSnapshot.documents.compactMap { document -> BookRequest? in
                do {
                    return try document.data(as: BookRequest.self)
                } catch {
                    print("Error decoding book request: \(error)")
                    return nil
                }
            }
            
            await MainActor.run {
                self.pendingRequests = pendingRequests
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
    
    func fetchUserBookRequests() async throws {
        await MainActor.run {
            isLoading = true
            error = nil
        }
        
        do {
            // Get the current logged-in user
            guard let currentUser = Auth.auth().currentUser else {
                throw NSError(domain: "AuthError", code: 401, userInfo: [NSLocalizedDescriptionKey: "No user is currently logged in"])
            }
            
            // Query book requests where userId matches the current user
            let requestsSnapshot = try await db.collection("bookRequests")
                .whereField("userId", isEqualTo: currentUser.uid)
                .getDocuments()
            
            // Decode the requests
            let userRequests = requestsSnapshot.documents.compactMap { document -> BookRequest? in
                do {
                    return try document.data(as: BookRequest.self)
                } catch {
                    print("Error decoding book request: \(error)")
                    return nil
                }
            }
            
            // Update UI on the main thread
            await MainActor.run {
                self.pendingRequests = userRequests
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
    
    func requestBook(book: Book, copyID: String) async throws {
        let db = Firestore.firestore()
        let bookRef = db.collection("books").document(book.id!)
        
        // Reference the specified book copy by copyID
        let bookCopyRef = bookRef.collection("bookCopies").document(copyID)
        let bookCopySnapshot = try await bookCopyRef.getDocument()
        
        guard let bookCopyData = bookCopySnapshot.data(),
              let status = bookCopyData["status"] as? String, status == "available" else {
            throw NSError(domain: "LibraryError", code: 400, userInfo: [NSLocalizedDescriptionKey: "The specified book copy is not available."])
        }
        
        let bookRequestRef = db.collection("bookRequests").document()
        let requestDate = Date()
        
        // Prepare request data
        let requestData: [String: Any] = [
            "requestId": bookRequestRef.documentID,
            "userId": Auth.auth().currentUser!.uid,
            "bookId": copyID,
            "libraryuId": book.libraryID,
            "approvedByLibrarianId": "",
            "requestDate": Timestamp(date: requestDate),
            "status": "pending"
        ]
        
        // Perform Firestore batch operation
        let batch = db.batch()
        
        // Update book copy status to "pending"
        batch.updateData(["status": "pending"], forDocument: bookCopyRef)
        
        batch.updateData(["availableCopies": FieldValue.increment(Int64(-1))], forDocument: bookRef)
        
        // Add book request record
        batch.setData(requestData, forDocument: bookRequestRef)
        
        // Commit batch
        try await batch.commit()
    }

    private func generateBarcode(bookID: String, copyNumber: Int) -> String {
        // Generate a unique barcode using book ID and copy number
        // You can customize this format according to your needs
        return "\(bookID)-\(String(format: "%03d", copyNumber))"
    }
    
    // Function to fetch books
    func fetchBooks() {
        db.collection("books")
            .addSnapshotListener { [weak self] snapshot, error in
                if let error = error {
                    self?.error = error.localizedDescription
                    return
                }
                
                self?.books = snapshot?.documents.compactMap { document in
                    try? document.data(as: Book.self)
                } ?? []
            }
    }
    
    func approveBookRequest(_ request: BookRequest) async throws {
        // Get a new document reference for the book issue
        let db = Firestore.firestore()
        let newIssueRef = db.collection("bookIssues").document()
        
        // Get the librarian ID (current user)
        guard let currentUser = Auth.auth().currentUser else {
            throw NSError(domain: "AuthError", code: 401, userInfo: [NSLocalizedDescriptionKey: "No user is currently logged in"])
        }
        
        // Calculate issue and due dates
        let issueDate = Date()
        guard let dueDate = Calendar.current.date(byAdding: .month, value: 1, to: issueDate) else {
            throw NSError(domain: "DateError", code: 500, userInfo: [NSLocalizedDescriptionKey: "Failed to calculate due date"])
        }
        
        // Create book issue data
        let bookIssueData: [String: Any] = [
            "issueID": newIssueRef.documentID,
            "requestID": request.requestId,
            "userId": request.userId,
            "bookId": request.bookId,
            "libraryId": request.libraryuId,
            "issuedByLibrarianId": currentUser.uid,
            "issueDate": Timestamp(date: issueDate),
            "dueDate": Timestamp(date: dueDate),
            "returnDate": NSNull(),
            "isReturned": false,
            "fineAmount": 0,
            "status": "issued"
        ]
        
        // Update request status
        let requestRef = db.collection("bookRequests").document(request.id ?? request.requestId)
        
        // Extract main book ID from the request.bookId (barcode format: "bookID-copyNumber")
        let bookIDComponents = request.bookId.split(separator: "-")
        guard bookIDComponents.count >= 2,
              let mainBookID = bookIDComponents.first else {
            throw NSError(domain: "BookError", code: 400, userInfo: [NSLocalizedDescriptionKey: "Invalid book ID format"])
        }
        
        let bookRef = db.collection("books").document(String(mainBookID))
        let bookCopyRef = bookRef.collection("bookCopies").document(request.bookId)
        
        // Create a batch to handle all updates
        let batch = db.batch()
        
        // Add book issue record
        batch.setData(bookIssueData, forDocument: newIssueRef)
        
        // Update request with approved status
        batch.updateData([
            "status": "approved",
            "approvedByLibrarianId": currentUser.uid
        ], forDocument: requestRef)
        
        // Update book copy status to "checked out"
        batch.updateData(["status": "checked out"], forDocument: bookCopyRef)
        
        // Decrement the availableCopies field in the books collection
        let bookDocument = try await bookRef.getDocument()
        guard let availableCopies = bookDocument.data()?["availableCopies"] as? Int else {
            throw NSError(domain: "LibraryError", code: 400, userInfo: [NSLocalizedDescriptionKey: "Invalid availableCopies field."])
        }

        // Increment bookIssueCount in the books collection
        batch.updateData([
            "bookIssueCount": FieldValue.increment(Int64(1))
        ], forDocument: bookRef)
        
        // Commit all changes
        try await batch.commit()
    }
    
    func rejectBookRequest(_ request: BookRequest) async throws {
        let db = Firestore.firestore()
        
        // Get the librarian ID (current user)
        guard let currentUser = Auth.auth().currentUser else {
            throw NSError(domain: "AuthError", code: 401, userInfo: [NSLocalizedDescriptionKey: "No user is currently logged in"])
        }
        
        // Update request status
        let requestRef = db.collection("bookRequests").document(request.id ?? request.requestId)
        
        // Get book reference to update copy status back to available
        let bookIDComponents = request.bookId.split(separator: "-")
        guard bookIDComponents.count >= 2,
              let mainBookID = bookIDComponents.first else {
            throw NSError(domain: "BookError", code: 400, userInfo: [NSLocalizedDescriptionKey: "Invalid book ID format"])
        }
        
        let bookRef = db.collection("books").document(String(mainBookID))
        let bookCopyRef = bookRef.collection("bookCopies").document(request.bookId)
        
        // Create a batch to handle all updates
        let batch = db.batch()
        
        // Update request with rejected status
        batch.updateData([
            "status": "rejected",
            "approvedByLibrarianId": currentUser.uid
        ], forDocument: requestRef)
        
        // Update book copy status back to available
        batch.updateData(["status": "available"], forDocument: bookCopyRef)
        batch.updateData(["availableCopies": FieldValue.increment(Int64(1))], forDocument: bookRef)
        
        // Commit all changes
        try await batch.commit()
    }
    
    func fetchLibraryDetails(byId id: String) async throws -> String {
        let documentRef = db.collection("libraries").document(id)
        
        do {
            let documentSnapshot = try await documentRef.getDocument()
            
            // Ensure data exists
            guard let data = documentSnapshot.data(),
                  let libraryName = data["name"] as? String else {
                throw NSError(domain: "FirestoreError", code: 404, userInfo: [NSLocalizedDescriptionKey: "Library not found"])
            }
            
            return libraryName
        } catch {
            throw error
        }
    }
    
    // Function to create a reservation
    func createReservation(book: Book, copyID: String) async throws {
        let db = Firestore.firestore()
        
        // Get the current user ID
        guard let userId = Auth.auth().currentUser?.uid else {
            throw NSError(domain: "AuthError", code: 401, userInfo: [NSLocalizedDescriptionKey: "No user is currently logged in"])
        }
        
        // Create a new reservation document
        let reservationRef = db.collection("bookReservations").document()
        let reservationDate = Date()
        
        // Calculate expiration date (e.g., 2 days from now)
        guard let expirationDate = Calendar.current.date(byAdding: .day, value: 2, to: reservationDate) else {
            throw NSError(domain: "DateError", code: 500, userInfo: [NSLocalizedDescriptionKey: "Failed to calculate expiration date"])
        }
        
        // Create reservation data
        let reservationData: [String: Any] = [
            "reservationId": reservationRef.documentID,
            "userId": userId,
            "bookId": copyID,
            "libraryId": book.libraryID,
            "reservationDate": Timestamp(date: reservationDate),
            "expirationDate": Timestamp(date: expirationDate),
            "status": "active"
        ]
        
        // Update book copy status to "reserved"
        let bookRef = db.collection("books").document(book.id!)
        let bookCopyRef = bookRef.collection("bookCopies").document(copyID)
        
        // Create a batch to handle both updates
        let batch = db.batch()
        
        // Add reservation record
        batch.setData(reservationData, forDocument: reservationRef)
        
        // Update book copy status to "reserved"
        batch.updateData(["status": "reserved"], forDocument: bookCopyRef)
        
        // Commit the batch
        try await batch.commit()
    }
    
    // Function to fulfill a reservation (issue the book)
    func fulfillReservation(_ reservation: BookReservation) async throws {
        let db = Firestore.firestore()
        
        // Get the current librarian ID
        guard let librarianId = Auth.auth().currentUser?.uid else {
            throw NSError(domain: "AuthError", code: 401, userInfo: [NSLocalizedDescriptionKey: "No user is currently logged in"])
        }
        
        // Create a new book issue document
        let issueRef = db.collection("bookIssues").document()
        let issueDate = Date()
        
        // Calculate due date (e.g., 1 month from now)
        guard let dueDate = Calendar.current.date(byAdding: .month, value: 1, to: issueDate) else {
            throw NSError(domain: "DateError", code: 500, userInfo: [NSLocalizedDescriptionKey: "Failed to calculate due date"])
        }
        
        // Create book issue data
        let issueData: [String: Any] = [
            "issueID": issueRef.documentID,
            "userId": reservation.userId,
            "bookId": reservation.bookId,
            "libraryId": reservation.libraryId,
            "issuedByLibrarianId": librarianId,
            "issueDate": Timestamp(date: issueDate),
            "dueDate": Timestamp(date: dueDate),
            "isReturned": false,
            "status": "issued"
        ]
        
        // Update reservation status to "fulfilled"
        let reservationRef = db.collection("bookReservations").document(reservation.id ?? reservation.reservationId)
        
        // Update book copy status to "checked out"
        let bookIDComponents = reservation.bookId.split(separator: "-")
        guard bookIDComponents.count >= 2,
              let mainBookID = bookIDComponents.first else {
            throw NSError(domain: "BookError", code: 400, userInfo: [NSLocalizedDescriptionKey: "Invalid book ID format"])
        }
        
        let bookRef = db.collection("books").document(String(mainBookID))
        let bookCopyRef = bookRef.collection("bookCopies").document(reservation.bookId)
        
        // Create a batch to handle all updates
        let batch = db.batch()
        
        // Add book issue record
        batch.setData(issueData, forDocument: issueRef)
        
        // Update reservation status
        batch.updateData(["status": "fulfilled"], forDocument: reservationRef)
        
        // Update book copy status
        batch.updateData(["status": "checked out"], forDocument: bookCopyRef)
        
        // Commit the batch
        try await batch.commit()
    }
    
    // Function to cancel a reservation
    func cancelReservation(_ reservation: BookReservation) async throws {
        let db = Firestore.firestore()
        
        // Update reservation status to "cancelled"
        let reservationRef = db.collection("bookReservations").document(reservation.id ?? reservation.reservationId)
        
        // Update book copy status back to "available"
        let bookIDComponents = reservation.bookId.split(separator: "-")
        guard bookIDComponents.count >= 2,
              let mainBookID = bookIDComponents.first else {
            throw NSError(domain: "BookError", code: 400, userInfo: [NSLocalizedDescriptionKey: "Invalid book ID format"])
        }
        
        let bookRef = db.collection("books").document(String(mainBookID))
        let bookCopyRef = bookRef.collection("bookCopies").document(reservation.bookId)
        
        // Create a batch to handle all updates
        let batch = db.batch()
        
        // Update reservation status
        batch.updateData(["status": "cancelled"], forDocument: reservationRef)
        
        // Update book copy status
        batch.updateData(["status": "available"], forDocument: bookCopyRef)
        
        // Commit the batch
        try await batch.commit()
    }
    
    // Function to fetch active reservations
    func fetchActiveReservations() async throws {
        isLoading = true
        error = nil
        
        do {
            // Get the current logged-in user
            guard let currentUser = Auth.auth().currentUser else {
                throw NSError(domain: "AuthError", code: 401, userInfo: [NSLocalizedDescriptionKey: "No user is currently logged in"])
            }
            
            // Get the librarian's assigned library
            let librarianDoc = try await db.collection("librarians").document(currentUser.uid).getDocument()
            
            guard let librarianData = librarianDoc.data(),
                  let assignedLibraryID = librarianData["libraryID"] as? String else {
                throw NSError(domain: "LibraryError", code: 401, userInfo: [NSLocalizedDescriptionKey: "User is not a librarian or not assigned to any library"])
            }
            
            // Get active reservations for this library
            let reservationsSnapshot = try await db.collection("bookReservations")
                .whereField("libraryId", isEqualTo: assignedLibraryID)
                .whereField("status", isEqualTo: "active")
                .getDocuments()
            
            // Process the reservations
            let activeReservations = reservationsSnapshot.documents.compactMap { document -> BookReservation? in
                do {
                    return try document.data(as: BookReservation.self)
                } catch {
                    print("Error decoding book reservation: \(error)")
                    return nil
                }
            }
            
            await MainActor.run {
                self.activeReservations = activeReservations
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
    
    func getFirstAvailableCopyID(for book: Book) async throws -> String? {
        let db = Firestore.firestore()
        
        // Reference the book's copies subcollection
        let bookRef = db.collection("books").document(book.id!)
        let copiesRef = bookRef.collection("bookCopies")
        
        // Query for the first available copy
        let query = copiesRef
            .whereField("status", isEqualTo: "available")
            .limit(to: 1) // Limit to 1 result since we only need the first available copy
        
        do {
            let snapshot = try await query.getDocuments()
            
            // Check if there's an available copy
            if let document = snapshot.documents.first {
                // Return the barcode (document ID) of the available copy
                return document.documentID
            } else {
                // No available copies found
                return nil
            }
        } catch {
            print("Error fetching available copies: \(error.localizedDescription)")
            throw error
        }
    }
    
    func returnBook(bookCopyID: String) async throws {
        let db = Firestore.firestore()
        
        // Get the current librarian ID
        guard let currentUser = Auth.auth().currentUser else {
            throw NSError(domain: "AuthError", code: 401, userInfo: [NSLocalizedDescriptionKey: "No user is currently logged in"])
        }
        
        // Get the book issue document
        let issuesSnapshot = try await db.collection("bookIssues")
            .whereField("bookId", isEqualTo: bookCopyID)
            .getDocuments()
        
        guard let issueDocument = issuesSnapshot.documents.first else {
            throw NSError(domain: "LibraryError", code: 404, userInfo: [NSLocalizedDescriptionKey: "No book issue found for this copy."])
        }
        
        let issueData = issueDocument.data()
        let bookId = issueData["bookId"] as? String ?? ""
        let userId = issueData["userId"] as? String ?? ""
        
        // Extract main book ID from the copy ID
        let bookIDComponents = bookId.split(separator: "-")
        guard bookIDComponents.count >= 2,
              let mainBookID = bookIDComponents.first else {
            throw NSError(domain: "BookError", code: 400, userInfo: [NSLocalizedDescriptionKey: "Invalid book ID format"])
        }
        
        let bookRef = db.collection("books").document(String(mainBookID))
        let bookCopyRef = bookRef.collection("bookCopies").document(bookId)
        
        // Create a batch to handle all updates
        let batch = db.batch()
        
        // Update book issue status to returned
        batch.updateData([
            "isReturned": true,
            "returnDate": Timestamp(date: Date())
        ], forDocument: issueDocument.reference)
        
        // Update book copy status to available
        batch.updateData(["status": "available"], forDocument: bookCopyRef)
        
        // Increment availableCopies in the books collection
        batch.updateData(["availableCopies": FieldValue.increment(Int64(1))], forDocument: bookRef)
        
        // Commit all changes
        try await batch.commit()
    }
    
    
    func addToWishlist(book: Book) async throws {
       guard let userId = Auth.auth().currentUser?.uid else {
           throw NSError(domain: "AuthError", code: 401, userInfo: [NSLocalizedDescriptionKey: "No user is currently logged in"])
       }

       let db = Firestore.firestore()
       let wishlistRef = db.collection("members").document(userId).collection("wishlist").document(book.id!)

       let wishlistData: [String: Any] = [
           "addedOn": Timestamp(date: Date())
       ]

       try await wishlistRef.setData(wishlistData)
   }

   func markAsCurrentlyReading(book: Book) async throws {
       guard let userId = Auth.auth().currentUser?.uid else {
           throw NSError(domain: "AuthError", code: 401, userInfo: [NSLocalizedDescriptionKey: "No user is currently logged in"])
       }

       let db = Firestore.firestore()
       let currentlyReadingRef = db.collection("members").document(userId).collection("currentlyReading").document(book.id!)

       let currentlyReadingData: [String: Any] = [
           "addedOn": Timestamp(date: Date()),
           "progress": 0 // Initial progress
       ]

       try await currentlyReadingRef.setData(currentlyReadingData)
   }

   func markAsCompleted(book: Book) async throws {
       guard let userId = Auth.auth().currentUser?.uid else {
           throw NSError(domain: "AuthError", code: 401, userInfo: [NSLocalizedDescriptionKey: "No user is currently logged in"])
       }

       let db = Firestore.firestore()
       let alreadyReadRef = db.collection("members").document(userId).collection("alreadyRead").document(book.id!)

       let alreadyReadData: [String: Any] = [
           "addedOn": Timestamp(date: Date()),
           "rating": 0 // Initial rating, can be updated later
       ]

       try await alreadyReadRef.setData(alreadyReadData)
    }
    
    // Fetch books from the user's wishlist
    func fetchWishlistBooks() async throws -> [Book] {
        guard let userId = Auth.auth().currentUser?.uid else {
            throw NSError(domain: "AuthError", code: 401, userInfo: [NSLocalizedDescriptionKey: "No user is currently logged in"])
        }

        let wishlistRef = db.collection("members").document(userId).collection("wishlist")
        let snapshot = try await wishlistRef.getDocuments()

        var books: [Book] = []
        for document in snapshot.documents {
            let bookId = document.documentID
            let bookRef = db.collection("books").document(bookId)
            let bookSnapshot = try await bookRef.getDocument()
            if let book = try? bookSnapshot.data(as: Book.self) {
                books.append(book)
            }
        }

        return books
     }

    // Fetch books from the user's currentlyReading collection
    func fetchCurrentlyReadingBooks() async throws -> [Book] {
        guard let userId = Auth.auth().currentUser?.uid else {
            throw NSError(domain: "AuthError", code: 401, userInfo: [NSLocalizedDescriptionKey: "No user is currently logged in"])
        }

        let currentlyReadingRef = db.collection("members").document(userId).collection("currentlyReading")
        let snapshot = try await currentlyReadingRef.getDocuments()

        var books: [Book] = []
        for document in snapshot.documents {
            let bookId = document.documentID
            let bookRef = db.collection("books").document(bookId)
            let bookSnapshot = try await bookRef.getDocument()
            if let book = try? bookSnapshot.data(as: Book.self) {
                books.append(book)
            }
        }

        return books
     }

    // Fetch books from the user's alreadyRead collection
    func fetchAlreadyReadBooks() async throws -> [Book] {
        guard let userId = Auth.auth().currentUser?.uid else {
            throw NSError(domain: "AuthError", code: 401, userInfo: [NSLocalizedDescriptionKey: "No user is currently logged in"])
        }

        let alreadyReadRef = db.collection("members").document(userId).collection("alreadyRead")
        let snapshot = try await alreadyReadRef.getDocuments()

        var books: [Book] = []
        for document in snapshot.documents {
            let bookId = document.documentID
            let bookRef = db.collection("books").document(bookId)
            let bookSnapshot = try await bookRef.getDocument()
            if let book = try? bookSnapshot.data(as: Book.self) {
                books.append(book)
            }
        }

        return books
     }

    // Fetch all books (for reserved and other sections)
    func fetchAllBooks() async throws -> [Book] {
        let snapshot = try await db.collection("books").getDocuments()
        return snapshot.documents.compactMap { document in
            try? document.data(as: Book.self)
        }
     }
}


