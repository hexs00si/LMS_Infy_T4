//
//  LibraryView.swift
//  LMS_Infosys_T4
//
//  Created by Gaganveer Bawa on 27/02/25.
//


import SwiftUI

struct BookShelf: View {
    @StateObject private var viewModel = LibraryViewModel()
    @State private var isLoading = false
    @State private var showAlert = false
    @State private var alertMessage = ""
    
    let sections: [(title: String, filter: (Book) -> Bool)] = [
        ("Want to Read", { _ in true }),
        ("Currently Reading", { $0.availabilityStatus == .checkedOut }),
        ("Completed", { $0.bookIssueCount > 0 }),
        ("Reserved", { $0.availabilityStatus == .reserved })
    ]
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    ForEach(sections, id: \.title) { section in
                        SectionView(title: section.title, books: viewModel.books.filter(section.filter))
                    }
                }
                .padding()
            }
            .navigationTitle("My Library")
            .onAppear {
                Task {
                    isLoading = true
                    do {
                        // Fetch all books for the reserved section
                        let allBooks = try await viewModel.fetchAllBooks()
                        viewModel.books = allBooks
                        
                        // Fetch books for the other sections
                        let wishlistBooks = try await viewModel.fetchWishlistBooks()
                        let currentlyReadingBooks = try await viewModel.fetchCurrentlyReadingBooks()
                        let alreadyReadBooks = try await viewModel.fetchAlreadyReadBooks()
                        
                        // Combine all books into one array
                        viewModel.books = allBooks + wishlistBooks + currentlyReadingBooks + alreadyReadBooks
                    } catch {
                        alertMessage = "Error fetching books: \(error.localizedDescription)"
                        showAlert = true
                    }
                    isLoading = false
                }
            }
            .alert(isPresented: $showAlert) {
                Alert(title: Text("Error"), message: Text(alertMessage), dismissButton: .default(Text("OK")))
            }
        }
    }
}

struct SectionView: View {
    let title: String
    let books: [Book]
    
    var body: some View {
        VStack(alignment: .leading) {
            Text(title)
                .font(.title2.bold())
                .padding(.leading)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 16) {
                    if books.isEmpty {
                        Text("No books available")
                            .foregroundColor(.secondary)
                            .padding()
                    } else {
                        ForEach(books) { book in
                            BookCardView(book: book)
                        }
                    }
                }
                .padding(.horizontal)
            }
        }
    }
}

struct BookCardView: View {
    let book: Book
    
    var body: some View {
        VStack(alignment: .leading) {
            if let image = book.getCoverImage() {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 120, height: 180)
                    .cornerRadius(8)
            } else {
                Rectangle()
                    .fill(Color.gray.opacity(0.3))
                    .frame(width: 120, height: 180)
                    .cornerRadius(8)
                    .overlay(Text("No Image").foregroundColor(.gray))
            }
            Text(book.title)
                .font(.headline)
                .lineLimit(2)
                .frame(width: 120, alignment: .leading)
            Text(book.author)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .frame(width: 120, alignment: .leading)
        }
    }
}

struct LibraryView_Previews: PreviewProvider {
    static var previews: some View {
        BookShelf()
    }
}
