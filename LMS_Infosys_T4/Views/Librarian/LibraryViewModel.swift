//
//  LibraryViewModel.swift
//  libraraian 1
//
//  Created by Kinshuk Garg on 14/02/25.
//
//
//

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
    let edition: String?
    let quantity: Int
    let availableCopies: String
    
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
        case edition
        case quantity
        case availableCopies
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

//import SwiftUI


//
////struct Book: Identifiable, Codable {
////    let id: UUID
////    var isbn: String
////    var title: String
////    var author: String
////    var publisher: String
////    var year: String
////    var genre: String?
////    
////    init(id: UUID = UUID(), isbn: String, title: String, author: String, publisher: String = "", year: String, genre: String? = nil) {
////        self.id = id
////        self.isbn = isbn
////        self.title = title
////        self.author = author
////        self.publisher = publisher
////        self.year = year
////        self.genre = genre
////    }
////}
//
//
//class LibraryViewModel: ObservableObject {
//    @Published var books: [Book] = []
//    @Published var recentActivities: [String] = []
//    
//    var totalBooks: Int { books.count }
//    var booksIssued: Int = 89
//    var dueReturns: Int = 12
//    var newImports: Int = 45
//    
//    func addBook(_ book: Book) {
//        books.append(book)
//        recentActivities.insert("New Import: \(book.title)", at: 0)
//    }
//    
////    func importBooks(from url: URL) {
////        // CSV import logic would go here
////        addBook(Book(isbn: "978-0-12345-678-9", 
////                    title: "Sample Book", 
////                    author: "Author Name",
////                    year: "2024"))
////    }
//}
