//
//  LibrariesView.swift
//  LMS_Infosys_T4
//
//  Created by Shravan Rajput on 18/02/25.
//

import SwiftUI

struct LibrariesView: View {
    @StateObject private var viewModel = LibrariesViewModel()
    @State private var showingAddLibrary = false
    @State private var selectedLibrary: Library?
    
    var body: some View {
        NavigationView {
            Group {
                if viewModel.libraries.isEmpty {
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
        }
    }
    
    private var libraryList: some View {
        ScrollView {
            LazyVStack(spacing: 16) {
                ForEach(viewModel.libraries) { library in
                    LibraryRowView(library: library) {
                        selectedLibrary = library
                    }
                    .padding(.horizontal)
                }
            }
            .padding(.vertical)
        }
        .background(Color(.systemGroupedBackground))
    }
    
    private var addButton: some View {
        Button(action: { showingAddLibrary = true }) {
            Image(systemName: "plus")
                .font(.system(size: 16, weight: .semibold))
        }
    }
}

// Preview provider
struct LibrariesView_Previews: PreviewProvider {
    static var previews: some View {
        LibrariesView()
    }
}
