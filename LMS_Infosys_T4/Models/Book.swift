//
//  Book.swift
//  LMS
//
//  Created by Gaganveer Bawa on 13/02/25.
//


import Foundation
import FirebaseFirestore

struct BookDetail { // For fetching the book details from the DB
    let isbn: Int
    let title: String
    let author: String
    let availabilityStatus: Bool
    let coverImage: String?
    let availableCopies: Int
    let description: String
    let genre: String
    let libraryId: Int
    let publishYear: Int
    let pageCount: Int
    let quantity: Int
}

struct BookDetails: Identifiable {
    let id = UUID()
    let title: String
    let author: String
    let image: String
    let status: String
    let category: [String]
    let rating: Double
    let reviews: Int
    let isbn: String
    let publisher: String
    let publishedDate: String
    let description: String
}

struct Book: Identifiable { // To add new book to the DB
    let id: String               // bookID in schema
    let libraryID: String
    let addedByLibrarian: String
    let title: String
    let author: String
    let isbn: String
    let availabilityStatus: AvailabilityStatus
    let publishYear: Int
    let genre: String
//    let edition: String
    let coverImage: String
    let description: String
    let quantity: Int
    let availableCopies: String
}

//struct Book: Identifiable, Codable {
//    @DocumentID var id: String?
//    var title: String
//    var author: String
//    var availabilityStatus: Bool
//    var availableCopies: Int
//    var coverImage: String
//    var description: String
//    var edition: String
//    var genre: String
//    var isbn: Int
//    var libraryID: String
//    var publishYear: Int
//    var quantity: Int
//}

//struct Book: Codable, Identifiable {
//    @DocumentID var id: String?
//    let libraryID: String
//    let addedByLibrarian: String
//    let title: String
//    let author: String
//    let ISBN: Int
//    var availabilityStatus: AvailabilityStatus
//    let publishYear: Int
//    let genre: String
//    let edition: String
//    let coverImage: String
//    let description: String
//    let quantity: Int
//    var availableCopies: Int
//    
//    enum CodingKeys: String, CodingKey {
//        case id = "bookID"
//        case libraryID, addedByLibrarian, title, author
//        case ISBN, availabilityStatus, publishYear, genre
//        case edition, coverImage, description, quantity
//        case availableCopies
//    }
//}
//
//enum AvailabilityStatus: String, Codable {
//    case available
//    case borrowed
//    case maintenance
//}
//
//struct BookIssue: Codable, Identifiable {
//    @DocumentID var id: String?
//    let userUid: String
//    let bookID: String
//    let librarianUid: String
//    let libraryUid: String
//    let issueDate: Date
//    let dueDate: Date
//    var returnDate: Date?
//    var isReturned: Bool
//    var fineAmount: Double
//    
//    enum CodingKeys: String, CodingKey {
//        case id = "issueID"
//        case userUid, bookID, librarianUid, libraryUid
//        case issueDate, dueDate, returnDate, isReturned
//        case fineAmount
//    }
//}
