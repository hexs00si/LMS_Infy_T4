//
//  MemberHomeView.swift
//  LMS
//
//  Created by Udayveer Chhina on 13/02/25.
//

import SwiftUI

struct MemberHomeView: View {
    @State private var selectedCategory: String = "All Books"
    @State private var searchText = ""
    @State private var showingGenreFilter = false
    @StateObject private var viewModel = LibraryViewModel() // Persistent ViewModel

    let categories = ["All Books", "Fiction", "Non-Fiction", "Academic", "Science", "History", "Biography", "Mystery", "Fantasy", "Self-Help"]
    
    var filteredBooks: [Book] {
        let categoryFilteredBooks = viewModel.books.filter { book in
            selectedCategory == "All Books" || book.genre.contains(selectedCategory)
        }
        
        if !searchText.isEmpty {
            return searchBooks(items: categoryFilteredBooks, searchText: searchText)
        }
        
        return categoryFilteredBooks
    }

    var body: some View {
        NavigationView {
            VStack {
                // Search bar for searching books
                SearchBar(text: $searchText, placeholder: "Search books...")
                
                ScrollView {
                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
                        ForEach(filteredBooks) { book in
                            BookCard(book: book)
                        }
                    }
                    .padding()
                }
            }
            .navigationTitle(selectedCategory)
            .navigationBarTitleDisplayMode(.large)
            .navigationBarItems(
                trailing: HStack {
                    Button(action: {
                        print("Bell icon tapped")
                    }) {
                        Image(systemName: "bell.fill")
                            .font(.title2)
                            .foregroundColor(.black)
                    }
                    
                    Button(action: {
                        showingGenreFilter.toggle()
                    }) {
                        Image(systemName: "line.3.horizontal.decrease.circle.fill")
                            .font(.title2)
                            .foregroundColor(.black)
                    }
                }
            )
            .sheet(isPresented: $showingGenreFilter) {
                GenreFilterView(selectedCategory: $selectedCategory)
            }
            .onAppear {
                viewModel.fetchBooks() // Fetch books when the view appears
            }
        }
    }
}

struct GenreFilterView: View {
    @Binding var selectedCategory: String
    @Environment(\.presentationMode) var presentationMode
    
    let genres = ["All Books", "Fiction", "Non-Fiction", "Academic", "Science", "History", "Biography", "Mystery", "Fantasy", "Self-Help"]
    
    var body: some View {
        NavigationView {
            List(genres, id: \.self) { genre in
                Button(action: {
                    selectedCategory = genre
                }) {
                    HStack {
                        Text(genre)
                        if genre == selectedCategory {
                            Spacer()
                            Image(systemName: "checkmark")
                        }
                    }
                }
            }
            .navigationTitle("Select Genre")
            .navigationBarItems(trailing: Button("Done") {
                // Close the sheet after selection
                selectedCategory = selectedCategory
                
                presentationMode.wrappedValue.dismiss()
            })
        }
    }
}

struct BookCard: View {
    let book: Book
    
    var body: some View {
        NavigationLink(destination: BookDetailsView(book: book)) {
            VStack(alignment: .center) {
                if let coverImage = book.getCoverImage() {
                    // Display the actual cover image if available
                    Image(uiImage: coverImage)
                        .resizable()
                        .scaledToFill()
                        .frame(width: 150, height: 160)
                        .clipped()
                        .cornerRadius(12)
                } else {
                    // Fallback to system image if no cover image is available
                    Image(systemName: "book")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 150, height: 160)
                        .foregroundColor(.gray)
                        .cornerRadius(12)
                }
                
                Text(book.title)
                    .font(.headline)
                    .lineLimit(2)
                    .frame(maxWidth: .infinity, alignment: .leading)
                
                Text(book.author)
                    .font(.subheadline)
                    .foregroundColor(.gray)
                    .frame(maxWidth: .infinity, alignment: .leading)
                
                Text(book.availabilityStatus.description)  // Using the description property
                    .font(.caption)
                    .padding(4)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .background(book.availabilityStatus == .available ? Color.green.opacity(0.2) : Color.red.opacity(0.2))
                    .foregroundColor(book.availabilityStatus == .available ? .green : .red)
                    .cornerRadius(6)
            }
            .padding()
            .frame(width: 170, height: 275)
            .background(Color.white)
            .cornerRadius(12)
            .shadow(radius: 2)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

//
//struct BookCard: View {
//    let book: Book
//    
//    var body: some View {
//        NavigationLink(destination: BookDetailsView(book: book)) {
//            VStack(alignment: .center) {
//                Image(systemName: book.coverImage ?? "book")
//                    .resizable()
//                    .scaledToFill()
//                    .frame(width: 150, height: 160)
//                    .clipped()
//                    .cornerRadius(12)
//                
//                Text(book.title)
//                    .font(.headline)
//                    .lineLimit(2)
//                    .frame(maxWidth: .infinity, alignment: .leading)
//                
//                Text(book.author)
//                    .font(.subheadline)
//                    .foregroundColor(.gray)
//                    .frame(maxWidth: .infinity, alignment: .leading)
//                
//                Text("\(book.availabilityStatus)")
//                    .font(.caption)
//                    .padding(4)
//                    .frame(maxWidth: .infinity, alignment: .center)
//                    .background(book.availabilityStatus == AvailabilityStatus.available ? Color.green.opacity(0.2) : Color.red.opacity(0.2))
//                    .foregroundColor(book.availabilityStatus == AvailabilityStatus.available ? .green : .red)
//                    .cornerRadius(6)
//            }
//            .padding()
//            .frame(width: 170, height: 275)
//            .background(Color.white)
//            .cornerRadius(12)
//            .shadow(radius: 2)
//        }
//        .buttonStyle(PlainButtonStyle()) // Removes default navigation link styling
//    }
//}

struct MainTabView: View {
    init() {
        let appearance = UITabBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = UIColor.white  // Ensures the background is white
        appearance.stackedLayoutAppearance.selected.iconColor = .black
        appearance.stackedLayoutAppearance.selected.titleTextAttributes = [.foregroundColor: UIColor.black]
        appearance.stackedLayoutAppearance.normal.iconColor = .lightGray
        appearance.stackedLayoutAppearance.normal.titleTextAttributes = [.foregroundColor: UIColor.lightGray]
        
        UITabBar.appearance().standardAppearance = appearance
        UITabBar.appearance().scrollEdgeAppearance = appearance
    }

    var body: some View {
        TabView {
            MemberHomeView()
                .tabItem {
                    Label("Home", systemImage: "house.fill")
                }

            Text("Bookshelf")
                .tabItem {
                    Label("Bookshelf", systemImage: "books.vertical.fill")
                }

            Text("Bookmarks")
                .tabItem {
                    Label("Bookmarks", systemImage: "bookmark.fill")
                }

            Text("Profile")
                .tabItem {
                    Label("Profile", systemImage: "person.fill")
                }
        }
    }
}

#Preview {
    MainTabView()
}
