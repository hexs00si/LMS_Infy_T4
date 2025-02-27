//
//  ReportsViewModel.swift
//  LMS_Infosys_T4
//
//  Created by Shravan Rajput on 27/02/25.
//

import Foundation
import FirebaseFirestore

class ReportsViewModel: ObservableObject {
    @Published var topIssuedBooks: [Book] = []
    @Published var isLoading = false
    @Published var error: String?
    
    private let db = Firestore.firestore()
    
    init() {
        fetchTopIssuedBooks()
    }
    
    func fetchTopIssuedBooks(limit: Int = 3) {
        isLoading = true
        error = nil
        
        db.collection("books")
            .order(by: "bookIssueCount", descending: true)
            .limit(to: limit)
            .getDocuments { [weak self] snapshot, error in
                guard let self = self else { return }
                
                DispatchQueue.main.async {
                    self.isLoading = false
                    
                    if let error = error {
                        self.error = error.localizedDescription
                        return
                    }
                    
                    guard let documents = snapshot?.documents else {
                        self.error = "No documents found"
                        return
                    }
                    
                    self.topIssuedBooks = documents.compactMap { document -> Book? in
                        do {
                            var book = try document.data(as: Book.self)
                            // Ensure bookIssueCount is set (it may not be in the Firestore document)
                            if let issueCount = document.data()["bookIssueCount"] as? Int {
                                book.bookIssueCount = issueCount
                            }
                            return book
                        } catch {
                            print("Error decoding book: \(error)")
                            return nil
                        }
                    }
                }
            }
    }
}
