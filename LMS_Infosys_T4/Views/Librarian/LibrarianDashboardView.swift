////
////  LibrarianDashboardView.swift
////  LMS_Infosys_T4
//
//  Created by Kinshuk Garg on 14/02/25.

////
//
//import SwiftUI
//
//struct LibrarianDashboardView: View {
//    @StateObject private var viewModel = LibraryViewModel()
//    
//    var body: some View {
//        TabView {
//            NavigationView {
//                ScrollView {
//                    VStack(spacing: 20) {
//                        // Stats Grid
//                        LazyVGrid(columns: [
//                            GridItem(.flexible()),
//                            GridItem(.flexible())
//                        ], spacing: 15) {
//                            RoundRectangleView(title: "Total Books", value: "\(1)", color: .blue)
//                            RoundRectangleView(title: "Books Issued", value: "\(2)", color: .green)
//                            RoundRectangleView(title: "Due Returns", value: "\(3)", color: .orange)
//                            RoundRectangleView(title: "New Imports", value: "\(4)", color: .purple)
//                        }
//                        .padding()
//                        
//                        // Recent Activities
//                        VStack(alignment: .leading, spacing: 15) {
//                            Text("Recent Activities")
//                                .font(.headline)
//                        }
//                        .padding()
//                        
//                        // Profile Section
//                        ProfileView()
//                    }
//                }
//                .navigationTitle("Dashboard")
//            }
//            .tabItem {
//                Label("Dashboard", systemImage: "square.grid.2x2")
//            }
//            
//            NavigationView {
//                AddBooksOptionView(viewModel: viewModel)
//            }
//            .tabItem {
//                Label("Import", systemImage: "arrow.up.doc")
//            }
//            
//            NavigationView {
////                BookIssueRequestsView()
//                BookRequestsView()
//            }
//            .tabItem {
//                Label("Issue Requests", systemImage: "doc.text.magnifyingglass")
//            }
//            
//            Text("Profile")
//                .tabItem { Label("Profile", systemImage: "person") }
//        }
//    }
//}
//
//#Preview {
//    LibrarianDashboardView()
//}






//
//
//
//import SwiftUI
//import FirebaseFirestore
//
//struct LibrarianDashboardView: View {
//    @StateObject private var viewModel = LibraryViewModel()
//    @State private var isAddBookPresented = false
//    @State private var searchText = ""
//    
//    var body: some View {
//        NavigationView {
//            ScrollView {
//                VStack(alignment: .leading, spacing: 20) {
//                    // Header Stats - Simplified to only show total books
//                    VStack(alignment: .leading, spacing: 16) {
//                        Text("Library Statistics")
//                            .font(.headline)
//                            .foregroundColor(.secondary)
//                        
//                        // Single stat card for total books
//                        StatisticCard(
//                            title: "Total Books in Library",
//                            value: "\(viewModel.books.count)",
//                            icon: "book.fill",
//                            color: .blue
//                        )
//                    }
//                    .padding()
//                    .background(Color(.systemGray6))
//                    .cornerRadius(12)
//                    
//                    // Recently Added Books
//                    VStack(alignment: .leading, spacing: 16) {
//                        Text("Recently Added Books")
//                            .font(.headline)
//                            .foregroundColor(.secondary)
//                        
//                        // Search Bar
//                        HStack {
//                            Image(systemName: "magnifyingglass")
//                                .foregroundColor(.secondary)
//                            
//                            TextField("Search books", text: $searchText)
//                                .textFieldStyle(RoundedBorderTextFieldStyle())
//                        }
//                        
//                        if viewModel.isLoading {
//                            HStack {
//                                Spacer()
//                                ProgressView()
//                                    .progressViewStyle(CircularProgressViewStyle())
//                                Spacer()
//                            }
//                            .padding()
//                        } else {
//                            ForEach(filteredBooks) { book in
//                                BookListItemView(book: book)
//                            }
//                        }
//                    }
//                    .padding()
//                    .background(Color(.systemGray6))
//                    .cornerRadius(12)
//                }
//                .padding()
//            }
//            .navigationTitle("Librarian Dashboard")
////            .toolbar {
////                ToolbarItem(placement: .navigationBarTrailing) {
////                    Button(action: {
////                        isAddBookPresented = true
////                    }) {
////                        Image(systemName: "plus")
////                    }
////                }
////            }
//            .sheet(isPresented: $isAddBookPresented) {
//                // This would be your AddBookView
//                Text("Add Book Form")
//                    .padding()
//            }
//            .onAppear {
//                // Load data when view appears
//                viewModel.fetchBooks()
//            }
//            .refreshable {
//                // Pull to refresh functionality
//                viewModel.fetchBooks()
//            }
//        }
//    }
//    
//    // Filter books based on search text
//    private var filteredBooks: [Book] {
//        if searchText.isEmpty {
//            // When no search, show most recently added books first (up to 10)
//            return viewModel.books.sorted {_,_ in 
//                // Here you would sort by date added if available
//                // For now, simply using the array order
//                return true
//            }.prefix(10).map { $0 }
//        } else {
//            return viewModel.books.filter {
//                $0.title.localizedCaseInsensitiveContains(searchText) ||
//                $0.author.localizedCaseInsensitiveContains(searchText) ||
//                $0.isbn.localizedCaseInsensitiveContains(searchText)
//            }
//        }
//    }
//}
//
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
        .background(Color.white)
        .cornerRadius(10)
        .shadow(color: Color.black.opacity(0.05), radius: 2, x: 0, y: 2)
    }
}

// Book List Item Component
struct BookListItemView: View {
    let book: Book
    
    var body: some View {
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
                    Text(book.genre)
                        .font(.caption)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(Color.blue.opacity(0.1))
                        .cornerRadius(4)
                    
                    Spacer()
                    
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
        .background(Color.white)
        .cornerRadius(8)
        .shadow(color: Color.black.opacity(0.05), radius: 2, x: 0, y: 1)
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
        case .underMaintenance:
            return .red
        }
    }
}

struct LibrarianDashboardView_Previews: PreviewProvider {
    static var previews: some View {
        LibrarianDashboardView()
    }
}

import SwiftUI
import FirebaseFirestore

struct LibrarianDashboardView: View {
    @StateObject private var viewModel = LibraryViewModel()
    @State private var isAddBookPresented = false
    @State private var searchText = ""
    
    var body: some View {
        TabView {
            NavigationView {
                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
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
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(12)
                        
                        VStack(alignment: .leading, spacing: 16) {
                            Text("Recently Added Books")
                                .font(.headline)
                                .foregroundColor(.secondary)
                            
                            HStack {
                                Image(systemName: "magnifyingglass")
                                    .foregroundColor(.secondary)
                                
                                TextField("Search books", text: $searchText)
                                    .textFieldStyle(RoundedBorderTextFieldStyle())
                            }
                            
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
                                    BookListItemView(book: book)
                                }
                            }
                        }
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(12)
                    }
                    .padding()
                }
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
            
            NavigationView {
                ProfileView()
            }
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

