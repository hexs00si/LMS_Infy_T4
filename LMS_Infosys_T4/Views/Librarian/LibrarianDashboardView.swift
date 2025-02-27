
import SwiftUI
import FirebaseFirestore

// Statistics Card Component
struct StatisticCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            HStack {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundColor(color)
                
                Text(value)
                    .font(.title)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(10)
        .shadow(color: Color.black.opacity(0.05), radius: 2, x: 0, y: 2)
    }
}
struct BookListItemView: View {
    let book: Book
    @ObservedObject var viewModel: LibraryViewModel // Add this line
    
    var body: some View {
        NavigationLink(destination: LibrarianBookDetailsView(book: book, viewModel: viewModel)) {
            HStack(spacing: 16) {
                // Book cover image or placeholder
                if let coverImage = book.getCoverImage() {
                    Image(uiImage: coverImage)
                        .resizable()
                        .scaledToFill()
                        .frame(width: 60, height: 80)
                        .cornerRadius(6)
                } else {
                    Rectangle()
                        .fill(Color.gray.opacity(0.3))
                        .frame(width: 60, height: 80)
                        .cornerRadius(6)
                        .overlay(
                            Image(systemName: "book.closed")
                                .foregroundColor(.gray)
                        )
                }
                
                // Book details
                VStack(alignment: .leading, spacing: 4) {
                    Text(book.title)
                        .font(.headline)
                        .lineLimit(1)
                    
                    Text(book.author)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                    
                    HStack {
                        // Availability badge
                        Text(book.availabilityStatus.description)
                            .font(.caption)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 3)
                            .background(availabilityColor(status: book.availabilityStatus).opacity(0.1))
                            .foregroundColor(availabilityColor(status: book.availabilityStatus))
                            .cornerRadius(4)
                    }
                }
            }
            .padding()
            .background(Color(.systemBackground))
            .cornerRadius(8)
            .shadow(color: Color.black.opacity(0.05), radius: 2, x: 0, y: 1)
        }
    }
    
    // Helper function to get color based on availability status
    private func availabilityColor(status: AvailabilityStatus) -> Color {
        switch status {
        case .available:
            return .green
        case .checkedOut:
            return .orange
        case .reserved:
            return .blue
        }
    }
}

struct LibrarianDashboardView: View {
    @StateObject private var viewModel = LibraryViewModel()
    @State private var isAddBookPresented = false
    @State private var searchText = ""
    
    var body: some View {
        TabView {
            NavigationView {
                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {
                        VStack(alignment: .leading, spacing: 16) {
                            Text("Library Statistics")
                                .font(.headline)
                                .foregroundColor(.secondary)
                            
                            StatisticCard(
                                title: "Total Books in Library",
                                value: "\(viewModel.books.count)",
                                icon: "book.fill",
                                color: .blue
                            )
                        }
                        .cornerRadius(12)
                        
                        Text("Recently Added Books")
                            .font(.headline)
                            .foregroundColor(.secondary)
                        
                        VStack(alignment: .leading, spacing: 16) {
                            SearchBar(text: $searchText, placeholder: "Search books...")
                            
                            if viewModel.isLoading {
                                HStack {
                                    Spacer()
                                    ProgressView()
                                        .progressViewStyle(CircularProgressViewStyle())
                                    Spacer()
                                }
                                .padding()
                            } else {
                                ForEach(filteredBooks) { book in
                                    BookListItemView(book: book, viewModel: viewModel) // Pass the viewModel here
                                }
                            }
                        }
                        .padding()
                        .background(Color(.systemBackground))
                        .cornerRadius(12)
                    }
                    .padding()
                }
                .background(Color(.systemGray6))
                .navigationTitle("Librarian Dashboard")
                .onAppear {
                    viewModel.fetchBooks()
                }
                .refreshable {
                    viewModel.fetchBooks()
                }
            }
            .tabItem {
                Label("Dashboard", systemImage: "house.fill")
            }
            
            NavigationView {
                AddBooksOptionView(viewModel: viewModel)
            }
            .tabItem {
                Label("Add Books", systemImage: "plus.circle.fill")
            }
            
            NavigationView {
                BookRequestsView()
            }
            .tabItem {
                Label("Requests", systemImage: "doc.text.fill")
            }
            
            ReturnBookView(viewModel: viewModel)
                .tabItem {
                    Label("Return", image: "custom.text.book.closed.fill.badge.arrow.up")
                }
            
            LibrarianProfileView()
                .tabItem {
                    Label("Profile", systemImage: "person.fill")
                }
        }
    }
    
    private var filteredBooks: [Book] {
        if searchText.isEmpty {
            return viewModel.books.prefix(10).map { $0 }
        } else {
            return viewModel.books.filter {
                $0.title.localizedCaseInsensitiveContains(searchText) ||
                $0.author.localizedCaseInsensitiveContains(searchText) ||
                $0.isbn.localizedCaseInsensitiveContains(searchText)
            }
        }
    }
}
#Preview {
    LibrarianDashboardView()
}
