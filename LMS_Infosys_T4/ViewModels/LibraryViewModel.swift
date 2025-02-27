import Foundation
import FirebaseFirestore
import FirebaseAuth

struct BookIssue: Identifiable, Codable {
    let id: String
    let userId: String
    let bookId: String
    let issueDate: Date
    let dueDate: Date
    let isReturned: Bool
}

struct Fine: Identifiable, Codable {
    let id: String
    let userId: String
    let bookId: String
    let issueId: String
    let fineAmount: Double
    let imposedDate: Date
    let isPaid: Bool
}

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
            let newBookRef = db.collection("books").document()
            var newBook = book
            newBook.id = newBookRef.documentID
            let bookData = try Firestore.Encoder().encode(newBook)
            let libraryRef = db.collection("libraries").document(book.libraryID)
            let batch = db.batch()
            batch.setData(bookData, forDocument: newBookRef)
            
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
            
            batch.updateData(["totalBooks": FieldValue.increment(Int64(book.quantity))], forDocument: libraryRef)
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
    
    func checkIfBookExists(isbn: String) async throws -> Bool {
        do {
            let snapshot = try await db.collection("books")
                .whereField("isbn", isEqualTo: isbn)
                .limit(to: 1)
                .getDocuments()
            return !snapshot.documents.isEmpty
        } catch {
            throw error
        }
    }
    
    func updateBookQuantity(bookID: String, newQuantity: Int) async throws {
        let db = Firestore.firestore()
        let bookRef = db.collection("books").document(bookID)
        let bookDocument = try await bookRef.getDocument()
        
        guard let bookData = bookDocument.data(),
              let currentQuantity = bookData["quantity"] as? Int,
              let libraryID = bookData["libraryID"] as? String else {
            throw NSError(domain: "LibraryError", code: 400, userInfo: [NSLocalizedDescriptionKey: "Invalid book data."])
        }
        
        let quantityDifference = newQuantity - currentQuantity
        try await bookRef.updateData(["quantity": newQuantity])
        
        if quantityDifference > 0 {
            for copyNumber in (currentQuantity + 1)...newQuantity {
                let barcode = generateBarcode(bookID: bookID, copyNumber: copyNumber)
                let copyRef = bookRef.collection("bookCopies").document(barcode)
                let copyData: [String: Any] = [
                    "barcode": barcode,
                    "status": "available",
                    "libraryID": libraryID
                ]
                try await copyRef.setData(copyData)
            }
        }
    }
    
    func fetchPendingBookRequests() async throws {
        await MainActor.run {
            isLoading = true
            error = nil
        }
        
        do {
            guard let currentUser = Auth.auth().currentUser else {
                throw NSError(domain: "AuthError", code: 401, userInfo: [NSLocalizedDescriptionKey: "No user is currently logged in"])
            }
            
            let librarianDoc = try await db.collection("librarians").document(currentUser.uid).getDocument()
            guard let librarianData = librarianDoc.data(),
                  let assignedLibraryID = librarianData["libraryID"] as? String else {
                throw NSError(domain: "LibraryError", code: 401, userInfo: [NSLocalizedDescriptionKey: "User is not a librarian or not assigned to any library"])
            }
            
            let requestsSnapshot = try await db.collection("bookRequests")
                .whereField("libraryuId", isEqualTo: assignedLibraryID)
                .whereField("status", isEqualTo: "pending")
                .getDocuments()
            
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
            guard let currentUser = Auth.auth().currentUser else {
                throw NSError(domain: "AuthError", code: 401, userInfo: [NSLocalizedDescriptionKey: "No user is currently logged in"])
            }
            
            let requestsSnapshot = try await db.collection("bookRequests")
                .whereField("userId", isEqualTo: currentUser.uid)
                .getDocuments()
            
            let userRequests = requestsSnapshot.documents.compactMap { document -> BookRequest? in
                do {
                    return try document.data(as: BookRequest.self)
                } catch {
                    print("Error decoding book request: \(error)")
                    return nil
                }
            }
            
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
        let bookCopyRef = bookRef.collection("bookCopies").document(copyID)
        let bookCopySnapshot = try await bookCopyRef.getDocument()
        
        guard let bookCopyData = bookCopySnapshot.data(),
              let status = bookCopyData["status"] as? String, status == "available" else {
            throw NSError(domain: "LibraryError", code: 400, userInfo: [NSLocalizedDescriptionKey: "The specified book copy is not available."])
        }
        
        let bookRequestRef = db.collection("bookRequests").document()
        let requestDate = Date()
        let requestData: [String: Any] = [
            "requestId": bookRequestRef.documentID,
            "userId": Auth.auth().currentUser!.uid,
            "bookId": copyID,
            "libraryuId": book.libraryID,
            "approvedByLibrarianId": "",
            "requestDate": Timestamp(date: requestDate),
            "status": "pending"
        ]
        
        let batch = db.batch()
        batch.updateData(["status": "pending"], forDocument: bookCopyRef)
        batch.updateData(["availableCopies": FieldValue.increment(Int64(-1))], forDocument: bookRef)
        batch.setData(requestData, forDocument: bookRequestRef)
        try await batch.commit()
    }
    
    private func generateBarcode(bookID: String, copyNumber: Int) -> String {
        return "\(bookID)-\(String(format: "%03d", copyNumber))"
    }
    
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
        let db = Firestore.firestore()
        guard let currentUser = Auth.auth().currentUser else {
            throw NSError(domain: "AuthError", code: 401, userInfo: [NSLocalizedDescriptionKey: "No user is currently logged in"])
        }
        
        let libraryRef = db.collection("libraries").document(request.libraryuId)
        let libraryDocument = try await libraryRef.getDocument()
        guard let libraryData = libraryDocument.data(),
              let loanDuration = libraryData["loanDuration"] as? Int else {
            throw NSError(domain: "LibraryError", code: 400, userInfo: [NSLocalizedDescriptionKey: "Invalid library data or loan duration not found."])
        }
        
        let issueDate = Date()
        guard let dueDate = Calendar.current.date(byAdding: .day, value: loanDuration, to: issueDate) else {
            throw NSError(domain: "DateError", code: 500, userInfo: [NSLocalizedDescriptionKey: "Failed to calculate due date"])
        }
        
        let calendar = Calendar.current
        let dueDateWithoutTime = calendar.startOfDay(for: dueDate)
        let bookIssueData: [String: Any] = [
            "issueID": UUID().uuidString,
            "requestID": request.requestId,
            "userId": request.userId,
            "bookId": request.bookId,
            "libraryId": request.libraryuId,
            "issuedByLibrarianId": currentUser.uid,
            "issueDate": Timestamp(date: issueDate),
            "dueDate": Timestamp(date: dueDateWithoutTime),
            "returnDate": NSNull(),
            "isReturned": false,
            "fineAmount": 0,
            "status": "issued"
        ]
        
        let requestRef = db.collection("bookRequests").document(request.id ?? request.requestId)
        let bookIDComponents = request.bookId.split(separator: "-")
        guard bookIDComponents.count >= 2,
              let mainBookID = bookIDComponents.first else {
            throw NSError(domain: "BookError", code: 400, userInfo: [NSLocalizedDescriptionKey: "Invalid book ID format"])
        }
        
        let bookRef = db.collection("books").document(String(mainBookID))
        let bookCopyRef = bookRef.collection("bookCopies").document(request.bookId)
        let batch = db.batch()
        
        batch.setData(bookIssueData, forDocument: db.collection("bookIssues").document())
        batch.updateData(["status": "approved", "approvedByLibrarianId": currentUser.uid], forDocument: requestRef)
        batch.updateData(["status": "checked out"], forDocument: bookCopyRef)
        
        let bookDocument = try await bookRef.getDocument()
        guard bookDocument.data()?["availableCopies"] as? Int != nil else {
            throw NSError(domain: "LibraryError", code: 400, userInfo: [NSLocalizedDescriptionKey: "Invalid availableCopies field."])
        }
        
        batch.updateData(["bookIssueCount": FieldValue.increment(Int64(1))], forDocument: bookRef)
        try await batch.commit()
    }
    
    func rejectBookRequest(_ request: BookRequest) async throws {
        let db = Firestore.firestore()
        guard let currentUser = Auth.auth().currentUser else {
            throw NSError(domain: "AuthError", code: 401, userInfo: [NSLocalizedDescriptionKey: "No user is currently logged in"])
        }
        
        let requestRef = db.collection("bookRequests").document(request.id ?? request.requestId)
        let bookIDComponents = request.bookId.split(separator: "-")
        guard bookIDComponents.count >= 2,
              let mainBookID = bookIDComponents.first else {
            throw NSError(domain: "BookError", code: 400, userInfo: [NSLocalizedDescriptionKey: "Invalid book ID format"])
        }
        
        let bookRef = db.collection("books").document(String(mainBookID))
        let bookCopyRef = bookRef.collection("bookCopies").document(request.bookId)
        let batch = db.batch()
        
        batch.updateData(["status": "rejected", "approvedByLibrarianId": currentUser.uid], forDocument: requestRef)
        batch.updateData(["status": "available"], forDocument: bookCopyRef)
        batch.updateData(["availableCopies": FieldValue.increment(Int64(1))], forDocument: bookRef)
        try await batch.commit()
    }
    
    func fetchLibraryDetails(byId id: String) async throws -> String {
        let documentRef = db.collection("libraries").document(id)
        let documentSnapshot = try await documentRef.getDocument()
        guard let data = documentSnapshot.data(),
              let libraryName = data["name"] as? String else {
            throw NSError(domain: "FirestoreError", code: 404, userInfo: [NSLocalizedDescriptionKey: "Library not found"])
        }
        return libraryName
    }
    
    func createReservation(book: Book, copyID: String) async throws {
        let db = Firestore.firestore()
        guard let userId = Auth.auth().currentUser?.uid else {
            throw NSError(domain: "AuthError", code: 401, userInfo: [NSLocalizedDescriptionKey: "No user is currently logged in"])
        }
        
        let reservationRef = db.collection("bookReservations").document()
        let reservationDate = Date()
        guard let expirationDate = Calendar.current.date(byAdding: .day, value: 2, to: reservationDate) else {
            throw NSError(domain: "DateError", code: 500, userInfo: [NSLocalizedDescriptionKey: "Failed to calculate expiration date"])
        }
        
        let reservationData: [String: Any] = [
            "reservationId": reservationRef.documentID,
            "userId": userId,
            "bookId": copyID,
            "libraryId": book.libraryID,
            "reservationDate": Timestamp(date: reservationDate),
            "expirationDate": Timestamp(date: expirationDate),
            "status": "active"
        ]
        
        let bookRef = db.collection("books").document(book.id!)
        let bookCopyRef = bookRef.collection("bookCopies").document(copyID)
        let batch = db.batch()
        
        batch.setData(reservationData, forDocument: reservationRef)
        batch.updateData(["status": "reserved"], forDocument: bookCopyRef)
        try await batch.commit()
    }
    
    func fulfillReservation(_ reservation: BookReservation) async throws {
        let db = Firestore.firestore()
        guard let librarianId = Auth.auth().currentUser?.uid else {
            throw NSError(domain: "AuthError", code: 401, userInfo: [NSLocalizedDescriptionKey: "No user is currently logged in"])
        }
        
        let issueRef = db.collection("bookIssues").document()
        let issueDate = Date()
        guard let dueDate = Calendar.current.date(byAdding: .month, value: 1, to: issueDate) else {
            throw NSError(domain: "DateError", code: 500, userInfo: [NSLocalizedDescriptionKey: "Failed to calculate due date"])
        }
        
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
        
        let reservationRef = db.collection("bookReservations").document(reservation.id ?? reservation.reservationId)
        let bookIDComponents = reservation.bookId.split(separator: "-")
        guard bookIDComponents.count >= 2,
              let mainBookID = bookIDComponents.first else {
            throw NSError(domain: "BookError", code: 400, userInfo: [NSLocalizedDescriptionKey: "Invalid book ID format"])
        }
        
        let bookRef = db.collection("books").document(String(mainBookID))
        let bookCopyRef = bookRef.collection("bookCopies").document(reservation.bookId)
        let batch = db.batch()
        
        batch.setData(issueData, forDocument: issueRef)
        batch.updateData(["status": "fulfilled"], forDocument: reservationRef)
        batch.updateData(["status": "checked out"], forDocument: bookCopyRef)
        try await batch.commit()
    }
    
    func cancelReservation(_ reservation: BookReservation) async throws {
        let db = Firestore.firestore()
        let reservationRef = db.collection("bookReservations").document(reservation.id ?? reservation.reservationId)
        let bookIDComponents = reservation.bookId.split(separator: "-")
        guard bookIDComponents.count >= 2,
              let mainBookID = bookIDComponents.first else {
            throw NSError(domain: "BookError", code: 400, userInfo: [NSLocalizedDescriptionKey: "Invalid book ID format"])
        }
        
        let bookRef = db.collection("books").document(String(mainBookID))
        let bookCopyRef = bookRef.collection("bookCopies").document(reservation.bookId)
        let batch = db.batch()
        
        batch.updateData(["status": "cancelled"], forDocument: reservationRef)
        batch.updateData(["status": "available"], forDocument: bookCopyRef)
        try await batch.commit()
    }
    
    func fetchActiveReservations() async throws {
        // Fixed: Wrap initial @Published updates in MainActor.run
        await MainActor.run {
            isLoading = true
            error = nil
        }
        
        do {
            guard let currentUser = Auth.auth().currentUser else {
                throw NSError(domain: "AuthError", code: 401, userInfo: [NSLocalizedDescriptionKey: "No user is currently logged in"])
            }
            
            let librarianDoc = try await db.collection("librarians").document(currentUser.uid).getDocument()
            guard let librarianData = librarianDoc.data(),
                  let assignedLibraryID = librarianData["libraryID"] as? String else {
                throw NSError(domain: "LibraryError", code: 401, userInfo: [NSLocalizedDescriptionKey: "User is not a librarian or not assigned to any library"])
            }
            
            let reservationsSnapshot = try await db.collection("bookReservations")
                .whereField("libraryId", isEqualTo: assignedLibraryID)
                .whereField("status", isEqualTo: "active")
                .getDocuments()
            
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
        let bookRef = db.collection("books").document(book.id!)
        let copiesRef = bookRef.collection("bookCopies")
        let query = copiesRef.whereField("status", isEqualTo: "available").limit(to: 1)
        
        do {
            let snapshot = try await query.getDocuments()
            return snapshot.documents.first?.documentID
        } catch {
            print("Error fetching available copies: \(error.localizedDescription)")
            throw error
        }
    }
    
    func returnBook(bookCopyID: String) async throws {
        let db = Firestore.firestore()
        guard let currentUser = Auth.auth().currentUser else {
            throw NSError(domain: "AuthError", code: 401, userInfo: [NSLocalizedDescriptionKey: "No user is currently logged in"])
        }
        
        let librarianDoc = try await db.collection("librarians").document(currentUser.uid).getDocument()
        guard let librarianData = librarianDoc.data(),
              let libraryID = librarianData["libraryID"] as? String else {
            throw NSError(domain: "LibraryError", code: 401, userInfo: [NSLocalizedDescriptionKey: "User is not a librarian or not assigned to any library"])
        }
        
        let libraryRef = db.collection("libraries").document(libraryID)
        let libraryDocument = try await libraryRef.getDocument()
        guard let libraryData = libraryDocument.data(),
              let fineAmountPerDay = libraryData["finePerDay"] as? Double else {
            throw NSError(domain: "LibraryError", code: 400, userInfo: [NSLocalizedDescriptionKey: "Invalid library data or fine amount not found."])
        }
        
        let issuesSnapshot = try await db.collection("bookIssues")
            .whereField("bookId", isEqualTo: bookCopyID)
            .getDocuments()
        
        guard let issueDocument = issuesSnapshot.documents.first else {
            throw NSError(domain: "LibraryError", code: 404, userInfo: [NSLocalizedDescriptionKey: "No book issue found for this copy."])
        }
        
        let issueData = issueDocument.data()
        let bookId = issueData["bookId"] as? String ?? ""
        let userId = issueData["userId"] as? String ?? ""
        let dueDate = (issueData["dueDate"] as? Timestamp)?.dateValue() ?? Date()
        let returnDate = Date()
        
        var fineAmount: Double = 0.0
        if returnDate > dueDate {
            let calendar = Calendar.current
            let components = calendar.dateComponents([.day], from: dueDate, to: returnDate)
            let daysOverdue = components.day ?? 0
            fineAmount = Double(daysOverdue) * fineAmountPerDay
        }
        
        let bookIDComponents = bookId.split(separator: "-")
        guard bookIDComponents.count >= 2,
              let mainBookID = bookIDComponents.first else {
            throw NSError(domain: "BookError", code: 400, userInfo: [NSLocalizedDescriptionKey: "Invalid book ID format"])
        }
        
        let bookRef = db.collection("books").document(String(mainBookID))
        let bookCopyRef = bookRef.collection("bookCopies").document(bookId)
        let batch = db.batch()
        
        batch.updateData(["isReturned": true, "returnDate": Timestamp(date: returnDate)], forDocument: issueDocument.reference)
        batch.updateData(["status": "available"], forDocument: bookCopyRef)
        batch.updateData(["availableCopies": FieldValue.increment(Int64(1))], forDocument: bookRef)
        
        if fineAmount > 0 {
            let fineRef = db.collection("fines").document()
            let fineData: [String: Any] = [
                "id": fineRef.documentID,
                "userId": userId,
                "bookId": bookId,
                "issueId": issueDocument.documentID,
                "fineAmount": fineAmount,
                "imposedDate": Timestamp(date: returnDate),
                "isPaid": false
            ]
            batch.setData(fineData, forDocument: fineRef)
        }
        
        try await batch.commit()
    }
    
    func fetchFines(for userId: String? = nil) async throws -> [Fine] {
        let db = Firestore.firestore()
        var query: Query = db.collection("fines")
        if let userId = userId {
            query = query.whereField("userId", isEqualTo: userId)
        }
        
        let snapshot = try await query.getDocuments()
        return snapshot.documents.compactMap { document in
            try? document.data(as: Fine.self)
        }
    }
    
    func markFineAsPaid(fineId: String) async throws {
        let db = Firestore.firestore()
        let fineRef = db.collection("fines").document(fineId)
        try await fineRef.updateData(["isPaid": true])
    }
    
    func fetchReturnedBooks() async throws -> [ReturnBookHistoryView.ReturnedBookInfo] {
        let db = Firestore.firestore()
        guard let currentUser = Auth.auth().currentUser else {
            throw NSError(domain: "AuthError", code: 401, userInfo: [NSLocalizedDescriptionKey: "No user is currently logged in"])
        }
        
        let librarianDoc = try await db.collection("librarians").document(currentUser.uid).getDocument()
        guard let librarianData = librarianDoc.data(),
              let libraryID = librarianData["libraryID"] as? String else {
            throw NSError(domain: "LibraryError", code: 401, userInfo: [NSLocalizedDescriptionKey: "User is not a librarian or not assigned to any library"])
        }
        
        let issuesSnapshot = try await db.collection("bookIssues")
            .whereField("libraryId", isEqualTo: libraryID)
            .whereField("isReturned", isEqualTo: true)
            .getDocuments()
        
        var returnedBooks: [ReturnBookHistoryView.ReturnedBookInfo] = []
        for document in issuesSnapshot.documents {
            let data = document.data()
            guard let bookId = data["bookId"] as? String,
                  let userId = data["userId"] as? String,
                  let issueDateTimestamp = data["issueDate"] as? Timestamp,
                  let returnDateTimestamp = data["returnDate"] as? Timestamp else {
                continue
            }
            
            let components = bookId.components(separatedBy: "-")
            guard let mainBookID = components.first else { continue }
            
            let bookDoc = try await db.collection("books").document(mainBookID).getDocument()
            guard let bookData = bookDoc.data() else { continue }
            
            let title = bookData["title"] as? String ?? "Unknown Title"
            let author = bookData["author"] as? String ?? "Unknown Author"
            let isbn = bookData["isbn"] as? String ?? "Unknown ISBN"
            let coverImage = bookData["coverImage"] as? String ?? ""
            
            let userDoc = try await db.collection("members").document(userId).getDocument()
            guard let userData = userDoc.data() else { continue }
            
            let userName = userData["name"] as? String ?? "Unknown User"
            let userEmail = userData["email"] as? String ?? ""
            
            let returnedBook = ReturnBookHistoryView.ReturnedBookInfo(
                id: document.documentID,
                title: title,
                author: author,
                isbn: isbn,
                bookId: bookId,
                userId: userId,
                userName: userName,
                userEmail: userEmail,
                issueDate: issueDateTimestamp.dateValue(),
                returnDate: returnDateTimestamp.dateValue(),
                coverImage: coverImage
            )
            returnedBooks.append(returnedBook)
        }
        return returnedBooks
    }
    
    func addToWishlist(book: Book) async throws {
        guard let userId = Auth.auth().currentUser?.uid else {
            throw NSError(domain: "AuthError", code: 401, userInfo: [NSLocalizedDescriptionKey: "No user is currently logged in"])
        }
        
        let db = Firestore.firestore()
        let wishlistRef = db.collection("members").document(userId).collection("wishlist").document(book.id!)
        let wishlistData: [String: Any] = ["addedOn": Timestamp(date: Date())]
        try await wishlistRef.setData(wishlistData)
    }
    
    func markAsCurrentlyReading(book: Book) async throws {
        guard let userId = Auth.auth().currentUser?.uid else {
            throw NSError(domain: "AuthError", code: 401, userInfo: [NSLocalizedDescriptionKey: "No user is currently logged in"])
        }
        
        let db = Firestore.firestore()
        let currentlyReadingRef = db.collection("members").document(userId).collection("currentlyReading").document(book.id!)
        let currentlyReadingData: [String: Any] = ["addedOn": Timestamp(date: Date()), "progress": 0]
        try await currentlyReadingRef.setData(currentlyReadingData)
    }
    
    func markAsCompleted(book: Book) async throws {
        guard let userId = Auth.auth().currentUser?.uid else {
            throw NSError(domain: "AuthError", code: 401, userInfo: [NSLocalizedDescriptionKey: "No user is currently logged in"])
        }
        
        let db = Firestore.firestore()
        let alreadyReadRef = db.collection("members").document(userId).collection("alreadyRead").document(book.id!)
        let alreadyReadData: [String: Any] = ["addedOn": Timestamp(date: Date()), "rating": 0]
        try await alreadyReadRef.setData(alreadyReadData)
    }
    
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
    
    func fetchAllBooks() async throws -> [Book] {
        let snapshot = try await db.collection("books").getDocuments()
        return snapshot.documents.compactMap { document in
            try? document.data(as: Book.self)
        }
    }
    
    func fetchIssuedBooks(for bookID: String) async throws -> [BookIssue] {
        let db = Firestore.firestore()
        let issuesSnapshot = try await db.collection("bookIssues")
            .whereField("bookId", isEqualTo: bookID)
            .getDocuments()
        return issuesSnapshot.documents.compactMap { document in
            try? document.data(as: BookIssue.self)
        }
    }
}
