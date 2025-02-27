//
//  LibrarianBookDetailsView.swift
//  LMS_Infosys_T4
//
//  Created by Gaganveer Bawa on 27/02/25.
//


import SwiftUI

struct LibrarianBookDetailsView: View {
    let book: Book
    @ObservedObject var viewModel: LibraryViewModel
    @State private var isLoading = false
    @State private var showAlert = false
    @State private var alertMessage = ""
    @State private var libraryName: String = "Loading..."
    @State private var showEditView = false
    @State private var issuedBooks: [BookIssue] = []
    
    var body: some View {
        GeometryReader { geometry in
            ScrollView {
                VStack(alignment: .center, spacing: 16) {
                    // Book Cover
                    BookCoverView(book: book)
                    
                    // Book Metadata
                    BookMetadataView(book: book)
                    
                    // Book Description
                    BookDescriptionView(book: book)
                    
                    // Edit Button
                    Button(action: {
                        showEditView = true
                    }) {
                        Text("Edit Book Info")
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(12)
                    }
                    .padding(.horizontal)
                    
                    // Issued Books Section
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Issued To")
                            .font(.headline)
                            .padding(.horizontal)
                        
                        if issuedBooks.isEmpty {
                            Text("No books issued yet.")
                                .font(.subheadline)
                                .foregroundColor(.gray)
                                .padding()
                        } else {
                            ForEach(issuedBooks) { issue in
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("User ID: \(issue.userId)")
                                        .font(.subheadline)
                                    Text("Issue Date: \(issue.issueDate, formatter: dateFormatter)")
                                        .font(.caption)
                                        .foregroundColor(.gray)
                                    Text("Due Date: \(issue.dueDate, formatter: dateFormatter)")
                                        .font(.caption)
                                        .foregroundColor(.gray)
                                }
                                .padding()
                                .background(Color(.systemGray6))
                                .cornerRadius(8)
                            }
                        }
                    }
                    .padding(.horizontal)
                }
                .frame(minHeight: geometry.size.height)
            }
            .navigationTitle("Book Details")
            .navigationBarTitleDisplayMode(.inline)
            .alert(isPresented: $showAlert) {
                Alert(title: Text("Library"), message: Text(alertMessage), dismissButton: .default(Text("OK")))
            }
            .sheet(isPresented: $showEditView) {
                EditBookView(book: book, viewModel: viewModel)
            }
            .onAppear {
                Task {
                    do {
                        libraryName = try await viewModel.fetchLibraryDetails(byId: book.libraryID)
                        issuedBooks = try await viewModel.fetchIssuedBooks(for: book.id!)
                    } catch {
                        libraryName = "Error fetching details"
                        print("Error fetching library details: \(error.localizedDescription)")
                    }
                }
            }
        }
    }
    
    private var dateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter
    }
}

struct EditBookView: View {
    let book: Book
    @ObservedObject var viewModel: LibraryViewModel
    @State private var quantity: String = ""
    @State private var showAlert = false
    @State private var alertMessage = ""
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Edit Book Quantity")) {
                    TextField("Quantity", text: $quantity)
                        .keyboardType(.numberPad)
                }
            }
            .navigationTitle("Edit Book")
            .navigationBarItems(trailing: Button("Save") {
                saveChanges()
            })
            .alert(isPresented: $showAlert) {
                Alert(title: Text("Library"), message: Text(alertMessage), dismissButton: .default(Text("OK")))
            }
            .onAppear {
                quantity = String(book.quantity)
            }
        }
    }
    
    private func saveChanges() {
        guard let newQuantity = Int(quantity), newQuantity >= book.quantity else {
            alertMessage = "Quantity can only be increased."
            showAlert = true
            return
        }
        
        Task {
            do {
                try await viewModel.updateBookQuantity(bookID: book.id!, newQuantity: newQuantity)
                alertMessage = "Book quantity updated successfully."
                showAlert = true
            } catch {
                alertMessage = "Error updating book quantity: \(error.localizedDescription)"
                showAlert = true
            }
        }
    }
}