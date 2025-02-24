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

class LibraryViewModel: ObservableObject {
    @Published var books: [Book] = []
    @Published var isLoading = false
    @Published var error: String?
    
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
                let copyRef = newBookRef.collection("bookCopies").document()
                let barcode = generateBarcode(bookID: newBookRef.documentID, copyNumber: copyNumber)
                
                let copyData: [String: Any] = [
                    "barcode": barcode,
                    "status": "available",
                    "libraryUID": book.libraryID
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
    
//    func issueBook(book: Book) async throws {
//        let db = Firestore.firestore()
//        let bookRef = db.collection("books").document(book.id!)
//        let fineAmount = db.collection("libraries").document(book.libraryID)
//        
//        // Fetch all available book copies
//        let bookCopiesRef = bookRef.collection("bookCopies")
//        let bookCopiesSnapshot = try await bookCopiesRef.whereField("status", isEqualTo: "available").getDocuments()
//        
//        guard let availableBookCopy = bookCopiesSnapshot.documents.first else {
//            throw NSError(domain: "LibraryError", code: 400, userInfo: [NSLocalizedDescriptionKey: "No available copies of this book."])
//        }
//        
//        let bookBarcodeID = availableBookCopy.documentID
//        let bookIssueRef = db.collection("bookIssues")
//        
//        // Check if this bookBarcodeID is already issued
//        let issuedBooksSnapshot = try await bookIssueRef.whereField("bookID", isEqualTo: bookBarcodeID)
//            .whereField("isReturned", isEqualTo: false).getDocuments()
//        
//        if !issuedBooksSnapshot.documents.isEmpty {
//            throw NSError(domain: "LibraryError", code: 400, userInfo: [NSLocalizedDescriptionKey: "This book copy is already issued."])
//        }
//        
//        let bookCopyRef = bookCopiesRef.document(bookBarcodeID)
//        let newIssueRef = bookIssueRef.document()
//
//        let issueDate = Date()
//        
//        // Calculate due date (issueDate + 2 months) and initial return date (issueDate - 1 day)
//        guard let dueDate = Calendar.current.date(byAdding: .month, value: 2, to: issueDate),
//              let initialReturnDate = Calendar.current.date(byAdding: .day, value: -1, to: issueDate) else {
//            throw NSError(domain: "DateError", code: 500, userInfo: [NSLocalizedDescriptionKey: "Failed to calculate due or return date."])
//        }
//        
//        // Prepare issue data
//        let issueData: [String: Any] = [
//            "issueID": newIssueRef.documentID,
//            "useruid": Auth.auth().currentUser!.uid,
//            "bookID": bookBarcodeID,
//            "libraryuid": book.libraryID,
//            "issueDate": Timestamp(date: issueDate),
//            "dueDate": Timestamp(date: dueDate),
//            "returnDate": Timestamp(date: initialReturnDate), // Initially issueDate - 1 day
//            "isReturned": false,
//            "fineAmount": 0.0
//        ]
//        
//        // Perform Firestore batch operation
//        let batch = db.batch()
//        
//        // Update book copy status to "checked out"
//        batch.updateData(["status": "checked out"], forDocument: bookCopyRef)
//        
//        // Add book issue record
//        batch.setData(issueData, forDocument: newIssueRef)
//        
//        // Commit batch
//        try await batch.commit()
//        
//        print("Book issued successfully. Due date: \(dueDate), Initial return date: \(initialReturnDate)")
//    }
    
    func issueBook(book: Book) async throws {
        let db = Firestore.firestore()
        let bookRef = db.collection("books").document(book.id!)
        let libraryRef = db.collection("libraries").document(book.libraryID)
        
        // Fetch fineAmount from the library document
        let librarySnapshot = try await libraryRef.getDocument()
        guard let libraryData = librarySnapshot.data(),
              let fineAmount = libraryData["finePerDay"] as? Double else {
            throw NSError(domain: "LibraryError", code: 500, userInfo: [NSLocalizedDescriptionKey: "Failed to fetch fine amount."])
        }

        // Fetch all available book copies
        let bookCopiesRef = bookRef.collection("bookCopies")
        let bookCopiesSnapshot = try await bookCopiesRef.whereField("status", isEqualTo: "available").getDocuments()
        
        guard let availableBookCopy = bookCopiesSnapshot.documents.first else {
            throw NSError(domain: "LibraryError", code: 400, userInfo: [NSLocalizedDescriptionKey: "No available copies of this book."])
        }
        
        let bookBarcodeID = availableBookCopy.documentID
        let bookIssueRef = db.collection("bookIssues")
        
        // Check if this bookBarcodeID is already issued
        let issuedBooksSnapshot = try await bookIssueRef.whereField("bookID", isEqualTo: bookBarcodeID)
            .whereField("isReturned", isEqualTo: false).getDocuments()
        
        if !issuedBooksSnapshot.documents.isEmpty {
            throw NSError(domain: "LibraryError", code: 400, userInfo: [NSLocalizedDescriptionKey: "This book copy is already issued."])
        }
        
        let bookCopyRef = bookCopiesRef.document(bookBarcodeID)
        let newIssueRef = bookIssueRef.document()

        let issueDate = Date()
        
        // Calculate due date (issueDate + 2 months) and initial return date (issueDate - 1 day)
        guard let dueDate = Calendar.current.date(byAdding: .month, value: 2, to: issueDate),
              let initialReturnDate = Calendar.current.date(byAdding: .day, value: -1, to: issueDate) else {
            throw NSError(domain: "DateError", code: 500, userInfo: [NSLocalizedDescriptionKey: "Failed to calculate due or return date."])
        }
        
        // Prepare issue data including fineAmount
        let issueData: [String: Any] = [
            "issueID": newIssueRef.documentID,
            "useruid": Auth.auth().currentUser!.uid,
            "bookID": bookBarcodeID,
            "libraryuid": book.libraryID,
            "issueDate": Timestamp(date: issueDate),
            "dueDate": Timestamp(date: dueDate),
            "returnDate": Timestamp(date: initialReturnDate), // Initially issueDate - 1 day
            "isReturned": false,
            "fineAmount": fineAmount // Added fine amount from library document
        ]
        
        // Perform Firestore batch operation
        let batch = db.batch()
        
        // Update book copy status to "checked out"
        batch.updateData(["status": "checked out"], forDocument: bookCopyRef)
        
        // Add book issue record
        batch.setData(issueData, forDocument: newIssueRef)
        
        // Commit batch
        try await batch.commit()
        
        print("Book issued successfully. Due date: \(dueDate), Initial return date: \(initialReturnDate), Fine per day: \(fineAmount)")
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
}
