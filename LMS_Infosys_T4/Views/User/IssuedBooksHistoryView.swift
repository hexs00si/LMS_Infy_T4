//
//  IssuedBooksHistoryView.swift
//  LMS_Infosys_T4
//
//  Created by Dakshdeep Singh on 24/02/25.
//


import SwiftUI
import Firebase

struct IssuedBook: Identifiable {
    let id: String
    let bookID: String
    let title: String
    let author: String
    let isbn: String
    let coverImageURL: String
    let isReturned: Bool
}


struct IssuedBooksHistoryView: View {
    @State private var issuedBooks: [IssuedBook] = []
    @State private var showingIssueBookView = false
    
    var body: some View {
        NavigationView {
            List(issuedBooks) { book in
                HStack {
                    if let url = URL(string: book.coverImageURL) {
                        AsyncImage(url: url) { image in
                            image.resizable()
                                .scaledToFit()
                                .frame(width: 50, height: 70)
                                .clipShape(RoundedRectangle(cornerRadius: 8))
                        } placeholder: {
                            Color.gray.frame(width: 50, height: 70)
                        }
                    }
                    
                    VStack(alignment: .leading) {
                        Text(book.title).font(.headline)
                        Text("Author: \(book.author)").font(.subheadline)
                        Text("ISBN: \(book.isbn)").font(.caption).foregroundColor(.gray)
                        Text("Status: \(book.isReturned ? "Returned" : "Issued")")
                            .font(.caption)
                            .foregroundColor(book.isReturned ? .green : .red)
                    }
                    Spacer()
                }
            }
            .navigationTitle("Issued Books")
            .toolbar {
                Button("Add Issue") {
                    showingIssueBookView = true
                }
            }
            .sheet(isPresented: $showingIssueBookView) {
                IssueBookView(viewModel: LibraryViewModel())
            }
        }
        .onAppear {
          //  fetchIssuedBooks()
        }
    }
    
    private func fetchIssuedBooks() {
        let db = Firestore.firestore()
        db.collection("bookIssues").getDocuments { snapshot, error in
            if let error = error {
                print("Error fetching issued books: \(error)")
                return
            }
            guard let documents = snapshot?.documents else { return }
            
            let group = DispatchGroup()
            var fetchedBooks: [IssuedBook] = []
            
            for document in documents {
                let data = document.data()
                let bookID = data["bookID"] as? String ?? ""
                let isReturned = data["isReturned"] as? Bool ?? false
                
                group.enter()
                db.collection("books").document(bookID).getDocument { bookDoc, _ in
                    if let bookData = bookDoc?.data() {
                        let book = IssuedBook(
                            id: document.documentID,
                            bookID: bookID,
                            title: bookData["title"] as? String ?? "Unknown",
                            author: bookData["author"] as? String ?? "Unknown",
                            isbn: bookData["isbn"] as? String ?? "",
                            coverImageURL: bookData["coverImage"] as? String ?? "",
                            isReturned: isReturned
                        )
                        fetchedBooks.append(book)
                    }
                    group.leave()
                }
            }
            
            group.notify(queue: .main) {
                issuedBooks = fetchedBooks
            }
        }
    }
}
