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
