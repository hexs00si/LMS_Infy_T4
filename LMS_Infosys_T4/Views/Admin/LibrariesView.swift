import SwiftUI

struct LibrariesView: View {
    @StateObject private var viewModel = LibrariesViewModel()
    @State private var showingAddLibrary = false
    @State private var selectedLibrary: Library?
    @State private var searchText = ""
    @State private var activeFilter: LibraryFilter = .all
    
    var filteredLibraries: [Library] {
        var result = viewModel.libraries
        
        // Apply active status filter
        switch activeFilter {
        case .all:
            // Show all libraries, no filtering needed
            break
        case .active:
            result = result.filter { $0.isActive }
        case .inactive:
            result = result.filter { !$0.isActive }
        }
        
        // Apply search text filter if not empty
        if !searchText.isEmpty {
            result = result.filter { library in
                library.name.localizedCaseInsensitiveContains(searchText) ||
                library.location.localizedCaseInsensitiveContains(searchText)
            }
        }
        
        return result
    }
    
    var body: some View {
        NavigationView {
            Group {
                if viewModel.isLoading {
                    ProgressView("Loading libraries...")
                } else if viewModel.libraries.isEmpty {
                    EmptyLibraryView()
                } else {
                    libraryList
                }
            }
            .navigationTitle("Libraries")
            .navigationBarItems(trailing: addButton)
            .sheet(isPresented: $showingAddLibrary) {
                AddLibraryView(viewModel: viewModel)
            }
            .sheet(item: $selectedLibrary) { library in
                LibraryDetailView(library: library, viewModel: viewModel)
            }
            .overlay(
                Group {
                    if let error = viewModel.error {
                        ErrorBanner(message: error) {
                            viewModel.error = nil
                        }
                    }
                }
            )
        }
        .navigationBarBackButtonHidden(true)
    }
    
    private var libraryList: some View {
        VStack {
            HStack {
                Spacer()
                Text("Total Libraries: \(filteredLibraries.count)")
                    .font(.system(size: 14))
                    .foregroundColor(.gray)
                    .padding(.horizontal)
            }
            
            //            HStack {
            //                SearchBar(text: $searchText, placeholder: "Search by name or location...")
            //                Picker("Filter", selection: $activeFilter) {
            //                    Text("All").tag(LibraryFilter.all)
            //                    Text("Active").tag(LibraryFilter.active)
            //                    Text("Inactive").tag(LibraryFilter.inactive)
            //                }
            //                .pickerStyle(SegmentedPickerStyle())
            //                .padding(.horizontal)
            //                .padding(.top, 8)
            //            }
            HStack {
                SearchBar(text: $searchText, placeholder: "Search by name or location...")
                FilterButton(activeFilter: $activeFilter)
            }
            .padding(.horizontal)
            .padding(.top, 8)
            
            ScrollView {
                LazyVStack(spacing: 16) {
                    ForEach(filteredLibraries) { library in
                        LibraryRowView(
                            library: library,
                            viewModel: viewModel
                        ) {
                            selectedLibrary = library
                        }
                        .padding(.horizontal)
                    }
                }
                .padding(.vertical)
            }
            .background(Color(.systemGroupedBackground))
            .refreshable {
                viewModel.fetchLibraries()
            }
        }
    }
    
    private var addButton: some View {
        Button(action: { showingAddLibrary = true }) {
            Image(systemName: "plus")
                .font(.system(size: 16, weight: .semibold))
        }
    }
}

struct ErrorBanner: View {
    let message: String
    let dismiss: () -> Void
    
    var body: some View {
        VStack {
            HStack {
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundColor(.white)
                Text(message)
                    .foregroundColor(.white)
                Spacer()
                Button(action: dismiss) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.white)
                }
            }
            .padding()
            .background(Color.red)
            .cornerRadius(8)
            .padding()
            
            Spacer()
        }
    }
}

enum LibraryFilter {
    case all
    case active
    case inactive
    
    var title: String {
        switch self {
        case .all: return "All Libraries"
        case .active: return "Active Libraries"
        case .inactive: return "Inactive Libraries"
        }
    }
}

struct FilterButton: View {
    @Binding var activeFilter: LibraryFilter
    
    var body: some View {
        Menu {
            Button(action: { activeFilter = .all }) {
                HStack {
                    Text(LibraryFilter.all.title)
                    if activeFilter == .all {
                        Spacer()
                        Image(systemName: "checkmark")
                    }
                }
            }
            
            Button(action: { activeFilter = .active }) {
                HStack {
                    Text(LibraryFilter.active.title)
                    if activeFilter == .active {
                        Spacer()
                        Image(systemName: "checkmark")
                    }
                }
            }
            
            Button(action: { activeFilter = .inactive }) {
                HStack {
                    Text(LibraryFilter.inactive.title)
                    if activeFilter == .inactive {
                        Spacer()
                        Image(systemName: "checkmark")
                    }
                }
            }
        } label: {
            Image(systemName: "line.3.horizontal.decrease.circle.fill")
                .font(.title2)
                .foregroundColor(.primary)
        }
    }
}


#Preview {
    LibrariesView()
}
