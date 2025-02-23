//
//  LibraryViewModel.swift
//  libraraian 1
//
//  Created by Kinshuk Garg on 14/02/25.
//


import SwiftUI

//struct Book: Identifiable, Codable {
//    let id: UUID
//    var isbn: String
//    var title: String
//    var author: String
//    var publisher: String
//    var year: String
//    var genre: String?
//    
//    init(id: UUID = UUID(), isbn: String, title: String, author: String, publisher: String = "", year: String, genre: String? = nil) {
//        self.id = id
//        self.isbn = isbn
//        self.title = title
//        self.author = author
//        self.publisher = publisher
//        self.year = year
//        self.genre = genre
//    }
//}


class LibraryViewModel: ObservableObject {
    @Published var books: [Book] = []
    @Published var recentActivities: [String] = []
    
    var totalBooks: Int { books.count }
    var booksIssued: Int = 89
    var dueReturns: Int = 12
    var newImports: Int = 45
    
    func addBook(_ book: Book) {
        books.append(book)
        recentActivities.insert("New Import: \(book.title)", at: 0)
    }
    
//    func importBooks(from url: URL) {
//        // CSV import logic would go here
//        addBook(Book(isbn: "978-0-12345-678-9", 
//                    title: "Sample Book", 
//                    author: "Author Name",
//                    year: "2024"))
//    }
}
