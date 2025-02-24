import SwiftUI

struct BookDetailsView: View {
    let book: Book
    
    var body: some View {
        ScrollView {
            VStack(alignment: .center, spacing: 16) {
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
                    
                    Text(book.availabilityStatus.description)
                        .font(.caption)
                        .padding(10)
                        .background(book.availabilityStatus == .available ? Color.green : Color.red)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                        .padding()
                }
                
                Text(book.title)
                    .font(.title)
                    .fontWeight(.bold)
                    .padding(.horizontal)
                
                Text("by \(book.author)")
                    .font(.subheadline)
                    .foregroundColor(.gray)
                    .padding(.horizontal)
                
                HStack {
                    ForEach(book.genre.split(separator: ",").map { String($0) }, id: \.self) { category in
                        Text(category)
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
                        Text("\(book.publishYear)")
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
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(8)
                .padding(.horizontal)
                
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
                
                Button(action: {
                    print("Issue Book tapped")
                }) {
                    Text("Issue Book")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.black)
                        .foregroundColor(.white)
                        .cornerRadius(12)
                }
                .padding(.horizontal)
            }
            .navigationTitle("Book Details")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

struct BookDetailsView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            BookDetailsView(book: Book(
                libraryID: "123",
                addedByLibrarian: "Librarian1",
                title: "SwiftUI for Beginners",
                author: "John Doe",
                isbn: "978-3-16-148410-0",
                availabilityStatus: .available,
                publishYear: 2023,
                genre: "Programming, Swift",
                coverImage: nil,
                description: "A beginner-friendly guide to SwiftUI development.",
                quantity: 10,
                availableCopies: 5
            ))
        }
    }
}
