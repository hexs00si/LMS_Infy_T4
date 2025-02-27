import SwiftUI
import FirebaseFirestore

struct BookDetailView: View {
    let book: Book
    @Environment(\.dismiss) private var dismiss
    @State private var libraryName: String = "Loading..."
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Book cover and basic info
                HStack(alignment: .top, spacing: 20) {
                    // Book cover
                    if let coverImage = book.getCoverImage() {
                        Image(uiImage: coverImage)
                            .resizable()
                            .scaledToFit()
                            .frame(width: 120, height: 180)
                            .cornerRadius(8)
                            .shadow(radius: 2)
                    } else {
                        Image(systemName: "book")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 120, height: 180)
                            .padding()
                            .background(Color.gray.opacity(0.1))
                            .cornerRadius(8)
                    }
                    
                    // Basic book details
                    VStack(alignment: .leading, spacing: 8) {
                        Text(book.title)
                            .font(.title2)
                            .fontWeight(.bold)
                            .fixedSize(horizontal: false, vertical: true)
                        
                        Text("by \(book.author)")
                            .font(.headline)
                            .foregroundColor(.secondary)
                        
                        HStack {
                            Text("ISBN:")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                            Text(book.isbn)
                                .font(.subheadline)
                        }
                        
                        HStack {
                            Text("Published:")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                            Text("\(book.publishYear)")
                                .font(.subheadline)
                        }
                    }
                }
                .padding()
//                .background(Color.white)
                .cornerRadius(12)
                .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
                
                // Stats section
                VStack(alignment: .leading, spacing: 15) {
                    Text("Book Statistics")
                        .font(.headline)
                        .padding(.bottom, 5)
                    
                    // Issue count
                    BookStatRow(
                        title: "Total Times Issued",
                        value: "\(book.bookIssueCount)",
                        icon: "repeat.circle.fill",
                        color: .blue
                    )
                    
                    // Availability
                    BookStatRow(
                        title: "Current Status",
                        value: book.availabilityStatus.description,
                        icon: book.availabilityStatus == .available ? "checkmark.circle.fill" : "xmark.circle.fill",
                        color: book.availabilityStatus == .available ? .green : .red
                    )
                    
                    // Available copies
                    BookStatRow(
                        title: "Available Copies",
                        value: "\(book.availableCopies) of \(book.quantity)",
                        icon: "books.vertical.fill",
                        color: .orange
                    )
                    
                    // Genre
                    BookStatRow(
                        title: "Genre",
                        value: book.genre,
                        icon: "tag.fill",
                        color: .purple
                    )
                    
                    // Library
                    BookStatRow(
                        title: "Library",
                        value: libraryName,
                        icon: "building.2.fill",
                        color: .indigo
                    )
                }
                .padding()
//                .background(Color.white)
                .cornerRadius(12)
                .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
                
                // Description section
                VStack(alignment: .leading, spacing: 10) {
                    Text("Description")
                        .font(.headline)
                    
                    Text(book.description)
                        .font(.body)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding()
//                .background(Color.white)
                .cornerRadius(12)
                .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
            }
            .padding()
        }
        .navigationTitle("Book Details")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: {
                    dismiss()
                }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.gray)
                }
            }
        }
        .background(Color(.systemGray6).ignoresSafeArea())
        .onAppear {
            fetchLibraryName()
        }
    }
    
    private func fetchLibraryName() {
        let db = Firestore.firestore()
        
        db.collection("libraries").document(book.libraryID).getDocument { snapshot, error in
            if let error = error {
                print("Error fetching library: \(error.localizedDescription)")
                libraryName = "Unknown Library"
                return
            }
            
            guard let snapshot = snapshot, snapshot.exists else {
                libraryName = "Unknown Library"
                return
            }
            
            if let name = snapshot.data()?["name"] as? String {
                libraryName = name
            } else {
                libraryName = "Unknown Library"
            }
        }
    }
}

struct BookStatRow: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(color)
                .frame(width: 30)
            
            Text(title)
                .foregroundColor(.secondary)
            
            Spacer()
            
            Text(value)
                .fontWeight(.semibold)
        }
    }
}

