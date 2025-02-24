import SwiftUI

struct LibrariesView: View {
    @StateObject private var viewModel = LibrariesViewModel()
    @State private var showingAddLibrary = false
    @State private var selectedLibrary: Library?
    
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
    }
    
    private var libraryList: some View {
        ScrollView {
            LazyVStack(spacing: 16) {
                ForEach(viewModel.libraries) { library in
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



// Preview provider
struct LibrariesView_Previews: PreviewProvider {
    static var previews: some View {
        LibrariesView()
    }
}
