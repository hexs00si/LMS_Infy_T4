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
    let coverImage: String
    let isReturned: Bool
    let status: String // "pending", "approved", "rejected"
    let issueDate: Date
}

// Define enums for filter and sort options
enum BookStatus: String, CaseIterable, Identifiable {
    case all = "All"
    case pending = "Pending"
    case approved = "Approved"
    case rejected = "Rejected"
    case returned = "Returned"
    
    var id: String { self.rawValue }
}

enum SortOption: String, CaseIterable, Identifiable {
    case newest = "Newest First"
    case oldest = "Oldest First"
    
    var id: String { self.rawValue }
}

struct IssuedBooksHistoryView: View {
    @StateObject private var viewModel = LibraryViewModel()
    @State private var issuedBooks: [IssuedBook] = []
    @State private var showingIssueBookView = false
    // Add these state variables at the top of your IssuedBooksHistoryView struct
    @State private var showingFilterOptions = false
    @State private var filterStatus: BookStatus = .all
    @State private var sortBy: SortOption = .newest
    
    var body: some View {
        NavigationView {
            ZStack {
                List(issuedBooks) { book in
                    HStack {
                        // Display book cover image from base64 string
                        if let imageData = Data(base64Encoded: book.coverImage),
                           let uiImage = UIImage(data: imageData) {
                            Image(uiImage: uiImage)
                                .resizable()
                                .scaledToFit()
                                .frame(width: 50, height: 70)
                                .clipShape(RoundedRectangle(cornerRadius: 8))
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
                                switch book.status {
                                    case "pending":
                                        Text("Pending")
                                            .font(.caption)
                                            .padding(.horizontal, 8)
                                            .padding(.vertical, 2)
                                            .background(Color.orange.opacity(0.2))
                                            .foregroundColor(.orange)
                                            .clipShape(Capsule())
                                    case "approved":
                                        if book.isReturned {
                                            Text("Returned")
                                                .font(.caption)
                                                .padding(.horizontal, 8)
                                                .padding(.vertical, 2)
                                                .background(Color.green.opacity(0.2))
                                                .foregroundColor(.green)
                                                .clipShape(Capsule())
                                        } else {
                                            Text("Approved")
                                                .font(.caption)
                                                .padding(.horizontal, 8)
                                                .padding(.vertical, 2)
                                                .background(Color.blue.opacity(0.2))
                                                .foregroundColor(.blue)
                                                .clipShape(Capsule())
                                        }
                                    case "rejected":
                                        Text("Rejected")
                                            .font(.caption)
                                            .padding(.horizontal, 8)
                                            .padding(.vertical, 2)
                                            .background(Color.red.opacity(0.2))
                                            .foregroundColor(.red)
                                            .clipShape(Capsule())
                                    default:
                                        Text(book.status.capitalized)
                                            .font(.caption)
                                            .padding(.horizontal, 8)
                                            .padding(.vertical, 2)
                                            .background(Color.gray.opacity(0.2))
                                            .foregroundColor(.gray)
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
                    ToolbarItem(placement: .navigationBarLeading) {
                        Text("Books: \(issuedBooks.count)")
                            .font(.subheadline)
                            .bold()
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color.blue.opacity(0.2))
                            .foregroundColor(.blue)
                            .clipShape(Capsule())
                    }
                    
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button(action: {
                            showingIssueBookView = true
                        }) {
                            Label("Issue Book", image: "custom.text.book.closed.badge.plus")
                        }
                    }
                    
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button(action: { showingFilterOptions = true }) {
                            Label("Filter", systemImage: "line.3.horizontal.decrease.circle")
                        }
                    }
                }
                .sheet(isPresented: $showingFilterOptions) {
                    FilterView(filterStatus: $filterStatus, sortBy: $sortBy, applyFilters: applyFilters)
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
            // Clear the issuedBooks array before fetching new data
            DispatchQueue.main.async {
                self.issuedBooks = []
            }
            
            // Fetch user book requests and issued books
            try await viewModel.fetchUserBookRequests()
            
            // Convert BookRequests to IssuedBooks
            await fetchBookDetailsForRequests()
            
//            // Add book issues too if needed
//            await fetchIssuedBooks()
            
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
                
                // Parse the requestDate from the BookRequest
                let issueDate = request.requestDate
                
                // Include in the IssuedBook constructor
                let book = IssuedBook(
                    id: request.id ?? request.requestId,
                    bookID: request.bookId,
                    title: bookData["title"] as? String ?? "Unknown Title",
                    author: bookData["author"] as? String ?? "Unknown Author",
                    isbn: bookData["isbn"] as? String ?? "Unknown ISBN",
                    coverImage: bookData["coverImage"] as? String ?? "",
                    isReturned: false,
                    status: request.status, // Use the actual status from the request
                    issueDate: issueDate
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
    
//    func fetchIssuedBooks() async {
//        guard let currentUser = Auth.auth().currentUser else { return }
//        
//        let db = Firestore.firestore()
//        
//        do {
//            // Get all issued books for the current user
//            let issuesSnapshot = try await db.collection("bookIssues")
//                .whereField("userId", isEqualTo: currentUser.uid)
//                .getDocuments()
//            
//            var bookIssuesData: [IssuedBook] = []
//            
//            for document in issuesSnapshot.documents {
//                let data = document.data()
//                let bookId = data["bookId"] as? String ?? ""
//                let isReturned = data["isReturned"] as? Bool ?? false
//                
//                // Get the book details
//                guard let mainBookId = bookId.split(separator: "-").first else { continue }
//                
//                let bookDoc = try await db.collection("books").document(String(mainBookId)).getDocument()
//                guard let bookData = bookDoc.data() else { continue }
//                
//                // Get issue date from the document
//                let issueDateTimestamp = data["issueDate"] as? Timestamp
//                let issueDate = issueDateTimestamp?.dateValue() ?? Date()
//                
//                // Include in the IssuedBook constructor
//                let book = IssuedBook(
//                    id: document.documentID,
//                    bookID: bookId,
//                    title: bookData["title"] as? String ?? "Unknown Title",
//                    author: bookData["author"] as? String ?? "Unknown Author",
//                    isbn: bookData["isbn"] as? String ?? "Unknown ISBN",
//                    coverImage: bookData["coverImage"] as? String ?? "",
//                    isReturned: isReturned,
//                    status: "approved", // Book issues are always approved
//                    issueDate: issueDate
//                )
//                
//                bookIssuesData.append(book)
//            }
//            
//            DispatchQueue.main.async {
//                // Combine requests and issues
//                self.issuedBooks.append(contentsOf: bookIssuesData)
//                
//                // Apply any filters
//                self.applyFilters()
//            }
//        } catch {
//            print("Error fetching issued books: \(error.localizedDescription)")
//        }
//    }
    
    func applyFilters() {
        DispatchQueue.main.async {
            var filteredBooks = self.issuedBooks
            
            // Filter by status
            if self.filterStatus != .all {
                filteredBooks = filteredBooks.filter { book in
                    switch self.filterStatus {
                    case .pending:
                        return book.status == "pending"
                    case .approved:
                        return book.status == "approved" && !book.isReturned
                    case .rejected:
                        return book.status == "rejected"
                    case .returned:
                        return book.status == "approved" && book.isReturned
                    case .all:
                        return true
                    }
                }
            }
            
            // Sort by date
            filteredBooks.sort { book1, book2 in
                switch self.sortBy {
                case .newest:
                    return book1.issueDate > book2.issueDate
                case .oldest:
                    return book1.issueDate < book2.issueDate
                }
            }
            
            self.issuedBooks = filteredBooks
        }
    }
}

struct FilterView: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var filterStatus: BookStatus
    @Binding var sortBy: SortOption
    var applyFilters: () -> Void
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Filter by Status")) {
                    ForEach(BookStatus.allCases) { status in
                        Button {
                            filterStatus = status
                        } label: {
                            HStack {
                                Text(status.rawValue)
                                Spacer()
                                if filterStatus == status {
                                    Image(systemName: "checkmark")
                                        .foregroundColor(.blue)
                                }
                            }
                        }
                        .foregroundColor(.primary)
                    }
                }
                
                Section(header: Text("Sort by")) {
                    ForEach(SortOption.allCases) { option in
                        Button {
                            sortBy = option
                        } label: {
                            HStack {
                                Text(option.rawValue)
                                Spacer()
                                if sortBy == option {
                                    Image(systemName: "checkmark")
                                        .foregroundColor(.blue)
                                }
                            }
                        }
                        .foregroundColor(.primary)
                    }
                }
            }
            .navigationTitle("Filter Books")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Apply") {
                        applyFilters()
                        dismiss()
                    }
                    .bold()
                }
                
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
    }
}
