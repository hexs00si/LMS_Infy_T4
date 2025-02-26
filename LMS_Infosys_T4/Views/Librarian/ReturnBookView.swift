//
//  ReturnBookView.swift
//  LMS_Infosys_T4
//
//  Created by Gaganveer Bawa on 26/02/25.
//


import SwiftUI
import CodeScanner
import Firebase

struct ReturnBookView: View {
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
    @State private var userId = ""
    @State private var userName = ""
    @State private var userEmail = ""
    
    // UI States
    @State private var showingScanner = false
    @State private var isLoading = false
    @State private var showAlert = false
    @State private var alertTitle = ""
    @State private var alertMessage = ""
    @State private var isBookFetched = false
    
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
                
                // User Information Section
                Section(header: Text("User Information").textCase(.uppercase)) {
                    ReadOnlyTextField(label: "User ID", text: userId)
                    ReadOnlyTextField(label: "Name", text: userName)
                    ReadOnlyTextField(label: "Email", text: userEmail)
                }
            }
            .navigationTitle("Return Book")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(
                leading: Button("Cancel") {
                    presentationMode.wrappedValue.dismiss()
                },
                trailing: Button("Confirm Return") {
                    confirmReturn()
                }
                .disabled(!isBookFetched || isLoading)
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
                    
                    // Fetch user information
                    fetchUserDetails(bookCopyID: bookCopyID)
                    
                    isBookFetched = true
                } else {
                    alertTitle = "Not Found"
                    alertMessage = "Book not found. Please check the ID and try again."
                    showAlert = true
                }
            }
        }
    }
    
    private func fetchUserDetails(bookCopyID: String) {
        let db = Firestore.firestore()
        db.collection("bookIssues").whereField("bookId", isEqualTo: bookCopyID).getDocuments { snapshot, error in
            if let error = error {
                alertTitle = "Error"
                alertMessage = "Failed to fetch user details: \(error.localizedDescription)"
                showAlert = true
                return
            }
            
            guard let document = snapshot?.documents.first else {
                alertTitle = "Error"
                alertMessage = "No user found for this book."
                showAlert = true
                return
            }
            
            let data = document.data()
            userId = data["userId"] as? String ?? ""
            
            // Fetch user details
            db.collection("members").document(userId).getDocument { userDocument, userError in
                if let userError = userError {
                    alertTitle = "Error"
                    alertMessage = "Failed to fetch user details: \(userError.localizedDescription)"
                    showAlert = true
                    return
                }
                
                if let userData = userDocument?.data() {
                    userName = userData["name"] as? String ?? ""
                    userEmail = userData["email"] as? String ?? ""
                }
            }
        }
    }
    
    private func confirmReturn() {
        isLoading = true
        
        Task {
            do {
                try await viewModel.returnBook(bookCopyID: bookID)
                
                await MainActor.run {
                    isLoading = false
                    alertTitle = "Success"
                    alertMessage = "Book successfully returned."
                    showAlert = true
                }
            } catch {
                await MainActor.run {
                    isLoading = false
                    alertTitle = "Error"
                    alertMessage = "Failed to return book: \(error.localizedDescription)"
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

// Read-Only Text Field for Displaying Book Details
//struct ReadOnlyTextField: View {
//    let label: String
//    let text: String
//    
//    var body: some View {
//        VStack(alignment: .leading) {
//            Text(label + ":")
//                .foregroundColor(.gray)
//            Text(text.isEmpty ? "-" : text)
//                .lineLimit(nil)
//                .multilineTextAlignment(.leading)
//        }
//    }
//}
