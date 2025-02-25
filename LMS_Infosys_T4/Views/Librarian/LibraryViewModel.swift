import Foundation
import FirebaseFirestore
import FirebaseAuth

// Book model matching the ER diagram
struct Book: Identifiable, Codable {
    @DocumentID var id: String?  // This will store the Firestore document ID
    let libraryID: String
    let addedByLibrarian: String
    let title: String
    let author: String
    let isbn: String
    var availabilityStatus: AvailabilityStatus
    let publishYear: Int
    let genre: String
    let coverImage: String?
    let description: String
//    let edition: String?
    let quantity: Int
    let availableCopies: Int
    
    // Add this function to decode base64 to UIImage
    func getCoverImage() -> UIImage? {
        guard let base64String = coverImage,
              let imageData = Data(base64Encoded: base64String) else {
            return nil
        }
        return UIImage(data: imageData)
    }
    
//    func getCoverImage(byData base64String: String) -> UIImage? {
//        guard let imageData = Data(base64Encoded: base64String) else {
//            return nil
//        }
//        return UIImage(data: imageData)
//    }

    enum CodingKeys: String, CodingKey {
        case id
        case libraryID
        case addedByLibrarian
        case title
        case author
        case isbn
        case availabilityStatus
        case publishYear
        case genre
        case coverImage
        case description
//        case edition
        case quantity
        case availableCopies
    }
}

// Enum for availabilityStatus
enum AvailabilityStatus: Int, Codable {
    case available = 1
    case checkedOut = 2
    case reserved = 3
    case underMaintenance = 4
    
    var description: String {
        switch self {
        case .available: return "Available"
        case .checkedOut: return "Checked Out"
        case .reserved: return "Reserved"
        case .underMaintenance: return "Under Maintenance"
        }
    }
}


// Add this BookRequest model
struct BookRequest: Identifiable, Codable {
    @DocumentID var id: String?
    let requestId: String
    let userId: String
    let bookId: String
    let libraryuId: String
    let approvedByLibrarianId: String
    let requestDate: Date
    let status: String
    
    enum CodingKeys: String, CodingKey {
        case id
        case requestId
        case userId
        case bookId
        case libraryuId
        case approvedByLibrarianId
        case requestDate
        case status
    }
}

class LibraryViewModel: ObservableObject {
    @Published var books: [Book] = []
    @Published var isLoading = false
    @Published var error: String?
    @Published var pendingRequests: [BookRequest] = []

    private let db = Firestore.firestore()
    
    func addBook(_ book: Book) async throws {
        isLoading = true
        error = nil
        
        do {
            // Create a new document reference to get the auto-generated ID
            let newBookRef = db.collection("books").document()
            
            // Create the book with the document ID
            var newBook = book
            newBook.id = newBookRef.documentID
            
            // Convert book to dictionary
            let bookData = try Firestore.Encoder().encode(newBook)
            
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
        isLoading = true
        error = nil
        
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
    
    func requestBook(book: Book, copyID: String) async throws {
        let db = Firestore.firestore()
        let bookRef = db.collection("books").document(book.id!)
//        let libraryRef = db.collection("libraries").document(book.libraryID)
        
//        // Fetch fineAmount from the library document
//        let librarySnapshot = try await libraryRef.getDocument()
//        guard let libraryData = librarySnapshot.data(),
//              let fineAmount = libraryData["finePerDay"] as? Double else {
//            throw NSError(domain: "LibraryError", code: 500, userInfo: [NSLocalizedDescriptionKey: "Failed to fetch fine amount."])
//        }
        
        // Reference the specified book copy by copyID
        let bookCopyRef = bookRef.collection("bookCopies").document(copyID)
        let bookCopySnapshot = try await bookCopyRef.getDocument()
        
        guard let bookCopyData = bookCopySnapshot.data(),
              let status = bookCopyData["status"] as? String, status == "available" else {
            throw NSError(domain: "LibraryError", code: 400, userInfo: [NSLocalizedDescriptionKey: "The specified book copy is not available."])
        }

        let bookIssueRef = db.collection("bookRequests")
        
        // Check if this book copy is already issued
        let issuedBooksSnapshot = try await bookIssueRef
            .whereField("bookId", isEqualTo: copyID)
            .whereField("isReturned", isEqualTo: false)
            .getDocuments()
        
        if !issuedBooksSnapshot.documents.isEmpty {
            throw NSError(domain: "LibraryError", code: 400, userInfo: [NSLocalizedDescriptionKey: "This book copy is already issued."])
        }

        let newIssueRef = bookIssueRef.document()
        let issueDate = Date()

        // Calculate due date (issueDate + 2 months) and initial return date (issueDate - 1 day)
        guard let dueDate = Calendar.current.date(byAdding: .month, value: 1, to: issueDate),
              let initialReturnDate = Calendar.current.date(byAdding: .day, value: -1, to: issueDate) else {
            throw NSError(domain: "DateError", code: 500, userInfo: [NSLocalizedDescriptionKey: "Failed to calculate due or return date."])
        }
        
        // Prepare issue data including fineAmount
        let issueData: [String: Any] = [
            "requestId": newIssueRef.documentID,
            "userId": Auth.auth().currentUser!.uid,
            "bookId": copyID, // Use the specified copyID
            "libraryuId": book.libraryID,
            "approvedByLibrarianId": "",
            "requestDate": Timestamp(date: issueDate),
//            "dueDate": Timestamp(date: dueDate),
//            "returnDate": Timestamp(date: initialReturnDate), // Initially issueDate - 1 day
//            "isReturned": false,
            "status": "pending"
//            "fineAmount": fineAmount // Added fine amount from library document
        ]
        
        // Perform Firestore batch operation
        let batch = db.batch()
        
        // Update book copy status to "checked out"
        batch.updateData(["status": "checked out"], forDocument: bookCopyRef)
        
        // Add book issue record
        batch.setData(issueData, forDocument: newIssueRef)
        
        // Commit batch
        try await batch.commit()
        
//        print("Book issued successfully. Due date: \(dueDate), Initial return date: \(initialReturnDate), Fine per day: \(fineAmount)")
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
                "issueID": newIssueRef.documentID,      // Unique ID for issued book
                "requestID": request.requestId,          // Link to original request
                "userId": request.userId,                // ID of the user who borrowed the book
                "bookId": request.bookId,                // Specific book copy issued
                "libraryId": request.libraryuId,         // The library issuing the book
                "issuedByLibrarianId": currentUser.uid,  // ID of approving librarian
                "issueDate": Timestamp(date: issueDate), // Date book was issued
                "dueDate": Timestamp(date: dueDate),     // Date the book must be returned
                "returnDate": NSNull(),                  // Will be updated when returned
                "isReturned": false,                     // Marks if the book has been returned
                "fineAmount": 0,                         // Default fine, updated if late
                "status": "issued"                       // Could be: "issued", "returned", "overdue"
            ]
            
            // Update request status
            let requestRef = db.collection("bookRequests").document(request.id ?? request.requestId)
            
            // Get book reference to update copy status
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
            
            // Update book copy status
            batch.updateData([
                "status": "checked out"
            ], forDocument: bookCopyRef)
            
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
            batch.updateData([
                "status": "available"
            ], forDocument: bookCopyRef)
            
            // Commit all changes
            try await batch.commit()
        }
}
