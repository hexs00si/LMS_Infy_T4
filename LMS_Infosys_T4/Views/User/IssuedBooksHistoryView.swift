//
//  IssuedBooksHistoryView.swift
//  LMS_Infosys_T4
//
//  Created by Dakshdeep Singh on 24/02/25.
//

import SwiftUI
import Firebase
import FirebaseFirestore
import FirebaseAuth

struct IssuedBook: Identifiable {
    let id: String
    let bookID: String
    let title: String
    let author: String
    let isbn: String
    let coverImageURL: String
    let isReturned: Bool
    let isApproved: Bool
    
    // You can add more fields if needed
    // var requestDate: Date?
    // var issueDate: Date?
    // var dueDate: Date?
    // var status: String
}

struct IssuedBooksHistoryView: View {
    @StateObject private var viewModel = LibraryViewModel()
    @State private var issuedBooks: [IssuedBook] = []
    @State private var showingIssueBookView = false
    
    var body: some View {
        NavigationView {
            ZStack {
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
                        } else {
                            // Default image if no cover available
                            Rectangle()
                                .fill(Color.gray.opacity(0.3))
                                .frame(width: 50, height: 70)
                                .clipShape(RoundedRectangle(cornerRadius: 8))
                        }
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text(book.title).font(.headline)
                            Text("Author: \(book.author)").font(.subheadline)
                            Text("ISBN: \(book.isbn)").font(.caption).foregroundColor(.gray)
                            
                            // Show status badge
                            HStack {
                                if book.isApproved {
                                    if book.isReturned {
                                        Text("Returned")
                                            .font(.caption)
                                            .padding(.horizontal, 8)
                                            .padding(.vertical, 2)
                                            .background(Color.green.opacity(0.2))
                                            .foregroundColor(.green)
                                            .clipShape(Capsule())
                                    } else {
                                        Text("Issued")
                                            .font(.caption)
                                            .padding(.horizontal, 8)
                                            .padding(.vertical, 2)
                                            .background(Color.blue.opacity(0.2))
                                            .foregroundColor(.blue)
                                            .clipShape(Capsule())
                                    }
                                } else {
                                    Text("Pending")
                                        .font(.caption)
                                        .padding(.horizontal, 8)
                                        .padding(.vertical, 2)
                                        .background(Color.orange.opacity(0.2))
                                        .foregroundColor(.orange)
                                        .clipShape(Capsule())
                                }
                            }
                        }
                        Spacer()
                    }
                    .padding(.vertical, 4)
                }
                .navigationTitle("Issue Books")
                .toolbar {
                    Button("Request Book") {
                        showingIssueBookView = true
                    }
                }
                .sheet(isPresented: $showingIssueBookView) {
                    IssueBookView(viewModel: viewModel)
                }
                .refreshable {
                    await fetchUserBooksHistory()
                }
                
                if viewModel.isLoading {
                    ProgressView("Loading...")
                        .padding()
                        .background(Color.white.opacity(0.8))
                        .cornerRadius(10)
                }
                
                if issuedBooks.isEmpty && !viewModel.isLoading {
                    VStack {
                        Image(systemName: "book.closed")
                            .font(.system(size: 50))
                            .foregroundColor(.gray)
                        Text("No book history found")
                            .font(.headline)
                            .foregroundColor(.gray)
                        Text("Request a book to get started")
                            .font(.subheadline)
                            .foregroundColor(.gray)
                    }
                }
                
                if let error = viewModel.error {
                    Text(error)
                        .foregroundColor(.red)
                        .padding()
                        .background(Color.white.opacity(0.8))
                        .cornerRadius(10)
                }
            }
        }
        .onAppear {
            Task {
                await fetchUserBooksHistory()
            }
        }
    }
    
    func fetchUserBooksHistory() async {
        do {
            // Use the existing fetchUserBookRequests method
            try await viewModel.fetchUserBookRequests()
            
            // Convert BookRequests to IssuedBooks
            await fetchBookDetailsForRequests()
            
            // Add book issues too if needed
            await fetchIssuedBooks()
            
        } catch {
            print("Error fetching user book history: \(error.localizedDescription)")
        }
    }
    
    func fetchBookDetailsForRequests() async {
        let db = Firestore.firestore()
        var tempIssuedBooks: [IssuedBook] = []
        
        for request in viewModel.pendingRequests {
            do {
                // Get main book ID from the copy ID
                guard let mainBookId = request.bookId.split(separator: "-").first else {
                    continue
                }
                
                let bookDoc = try await db.collection("books").document(String(mainBookId)).getDocument()
                guard let bookData = bookDoc.data() else { continue }
                
                // Create IssuedBook object from the request
                let book = IssuedBook(
                    id: request.id ?? request.requestId,
                    bookID: request.bookId,
                    title: bookData["title"] as? String ?? "Unknown Title",
                    author: bookData["author"] as? String ?? "Unknown Author",
                    isbn: bookData["isbn"] as? String ?? "Unknown ISBN",
                    coverImageURL: bookData["coverImage"] as? String ?? "",
                    isReturned: false,
                    isApproved: request.status == "approved"
                )
                
                tempIssuedBooks.append(book)
            } catch {
                print("Error fetching book details: \(error.localizedDescription)")
            }
        }
        
        DispatchQueue.main.async {
            self.issuedBooks = tempIssuedBooks
        }
    }
    
    func fetchIssuedBooks() async {
        guard let currentUser = Auth.auth().currentUser else { return }
        
        let db = Firestore.firestore()
        
        do {
            // Get all issued books for the current user
            let issuesSnapshot = try await db.collection("bookIssues")
                .whereField("userId", isEqualTo: currentUser.uid)
                .getDocuments()
            
            var bookIssuesData: [IssuedBook] = []
            
            for document in issuesSnapshot.documents {
                let data = document.data()
                let bookId = data["bookId"] as? String ?? ""
                let isReturned = data["isReturned"] as? Bool ?? false
                
                // Get the book details
                guard let mainBookId = bookId.split(separator: "-").first else { continue }
                
                let bookDoc = try await db.collection("books").document(String(mainBookId)).getDocument()
                guard let bookData = bookDoc.data() else { continue }
                
                // Create IssuedBook object
                let book = IssuedBook(
                    id: document.documentID,
                    bookID: bookId,
                    title: bookData["title"] as? String ?? "Unknown Title",
                    author: bookData["author"] as? String ?? "Unknown Author",
                    isbn: bookData["isbn"] as? String ?? "Unknown ISBN",
                    coverImageURL: bookData["coverImage"] as? String ?? "",
                    isReturned: isReturned,
                    isApproved: true  // Issues are always approved
                )
                
                bookIssuesData.append(book)
            }
            
            DispatchQueue.main.async {
                // Combine requests and issues
                self.issuedBooks.append(contentsOf: bookIssuesData)
                
                // Sort by approval status (approved first)
                self.issuedBooks.sort {
                    ($0.isApproved ? 1 : 0) > ($1.isApproved ? 1 : 0)
                }
            }
        } catch {
            print("Error fetching issued books: \(error.localizedDescription)")
        }
    }
}
