
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
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    ForEach(sections, id: \.title) { section in
                        let filteredBooks = viewModel.books.filter(section.filter)
                        SectionView(
                            title: section.title,
                            books: Array(filteredBooks.prefix(4)),
                            allBooks: filteredBooks,
                            viewModel: viewModel
                        )
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
    let allBooks: [Book]
    let viewModel: LibraryViewModel
    
    var body: some View {
        VStack(alignment: .leading) {
            NavigationLink(destination: BookListView(title: title, books: allBooks, viewModel: viewModel)) {
                HStack {
                    Text(title)
                        .font(.title2.bold())
                    
                    Image(systemName: "chevron.right")
                        .foregroundColor(.blue)
                }
                .padding(.leading)
            }
            .buttonStyle(PlainButtonStyle())
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 16) {
                    if books.isEmpty {
                        Text("No books available")
                            .foregroundColor(.secondary)
                            .padding()
                    } else {
                        ForEach(books) { book in
                            BookCard(book: book)
                        }
                    }
                }
                .padding(.horizontal)
            }
        }
    }
}

#Preview {
    BookShelf()
}

