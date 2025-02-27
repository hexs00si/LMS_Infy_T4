//
//  LibraryChatService .swift
//  LMS_Infosys_T4
//
//  Created by Shravan Rajput on 27/02/25.
//

import Foundation
import FirebaseFirestore

class LibraryChatService {
    private let db = Firestore.firestore()
    
    // Search for books by title, author, or genre
    func searchBooks(query: String, completion: @escaping ([Book]) -> Void) {
        // Convert query to lowercase for case-insensitive searching
        let lowercaseQuery = query.lowercased()
        
        // Get books collection reference
        let booksRef = db.collection("books")
        
        // We'll perform multiple queries to search across different fields
        // and combine the results
        var allBooks: [Book] = []
        let group = DispatchGroup()
        
        // Search by title
        group.enter()
        booksRef
            .whereField("title", isGreaterThanOrEqualTo: lowercaseQuery)
            .whereField("title", isLessThanOrEqualTo: lowercaseQuery + "\u{f8ff}")
            .limit(to: 5)
            .getDocuments { (snapshot, error) in
                defer { group.leave() }
                
                if let error = error {
                    print("Error searching books by title: \(error)")
                    return
                }
                
                let books = snapshot?.documents.compactMap { try? $0.data(as: Book.self) } ?? []
                allBooks.append(contentsOf: books)
            }
        
        // Search by author
        group.enter()
        booksRef
            .whereField("author", isGreaterThanOrEqualTo: lowercaseQuery)
            .whereField("author", isLessThanOrEqualTo: lowercaseQuery + "\u{f8ff}")
            .limit(to: 5)
            .getDocuments { (snapshot, error) in
                defer { group.leave() }
                
                if let error = error {
                    print("Error searching books by author: \(error)")
                    return
                }
                
                let books = snapshot?.documents.compactMap { try? $0.data(as: Book.self) } ?? []
                allBooks.append(contentsOf: books)
            }
        
        // Search by genre
        group.enter()
        booksRef
            .whereField("genre", isEqualTo: lowercaseQuery)
            .limit(to: 5)
            .getDocuments { (snapshot, error) in
                defer { group.leave() }
                
                if let error = error {
                    print("Error searching books by genre: \(error)")
                    return
                }
                
                let books = snapshot?.documents.compactMap { try? $0.data(as: Book.self) } ?? []
                allBooks.append(contentsOf: books)
            }
        
        // When all searches are complete, deduplicate and return results
        group.notify(queue: .main) {
            // Deduplicate books by ID
            var uniqueBooks: [Book] = []
            var seenIds = Set<String>()
            
            for book in allBooks {
                if let id = book.id, !seenIds.contains(id) {
                    seenIds.insert(id)
                    uniqueBooks.append(book)
                }
            }
            
            completion(uniqueBooks)
        }
    }
    
    // Get books by genre for recommendations
    func getBooksByGenre(genre: String, limit: Int = 5, completion: @escaping ([Book]) -> Void) {
        db.collection("books")
            .whereField("genre", isEqualTo: genre)
            .limit(to: limit)
            .getDocuments { (snapshot, error) in
                if let error = error {
                    print("Error getting books by genre: \(error)")
                    completion([])
                    return
                }
                
                let books = snapshot?.documents.compactMap { try? $0.data(as: Book.self) } ?? []
                completion(books)
            }
    }
    
    // Get library name from library ID
    func getLibraryName(libraryID: String, completion: @escaping (String) -> Void) {
        db.collection("libraries")
            .document(libraryID)
            .getDocument { (document, error) in
                if let error = error {
                    print("Error getting library: \(error)")
                    completion("Unknown Library")
                    return
                }
                
                if let document = document, document.exists,
                   let data = document.data(),
                   let name = data["name"] as? String {
                    completion(name)
                } else {
                    completion("Unknown Library")
                }
            }
    }
    
    // Get most popular books (based on issue count)
    func getPopularBooks(limit: Int = 5, completion: @escaping ([Book]) -> Void) {
        db.collection("books")
            .order(by: "bookIssueCount", descending: true)
            .limit(to: limit)
            .getDocuments { (snapshot, error) in
                if let error = error {
                    print("Error getting popular books: \(error)")
                    completion([])
                    return
                }
                
                let books = snapshot?.documents.compactMap { document -> Book? in
                    do {
                        var book = try document.data(as: Book.self)
                        if let issueCount = document.data()["bookIssueCount"] as? Int {
                            book.bookIssueCount = issueCount
                        }
                        return book
                    } catch {
                        print("Error decoding book: \(error)")
                        return nil
                    }
                } ?? []
                
                completion(books)
            }
    }
    
    // Check if a specific book is available
    func checkBookAvailability(title: String, completion: @escaping (Book?) -> Void) {
        db.collection("books")
            .whereField("title", isEqualTo: title)
            .getDocuments { (snapshot, error) in
                if let error = error {
                    print("Error checking book availability: \(error)")
                    completion(nil)
                    return
                }
                
                if let document = snapshot?.documents.first {
                    do {
                        var book = try document.data(as: Book.self)
                        if let issueCount = document.data()["bookIssueCount"] as? Int {
                            book.bookIssueCount = issueCount
                        }
                        completion(book)
                    } catch {
                        print("Error decoding book: \(error)")
                        completion(nil)
                    }
                } else {
                    completion(nil)
                }
            }
    }
}
