//
//  IssueBookView.swift
//  LMS_Infosys_T4
//
//  Created by Dakshdeep Singh on 24/02/25.
//

import SwiftUI
import CodeScanner
import Firebase

struct IssueBookView: View {
    @ObservedObject var viewModel: LibraryViewModel
    @Environment(\.presentationMode) var presentationMode
    
    // Book Details (Read-Only)
    @State private var bookID = ""
    @State private var originalBookID = "" // To store the main book ID (without copy number)
    @State private var title = ""
    @State private var author = ""
    @State private var isbn = ""
    @State private var coverImage = ""
    @State private var libraryID = ""
    @State private var addedByLibrarian = ""
    
    // UI States
    @State private var showingScanner = false
    @State private var isLoading = false
    @State private var showAlert = false
    @State private var alertTitle = ""
    @State private var alertMessage = ""
    @State private var isBookFetched = false
    
    // Check if all required fields are filled
    private var isFormValid: Bool {
        return isBookFetched && !originalBookID.isEmpty && !title.isEmpty && !author.isEmpty && !isbn.isEmpty
    }
    
    var body: some View {
        NavigationView {
            Form {
                // Book ID Section
                Section(header: Text("Book ID").textCase(.uppercase)) {
                    HStack {
                        TextField("Enter Book ID", text: $bookID)
                            .keyboardType(.default)
                            .disabled(isLoading)
                        
                        Button(action: { showingScanner = true }) {
                            Image(systemName: "qrcode.viewfinder")
                                .font(.title2)
                                .foregroundColor(.blue)
                        }
                    }
                    
                    Button("Fetch Book Details") {
                        fetchBookDetails(bookCopyID: bookID)
                    }
                    .disabled(bookID.isEmpty || isLoading)
                }
                
                // Cover Image Section
                if !coverImage.isEmpty, let imageData = Data(base64Encoded: coverImage) {
                    Section(header: Text("Cover Image").textCase(.uppercase)) {
                        if let uiImage = UIImage(data: imageData) {
                            Image(uiImage: uiImage)
                                .resizable()
                                .scaledToFit()
                                .frame(height: 200)
                                .clipShape(RoundedRectangle(cornerRadius: 8))
                        }
                    }
                }
                
                // Basic Information Section (Read-Only)
                Section(header: Text("Basic Information").textCase(.uppercase)) {
                    ReadOnlyTextField(label: "Title", text: title)
                    ReadOnlyTextField(label: "Author", text: author)
                    ReadOnlyTextField(label: "ISBN", text: isbn)
                }
            }
            .navigationTitle("Issue Book")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(
                leading: Button("Cancel") {
                    presentationMode.wrappedValue.dismiss()
                },
                trailing: Button("Issue") {
                    issueBook()
                }
                    .disabled(!isFormValid || isLoading)
            )
            .sheet(isPresented: $showingScanner) {
                CodeScannerView(codeTypes: [.qr], completion: handleScan)
            }
            .alert(alertTitle, isPresented: $showAlert) {
                Button("OK") {
                    if alertTitle == "Success" {
                        presentationMode.wrappedValue.dismiss()
                    }
                }
            } message: {
                Text(alertMessage)
            }
            .overlay {
                if isLoading {
                    ProgressView()
                        .scaleEffect(1.5)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .background(Color.black.opacity(0.2))
                }
            }
        }
    }
    
    private func fetchBookDetails(bookCopyID: String) {
        // Extract book ID before the "-" if it's a barcode format
        let components = bookCopyID.components(separatedBy: "-")
        let mainBookID = components.first ?? bookCopyID
        
        isLoading = true
        isBookFetched = false
        
        let db = Firestore.firestore()
        db.collection("books").document(mainBookID).getDocument { document, error in
            DispatchQueue.main.async {
                isLoading = false
                
                if let document = document, document.exists {
                    let data = document.data()
                    
                    // Store essential fields
                    originalBookID = mainBookID
                    title = data?["title"] as? String ?? ""
                    author = data?["author"] as? String ?? ""
                    isbn = data?["isbn"] as? String ?? ""
                    coverImage = data?["coverImage"] as? String ?? ""
                    libraryID = data?["libraryID"] as? String ?? ""
                    addedByLibrarian = data?["addedByLibrarian"] as? String ?? ""
                    
                    isBookFetched = true
                } else {
                    alertTitle = "Not Found"
                    alertMessage = "Book not found. Please check the ID and try again."
                    showAlert = true
                }
            }
        }
    }
    
    private func issueBook() {
        guard isFormValid else {
            alertTitle = "Error"
            alertMessage = "Please fetch a valid book first."
            showAlert = true
            return
        }
        
        isLoading = true
        
        // Create a minimal book object with required fields
        let book = Book(
            id: originalBookID,
            libraryID: libraryID,
            addedByLibrarian: addedByLibrarian,
            title: title,
            author: author,
            isbn: isbn,
            availabilityStatus: .available,
            publishYear: 0, // Default value
            genre: "", // Default value
            coverImage: coverImage,
            description: "", // Default value
            quantity: 1, // Default value
            availableCopies: 1 // Default value
        )
        
        Task {
            do {
                try await viewModel.requestBook(book: book, copyID: bookID)
                
                await MainActor.run {
                    isLoading = false
                    alertTitle = "Success"
                    alertMessage = "Book successfully issued."
                    showAlert = true
                }
            } catch {
                await MainActor.run {
                    isLoading = false
                    alertTitle = "Error"
                    alertMessage = "Failed to issue book: \(error.localizedDescription)"
                    showAlert = true
                }
            }
        }
    }
    
    private func handleScan(result: Result<ScanResult, ScanError>) {
        showingScanner = false
        switch result {
        case .success(let scanResult):
            bookID = scanResult.string
            fetchBookDetails(bookCopyID: scanResult.string)
        case .failure:
            alertTitle = "Scan Failed"
            alertMessage = "Unable to read QR code. Please try again or enter the book ID manually."
            showAlert = true
        }
    }
}
