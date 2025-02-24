//
//  LibrariansView.swift
//  LMS_Infosys_T4
//
//  Created by Shravan Rajput on 18/02/25.
//

import SwiftUI

struct LibrariansView: View {
    @StateObject private var viewModel = LibrarianViewModel()
    @State private var showingAddLibrarian = false
    @State private var selectedLibrarian: Librarian?

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
                    List {
                        ForEach(viewModel.librarians) { librarian in
                            LibrarianRowView(librarian: librarian)
                                .onTapGesture {
                                    selectedLibrarian = librarian
                                }
                        }
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
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(librarian.name)
                .font(.headline)
            Text(librarian.email)
                .font(.subheadline)
                .foregroundColor(.secondary)
            HStack {
                Image(systemName: "phone")
                Text(librarian.phoneNumber)
                    .font(.caption)
            }
            .foregroundColor(.secondary)
        }
        .padding(.vertical, 8)
    }
}
