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
    
    // Categories to choose from
    let categories = ["All Books", "Fiction", "Non-Fiction", "Academic", "Science", "History", "Biography", "Mystery", "Fantasy", "Self-Help"]
    
    // Filtered books based on selected category
    var filteredBooks: [BookDetails] {
        if selectedCategory == "All Books" {
            return BookData.books.filter { book in
                // Filter by searchText (case-insensitive)
                searchText.isEmpty || book.title.lowercased().contains(searchText.lowercased())
            }
        } else {
            return BookData.books.filter { book in
                book.category.contains(selectedCategory) && (searchText.isEmpty || book.title.lowercased().contains(searchText.lowercased()))
            }
        }
    }

    var body: some View {
        NavigationView {
            VStack {
                // Search bar for searching books
                SearchBar(text: $searchText, placeholder: "Search books...")
                
                // Book display grid
                ScrollView {
                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
                        ForEach(filteredBooks) { book in
                            BookCard(book: book)
                        }
                    }
                    .padding()
                }
            }
//            .navigationTitle("Library")
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
        }
    }
}

struct GenreFilterView: View {
    @Binding var selectedCategory: String
    @Environment(\.presentationMode) var presentationMode
    
    let genres = ["All", "Fiction", "Non-Fiction", "Academic", "Science", "History", "Biography", "Mystery", "Fantasy", "Self-Help"]
    
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
    let book: BookDetails
    
    var body: some View {
        NavigationLink(destination: BookDetailsView(book: book)) {
            VStack(alignment: .center) {
                Image(book.image)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 150, height: 160)
                    .clipped()
                    .cornerRadius(12)
                
                Text(book.title)
                    .font(.headline)
                    .lineLimit(2)
                    .frame(maxWidth: .infinity, alignment: .leading)
                
                Text(book.author)
                    .font(.subheadline)
                    .foregroundColor(.gray)
                    .frame(maxWidth: .infinity, alignment: .leading)
                
                Text(book.status)
                    .font(.caption)
                    .padding(4)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .background(book.status == "Available" ? Color.green.opacity(0.2) : Color.red.opacity(0.2))
                    .foregroundColor(book.status == "Available" ? .green : .red)
                    .cornerRadius(6)
            }
            .padding()
            .frame(width: 170, height: 275)
            .background(Color.white)
            .cornerRadius(12)
            .shadow(radius: 2)
        }
        .buttonStyle(PlainButtonStyle()) // Removes default navigation link styling
    }
}

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
