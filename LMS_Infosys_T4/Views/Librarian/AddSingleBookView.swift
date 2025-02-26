//
//  AddSingleBookView.swift
//  libraraian 1
//
//  Created by Kinshuk Garg on 14/02/25.
////
//  AddSingleBookView.swift
//  libraraian 1
//
//  Created by Kinshuk Garg on 14/02/25.
//

import SwiftUI
import CodeScanner

// Update the Google Books API Response Models
struct GoogleBooksResponse: Codable {
    let items: [BookItem]
}

struct BookItem: Codable {
    let volumeInfo: VolumeInfo
}

struct VolumeInfo: Codable {
    let title: String
    let authors: [String]?
    let publishedDate: String?
    let description: String?
    let categories: [String]?
    let imageLinks: ImageLinks?
}

struct ImageLinks: Codable {
    let thumbnail: String
}

import SwiftUI
import CodeScanner
import FirebaseAuth
import PhotosUI
import FirebaseFirestore

struct AddSingleBookView: View {
    @ObservedObject var viewModel: LibraryViewModel
    @Environment(\.presentationMode) var presentationMode
    
    // Form Fields
    @State private var title = ""
    @State private var author = ""
    @State private var isbn = ""
    @State private var publishYear = ""
    @State private var genre = ""
    @State private var description = ""
    @State private var coverImageURL = ""
    @State private var quantity = 1
    @State private var edition = ""
    
    // UI States
    @State private var showingScanner = false
    @State private var showingImageSourceOptions = false
    @State private var showingCamera = false
    @State private var showingPhotoLibrary = false
    @State private var selectedImage: UIImage? = nil
    @State private var isLoading = false
    @State private var errorMessage: String? = nil
    
    // Current user and library info
    @State private var currentLibrarianID = ""
    @State private var currentLibraryID = ""
    
    var isSaveDisabled: Bool {
        title.isEmpty || author.isEmpty || Int(publishYear) == nil ||
        isbn.isEmpty || selectedImage == nil || currentLibrarianID.isEmpty
    }
    
