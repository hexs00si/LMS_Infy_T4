//
//  ReturnBookHistoryView.swift
//  LMS_Infosys_T4
//
//  Created by Dakshdeep Singh on 27/02/25.
//

import SwiftUI
import Firebase

struct ReturnBookHistoryView: View {
    @ObservedObject var viewModel: LibraryViewModel
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var showError = false
    @State private var returnedBooks: [ReturnedBookInfo] = []
    @State private var sortAscending = true
    @State private var showingReturnBookView = false
    
    struct ReturnedBookInfo: Identifiable {
        let id: String
        let title: String
        let author: String
        let isbn: String
        let bookId: String
        let userId: String
        let userName: String
        let userEmail: String
        let issueDate: Date
        let returnDate: Date
        let coverImage: String
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                VStack {
                    if returnedBooks.isEmpty && !isLoading {
                        VStack(spacing: 12) {
                            Image(systemName: "book.closed")
                                .font(.system(size: 50))
                                .foregroundColor(.secondary)
                            Text("No returned books found")
                                .font(.headline)
                            Text("Books that have been returned will appear here")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal)
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                    } else {
                        List {
                            ForEach(returnedBooks) { book in
                                ReturnedBookRow(book: book)
                            }
                        }
                        .listStyle(InsetGroupedListStyle())
                        .refreshable {
                            await loadReturnedBooks()
                        }
                    }
                }
                
                if isLoading {
                    ProgressView()
                        .scaleEffect(1.5)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .background(Color.black.opacity(0.2))
                }
            }
            .alert("Error", isPresented: $showError) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(errorMessage ?? "An unknown error occurred")
            }
            .navigationTitle("Return Books")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        showingReturnBookView = true
                    }) {
                        Image(systemName: "plus")
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Menu {
                        Button(action: {
                            sortAscending = true
                            sortBooks()
                        }) {
                            Label("Oldest First", systemImage: "arrow.up")
                        }
                        
                        Button(action: {
                            sortAscending = false
                            sortBooks()
                        }) {
                            Label("Recent First", systemImage: "arrow.down")
                        }
                    } label: {
                        Image(systemName: "arrow.up.arrow.down")
                    }
                }
            }
            .sheet(isPresented: $showingReturnBookView) {
                ReturnBookView(viewModel: viewModel)
            }
            .onAppear {
                Task {
                    await loadReturnedBooks()
                }
            }
        }
    }
    
    private func loadReturnedBooks() async {
        isLoading = true
        defer { isLoading = false }
        
        do {
            let books = try await viewModel.fetchReturnedBooks()
            returnedBooks = books
            sortBooks()
        } catch {
            errorMessage = error.localizedDescription
            showError = true
        }
    }
    
    private func sortBooks() {
        returnedBooks.sort { book1, book2 in
            if sortAscending {
                return book1.returnDate < book2.returnDate
            } else {
                return book1.returnDate > book2.returnDate
            }
        }
    }
}

struct ReturnedBookRow: View {
    let book: ReturnBookHistoryView.ReturnedBookInfo
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top, spacing: 12) {
                // Book cover image
                if let imageData = Data(base64Encoded: book.coverImage),
                   let uiImage = UIImage(data: imageData) {
                    Image(uiImage: uiImage)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: 80, height: 120)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                        .shadow(radius: 2)
                } else {
                    Rectangle()
                        .fill(Color.gray.opacity(0.3))
                        .frame(width: 80, height: 120)
                        .cornerRadius(8)
                        .overlay(
                            Image(systemName: "book.closed")
                                .foregroundColor(.gray)
                                .font(.system(size: 30))
                        )
                }
                
                // Book details
                VStack(alignment: .leading, spacing: 6) {
                    Text(book.title)
                        .font(.headline)
                        .lineLimit(2)
                    
                    Text(book.author)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    Text("ISBN: \(book.isbn)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Divider()
                    
                    // User info
                    Text(book.userName)
                        .font(.subheadline)
                        .fontWeight(.medium)
                    
                    Text(book.userEmail)
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Spacer(minLength: 5)
                    
                    // Date information
                    HStack {
                        VStack(alignment: .leading, spacing: 3) {
                            Label {
                                Text("Issued: \(formatDate(book.issueDate))")
                                    .font(.caption)
                            } icon: {
                                Image(systemName: "arrow.right.circle")
                                    .foregroundColor(.blue)
                            }
                            
                            Label {
                                Text("Returned: \(formatDate(book.returnDate))")
                                    .font(.caption)
                            } icon: {
                                Image(systemName: "arrow.left.circle")
                                    .foregroundColor(.green)
                            }
                        }
                        Spacer()
                    }
                }
            }
            .padding(.vertical, 4)
        }
        .padding(.vertical, 6)
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

#Preview {
    ReturnBookHistoryView(viewModel: LibraryViewModel())
}
