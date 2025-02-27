//
//  LibraryChatService .swift
//  LMS_Infosys_T4
//
//  Created by Shravan Rajput on 27/02/25.
//

import FirebaseFirestore
import Foundation

class LibraryChatService {
    private let db = Firestore.firestore()
    
    func searchBooks(query: String, completion: @escaping ([Book]) -> Void) {
        let lowercaseQuery = query.lowercased()
        let booksRef = db.collection("books")
        var allBooks: [Book] = []
        let group = DispatchGroup()
        
        group.enter()
        booksRef
            .whereField("title", isGreaterThanOrEqualTo: lowercaseQuery)
            .whereField("title", isLessThanOrEqualTo: lowercaseQuery + "\u{f8ff}")
            .limit(to: 5)
            .getDocuments { snapshot, error in
                defer { group.leave() }
                if let error = error { print("Error searching books by title: \(error)"); return }
                let books = snapshot?.documents.compactMap { try? $0.data(as: Book.self) } ?? []
                allBooks.append(contentsOf: books)
            }
        
        group.enter()
        booksRef
            .whereField("author", isGreaterThanOrEqualTo: lowercaseQuery)
            .whereField("author", isLessThanOrEqualTo: lowercaseQuery + "\u{f8ff}")
            .limit(to: 5)
            .getDocuments { snapshot, error in
                defer { group.leave() }
                if let error = error { print("Error searching books by author: \(error)"); return }
                let books = snapshot?.documents.compactMap { try? $0.data(as: Book.self) } ?? []
                allBooks.append(contentsOf: books)
            }
        
        group.enter()
        booksRef
            .whereField("genre", isEqualTo: lowercaseQuery)
            .limit(to: 5)
            .getDocuments { snapshot, error in
                defer { group.leave() }
                if let error = error { print("Error searching books by genre: \(error)"); return }
                let books = snapshot?.documents.compactMap { try? $0.data(as: Book.self) } ?? []
                allBooks.append(contentsOf: books)
            }
        
        group.notify(queue: .main) {
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
    
    func getBooksByGenre(genre: String, limit: Int = 5, completion: @escaping ([Book]) -> Void) {
        db.collection("books")
            .whereField("genre", isEqualTo: genre)
            .limit(to: limit)
            .getDocuments { snapshot, error in
                if let error = error {
                    print("Error getting books by genre: \(error)")
                    completion([])
                    return
                }
                let books = snapshot?.documents.compactMap { try? $0.data(as: Book.self) } ?? []
                completion(books)
            }
    }
    
    func getLibraryName(libraryID: String, completion: @escaping (String) -> Void) {
        db.collection("libraries")
            .document(libraryID)
            .getDocument { document, error in
                if let error = error {
                    print("Error getting library: \(error)")
                    completion("Unknown Library")
                    return
                }
                if let document = document, document.exists, let data = document.data(), let name = data["name"] as? String {
                    completion(name)
                } else {
                    completion("Unknown Library")
                }
            }
    }
    
    func getPopularBooks(limit: Int = 5, completion: @escaping ([Book]) -> Void) {
        db.collection("books")
            .order(by: "bookIssueCount", descending: true)
            .limit(to: limit)
            .getDocuments { snapshot, error in
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
    
    func checkBookAvailability(title: String, completion: @escaping (Book?) -> Void) {
        db.collection("books")
            .whereField("title", isEqualTo: title.capitalized) // Case-insensitive match
            .limit(to: 1)
            .getDocuments { snapshot, error in
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