    var body: some View {
        NavigationView {
            Form {
                // ISBN Section
                Section(header: Text("ISBN").textCase(.uppercase)) {
                    HStack {
                        TextField("Enter ISBN", text: $isbn)
                            .keyboardType(.numberPad)
                        
                        Button(action: { showingScanner = true }) {
                            Image(systemName: "barcode.viewfinder")
                                .font(.title2)
                                .foregroundColor(.blue)
                        }
                    }
                    
                    Button("Fetch Book Details") {
                        fetchBookDetails(isbn: isbn)
                    }
                    .disabled(isbn.isEmpty)
                }
                
                // Cover Image Section
                Section(header: Text("Cover Image").textCase(.uppercase)) {
                    if let selectedImage = selectedImage {
                        Image(uiImage: selectedImage)
                            .resizable()
                            .scaledToFit()
                            .frame(height: 200)
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                    }
                    
                    Button("Select Cover Image") {
                        showingImageSourceOptions = true
                    }
                }
                
                // Basic Information Section
                Section(header: Text("Basic Information").textCase(.uppercase)) {
                    TextField("Title", text: $title)
                    TextField("Author", text: $author)
                    TextField("Publication Year", text: $publishYear)
                        .keyboardType(.numberPad)
                    TextField("Genre", text: $genre)
                    TextField("Edition", text: $edition)
                    Stepper("Quantity: \(quantity)", value: $quantity, in: 1...100)
                }
                
                // Description Section
                Section(header: Text("Description").textCase(.uppercase)) {
                    TextEditor(text: $description)
                        .frame(minHeight: 100)
                }
            }
            .navigationTitle("Add New Book")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(
                trailing: Button("Save") {
                    Task {
                        await saveBook()
                    }
                }
                    .disabled(isSaveDisabled)
            )
            .onAppear {
                getCurrentLibrarianInfo()
            }
            .sheet(isPresented: $showingScanner) {
                CodeScannerView(
                    codeTypes: [.ean13],
                    completion: handleScan
                )
            }
            .fullScreenCover(isPresented: $showingCamera) {
                ImagePicker(sourceType: .camera, selectedImage: $selectedImage)
            }
            .sheet(isPresented: $showingPhotoLibrary) {
                ImagePicker(sourceType: .photoLibrary, selectedImage: $selectedImage)
            }
            .actionSheet(isPresented: $showingImageSourceOptions) {
                ActionSheet(
                    title: Text("Choose Image Source"),
                    buttons: [
                        .default(Text("Take Photo")) { showingCamera = true },
                        .default(Text("Choose from Photos")) { showingPhotoLibrary = true },
                        .cancel()
                    ]
                )
            }
            .alert("Error", isPresented: .constant(errorMessage != nil)) {
                Button("OK") { errorMessage = nil }
            } message: {
                Text(errorMessage ?? "")
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
    
    private func getCurrentLibrarianInfo() {
        guard let currentUser = Auth.auth().currentUser else {
            errorMessage = "No authenticated librarian found"
            return
        }
        
        // Set the current librarian's ID
        currentLibrarianID = currentUser.uid
        
        // Fetch the librarian's library ID from Firestore
        let db = Firestore.firestore()
        db.collection("librarians")
            .document(currentUser.uid)
            .getDocument { document, error in
                if let document = document, document.exists {
                    currentLibraryID = document.data()?["libraryID"] as? String ?? ""
                } else {
                    errorMessage = "Could not fetch librarian information"
                }
            }
    }
    
    private func convertImageToBase64(_ image: UIImage) -> String? {
        guard let imageData = image.jpegData(compressionQuality: 0.1) else { return nil }
        return imageData.base64EncodedString()
    }
    
    private func saveBook() async {
        guard let yearInt = Int(publishYear) else { return }
        
        isLoading = true
        defer { isLoading = false }
        
        // Convert image to base64 if available
        var imageBase64: String? = nil
        if let image = selectedImage {
            imageBase64 = convertImageToBase64(image)
        }
        
        let newBook = Book(
            libraryID: currentLibraryID,
            addedByLibrarian: currentLibrarianID,
            title: title,
            author: author,
            isbn: isbn,
            availabilityStatus: .available,
            publishYear: yearInt,
            genre: genre,
            coverImage: imageBase64,  // Now passing the base64 string
            description: description,
            quantity: quantity,
            bookIssueCount: 0,
            availableCopies: quantity
        )
        
        do {
            try await viewModel.addBook(newBook)
            presentationMode.wrappedValue.dismiss()
        } catch {
            errorMessage = error.localizedDescription
        }
    }
    
    private func handleScan(result: Result<ScanResult, ScanError>) {
        showingScanner = false
        switch result {
        case .success(let scanResult):
            isbn = scanResult.string
            fetchBookDetails(isbn: scanResult.string)
        case .failure:
            errorMessage = "Scanning failed"
        }
    }
    
    private func fetchBookDetails(isbn: String) {
        guard let url = URL(string: "https://www.googleapis.com/books/v1/volumes?q=isbn:\(isbn)") else {
            errorMessage = "Invalid URL"
            return
        }
        
        URLSession.shared.dataTask(with: url) { data, response, error in
            if let error = error {
                DispatchQueue.main.async {
                    errorMessage = error.localizedDescription
                }
                return
            }
            
            guard let data = data else {
                DispatchQueue.main.async {
                    errorMessage = "No data received"
                }
                return
            }
            
            do {
                let result = try JSONDecoder().decode(GoogleBooksResponse.self, from: data)
                if let book = result.items.first?.volumeInfo {
                    DispatchQueue.main.async {
                        title = book.title
                        author = book.authors?.joined(separator: ", ") ?? "Unknown Author"
                        publishYear = book.publishedDate?.prefix(4).description ?? ""
                        genre = book.categories?.first ?? "Unknown"
                        description = book.description ?? "No description available."
                    }
                }
            } catch {
                DispatchQueue.main.async {
                    errorMessage = "Error decoding book data"
                }
            }
        }.resume()
    }
}
