import SwiftUI
import CodeScanner
import Firebase

struct IssueBookView: View {
    @ObservedObject var viewModel: LibraryViewModel
    @Environment(\.presentationMode) var presentationMode
    
    // Book Details (Read-Only)
    @State private var bookID = ""
    @State private var title = ""
    @State private var author = ""
    @State private var isbn = ""
    @State private var publishYear = ""
    @State private var genre = ""
    @State private var description = ""
    @State private var coverImageURL = ""
    @State private var availableCopies = 0
    
    // UI States
    @State private var showingScanner = false
    @State private var isLoading = false
    @State private var errorMessage: String? = nil
    
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
                        fetchBookDetails(bookID: bookID)
                    }
                    .disabled(bookID.isEmpty || isLoading)
                }
                
                // Cover Image Section
                if !coverImageURL.isEmpty, let url = URL(string: coverImageURL) {
                    Section(header: Text("Cover Image").textCase(.uppercase)) {
                        AsyncImage(url: url) { image in
                            image.resizable()
                                .scaledToFit()
                                .frame(height: 200)
                                .clipShape(RoundedRectangle(cornerRadius: 8))
                        } placeholder: {
                            ProgressView()
                        }
                    }
                }
                
                // Basic Information Section (Read-Only)
                Section(header: Text("Basic Information").textCase(.uppercase)) {
                    ReadOnlyTextField(label: "Title", text: title)
                    ReadOnlyTextField(label: "Author", text: author)
                    ReadOnlyTextField(label: "ISBN", text: isbn)
                    ReadOnlyTextField(label: "Publication Year", text: publishYear)
                    ReadOnlyTextField(label: "Genre", text: genre)
                    ReadOnlyTextField(label: "Available Copies", text: "\(availableCopies)")
                }
                
                // Description Section
                Section(header: Text("Description").textCase(.uppercase)) {
                    Text(description.isEmpty ? "No description available." : description)
                        .font(.body)
                        .foregroundColor(description.isEmpty ? .gray : .primary)
                }
            }
            .navigationTitle("Issue Book")
            .navigationBarTitleDisplayMode(.inline)
            .sheet(isPresented: $showingScanner) {
                CodeScannerView(codeTypes: [.qr], completion: handleScan)
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
    
    private func fetchBookDetails(bookID: String) {
        isLoading = true
        errorMessage = nil
        
        let db = Firestore.firestore()
        db.collection("books").document(bookID).getDocument { document, error in
            DispatchQueue.main.async {
                isLoading = false
                if let document = document, document.exists {
                    let data = document.data()
                    title = data?["title"] as? String ?? ""
                    author = data?["author"] as? String ?? ""
                    isbn = data?["isbn"] as? String ?? ""
                    publishYear = "\(data?["publishYear"] as? Int ?? 0)"
                    genre = data?["genre"] as? String ?? ""
                    description = data?["description"] as? String ?? ""
                    availableCopies = data?["availableCopies"] as? Int ?? 0
                    coverImageURL = data?["coverImage"] as? String ?? ""
                } else {
                    errorMessage = "Book not found."
                }
            }
        }
    }
    
    private func handleScan(result: Result<ScanResult, ScanError>) {
        showingScanner = false
        switch result {
        case .success(let scanResult):
            bookID = scanResult.string
            fetchBookDetails(bookID: scanResult.string)
        case .failure:
            errorMessage = "Scanning failed"
        }
    }
}

// Read-Only Text Field for Displaying Book Details
struct ReadOnlyTextField: View {
    let label: String
    let text: String
    
    var body: some View {
        HStack {
            Text(label + ":")
                .foregroundColor(.gray)
            Spacer()
            Text(text.isEmpty ? "-" : text)
                .multilineTextAlignment(.trailing)
        }
    }
}