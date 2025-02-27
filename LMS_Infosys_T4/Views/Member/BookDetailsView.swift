import SwiftUI

struct BookDetailsView: View {
    let book: Book
    @ObservedObject var viewModel: LibraryViewModel
    @State private var isLoading = false
    @State private var showAlert = false
    @State private var alertMessage = ""
    @State private var libraryName: String = "Loading..."
    @State private var selectedReadingStatus: String? = nil
    @State private var showReadingOptions = false
    
    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .bottom) {
                ScrollView {
                    VStack(alignment: .center, spacing: 16) {
                        BookCoverView(book: book)
                        BookMetadataView(book: book, libraryName: $libraryName)
                        BookDescriptionView(book: book)
                    }
                    .frame(minHeight: geometry.size.height)
                }
                
                ReserveButtonView(
                    book: book,
                    viewModel: viewModel,
                    isLoading: $isLoading,
                    showAlert: $showAlert,
                    alertMessage: $alertMessage
                )
            }
            .navigationTitle("Book Details")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(trailing: menuButton)
            .alert(isPresented: $showAlert) {
                Alert(title: Text("Library"), message: Text(alertMessage), dismissButton: .default(Text("OK")))
            }
            .onAppear {
                Task {
                    do {
                        libraryName = try await viewModel.fetchLibraryDetails(byId: book.libraryID)
                    } catch {
                        libraryName = "Error fetching details"
                        print(book.libraryID)
                        print("Error fetching library details: \(error.localizedDescription)")
                    }
                }
            }
        }
    }
    
    private var menuButton: some View {
        Menu {
            Button(action: { updateReadingStatus("Want to Read") }) {
                HStack {
                    if selectedReadingStatus == "Want to Read" { Image(systemName: "checkmark") }
                    Text("Want to Read")
                }
            }
            Button(action: { updateReadingStatus("Currently Reading") }) {
                HStack {
                    if selectedReadingStatus == "Currently Reading" { Image(systemName: "checkmark") }
                    Text("Currently Reading")
                }
            }
            Button(action: { updateReadingStatus("Completed") }) {
                HStack {
                    if selectedReadingStatus == "Completed" { Image(systemName: "checkmark") }
                    Text("Completed")
                }
            }
        } label: {
            Image(systemName: "ellipsis.circle")
                .imageScale(.large)
        }
    }
    
    private func updateReadingStatus(_ status: String) {
        selectedReadingStatus = status
        Task {
            do {
                switch status {
                case "Want to Read":
                    try await viewModel.addToWishlist(book: book)
                case "Currently Reading":
                    try await viewModel.markAsCurrentlyReading(book: book)
                case "Completed":
                    try await viewModel.markAsCompleted(book: book)
                default:
                    break
                }
                alertMessage = "Marked as \(status)"
                showAlert = true
            } catch {
                alertMessage = "Error marking as \(status): \(error.localizedDescription)"
                showAlert = true
            }
        }
    }
}



struct BookCoverView: View {
    let book: Book
    
    var body: some View {
        ZStack(alignment: .topTrailing) {
            if let uiImage = book.getCoverImage() {
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFit()
                    .frame(height: 250)
                    .cornerRadius(12)
                    .padding()
            } else {
                Image(systemName: "book") // Placeholder image
                    .resizable()
                    .scaledToFit()
                    .frame(height: 250)
                    .cornerRadius(12)
                    .padding()
            }
            
            // Update status display based on availableCopies
            Text(book.availableCopies > 0 ? "Available" : "Unavailable")
                .font(.caption)
                .padding(10)
                .background(book.availableCopies > 0 ? Color.green : Color.red)
                .foregroundColor(.white)
                .cornerRadius(8)
                .padding()
        }
    }
}

struct ReserveButtonView: View {
    let book: Book
    @ObservedObject var viewModel: LibraryViewModel
    @Binding var isLoading: Bool
    @Binding var showAlert: Bool
    @Binding var alertMessage: String
    
    var body: some View {
        VStack {
            Divider() // Adds a separator above the button
            Button(action: {
                isLoading = true
                Task {
                    do {
                        if let copyID = try await viewModel.getFirstAvailableCopyID(for: book) {
                            try await viewModel.createReservation(book: book, copyID: copyID)
                            alertMessage = "Book reserved successfully!"
                            showAlert = true
                        } else {
                            alertMessage = "No available copies to reserve."
                            showAlert = true
                        }
                    } catch {
                        alertMessage = "Error reserving book: \(error.localizedDescription)"
                        showAlert = true
                    }
                    isLoading = false
                }
            }) {
                if isLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.black)
                        .cornerRadius(12)
                } else {
                    Text("Reserve Book")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(book.availableCopies > 0 ? Color.black : Color.gray)
                        .foregroundColor(.white)
                        .cornerRadius(12)
                }
            }
            .disabled(isLoading || book.availableCopies == 0) // Disable button if no copies are available
            .padding(.horizontal)
            .padding(.bottom, 10)
        }
        .background(Color.white)
    }
}

struct BookDescriptionView: View {
    let book: Book
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Description")
                .font(.headline)
                .padding(.horizontal)
            
            Text(book.description)
                .font(.body)
                .foregroundColor(.gray)
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(8)
                .padding(.horizontal)
        }
    }
}

struct BookMetadataView: View {
    let book: Book
    @Binding var libraryName: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(book.title)
                .font(.title)
                .fontWeight(.bold)
                .padding(.horizontal)
            
            Text("by \(book.author)")
                .font(.subheadline)
                .foregroundColor(.gray)
                .padding(.horizontal)
            
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 100))], spacing: 8) {
                ForEach(book.genre.split(separator: ",").map { String($0) }, id: \ .self) { category in
                    Text(category.trimmingCharacters(in: .whitespacesAndNewlines))
                        .font(.caption)
                        .padding(8)
                        .background(Color(.systemGray5))
                        .cornerRadius(8)
                }
            }
            .padding(.horizontal)
            
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("ISBN")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                    Spacer()
                    Text(book.isbn)
                        .font(.subheadline)
                }
                
                HStack {
                    Text("Published Year")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                    Spacer()
                    Text(String(describing: book.publishYear))
                        .font(.subheadline)
                }
                
                HStack {
                    Text("Total Copies")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                    Spacer()
                    Text("\(book.quantity)")
                        .font(.subheadline)
                }
                
                HStack {
                    Text("Available Copies")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                    Spacer()
                    Text("\(book.availableCopies)")
                        .font(.subheadline)
                }
                
                HStack {
                    Text("Library")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                    Spacer()
                    Text(libraryName)
                        .font(.subheadline)
                }
            }
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(8)
            .padding(.horizontal)
        }
    }
}
