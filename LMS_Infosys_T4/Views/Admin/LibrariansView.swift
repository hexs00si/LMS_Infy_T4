import SwiftUI

struct LibrariansView: View {
    @StateObject private var viewModel = LibrarianViewModel()
    @State private var showingAddLibrarian = false
    @State private var selectedLibrarian: Librarian?
    @State private var searchText = ""

    var filteredLibrarians: [Librarian] {
//        filterItems(items: viewModel.librarians, searchText: searchText, keyPath: \.name)
        if searchText.isEmpty {
            return viewModel.librarians
        } else {
            return viewModel.librarians.filter { librarian in
                librarian.name.localizedCaseInsensitiveContains(searchText) ||
                librarian.email.localizedCaseInsensitiveContains(searchText)
            }
        }
    }
    
    var body: some View {
        NavigationView {
            Group {
                if viewModel.librarians.isEmpty {
                    ContentUnavailableView(
                        "No Librarians",
                        systemImage: "person.2.slash",
                        description: Text("Start by adding your first librarian")
                    )
                } else {
                    VStack {
                        HStack {
                            Spacer()
                            Text("Total Librarians: \(filteredLibrarians.count)")
                                .font(.system(size: 14))
                                .foregroundColor(.gray)
                                .padding(.horizontal)
                        }
                        SearchBar(text: $searchText, placeholder: "Search by name or email...")
                        ScrollView {
                            LazyVStack(spacing: 16) {
                                ForEach(filteredLibrarians) { librarian in
                                    LibrarianRowView(librarian: librarian)
                                        .onTapGesture {
                                            selectedLibrarian = librarian
                                        }
                                        .padding(.horizontal)
                                }
                            }
                            .padding(.vertical)
                        }
                        .background(Color(.systemGroupedBackground))
                    }
                }
            }
            .navigationTitle("Librarians")
            .toolbar {
                Button(action: {
                    showingAddLibrarian = true
                }) {
                    Image(systemName: "plus")
                }
            }
            .sheet(isPresented: $showingAddLibrarian) {
                AddLibrarianView(viewModel: viewModel) {
                    viewModel.fetchLibrarians() // Refresh the list when a librarian is added
                }
            }
            .sheet(item: $selectedLibrarian) { librarian in
                LibrarianDetailView(librarian: librarian, viewModel: viewModel)
            }
            .onAppear {
                viewModel.fetchLibrarians() // Ensure data is up-to-date when the view appears
            }
        }
    }
}

struct LibrarianRowView: View {
    let librarian: Librarian
    
//    var body: some View {
//        VStack(alignment: .leading, spacing: 4) {
//            Text(librarian.name)
//                .font(.headline)
//            Text(librarian.email)
//                .font(.subheadline)
//                .foregroundColor(.secondary)
//            HStack {
//                Image(systemName: "phone")
//                Text(librarian.phoneNumber)
//                    .font(.caption)
//            }
//            .foregroundColor(.secondary)
//        }
//        .padding(.vertical, 8)
//    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(librarian.name)
                .font(.system(size: 18, weight: .semibold))
            HStack {
                Image(systemName: "envelope")
                    .font(.system(size: 14))
                    .foregroundColor(.gray)
                Text(librarian.email)
                    .font(.system(size: 15))
                    .foregroundColor(.gray)
            }
            HStack {
                Image(systemName: "phone")
                    .font(.system(size: 14))
                    .foregroundColor(.gray)
                Text(librarian.phoneNumber)
                    .font(.system(size: 15))
                    .foregroundColor(.gray)
            }
            .foregroundColor(.secondary)
        }
        .padding(.vertical, 16)
        .padding(.horizontal, 20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white)
                .shadow(
                    color: Color.black.opacity(0.08),
                    radius: 8,
                    x: 0,
                    y: 4
                )
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.gray.opacity(0.1), lineWidth: 1)
        )
    }
}


#Preview {
    LibrariansView()
}
