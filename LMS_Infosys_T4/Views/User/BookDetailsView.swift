import SwiftUI

struct BookDetailsView: View {
    let book: Book
    
    var body: some View {
        Text("Book Details here")
//        ScrollView {
//            VStack(alignment: .center, spacing: 16) {
//                ZStack(alignment: .topTrailing) {
//                    Image(book.image)
//                        .resizable()
//                        .scaledToFit()
//                        .frame(height: 250)
//                        .cornerRadius(12)
//                        .padding()
//                    
//                    Text(book.status)
//                        .font(.caption)
//                        .padding(10)
//                        .background(book.status == "Available" ? Color.green : Color.red)
//                        .foregroundColor(.black)
//                        .cornerRadius(8)
//                        .padding()
//                }
//                
//                Text(book.title)
//                    .font(.title)
//                    .fontWeight(.bold)
//                    .padding(.horizontal)
//                
//                Text("by \(book.author)")
//                    .font(.subheadline)
//                    .foregroundColor(.gray)
//                    .padding(.horizontal)
//                
//                .padding(.horizontal)
//                
//                HStack {
//                    ForEach(book.category, id: \..self) { category in
//                        Text(category)
//                            .font(.caption)
//                            .padding(8)
//                            .background(Color(.systemGray5))
//                            .cornerRadius(8)
//                    }
//                }
//                .padding(.horizontal)
//                
//                VStack(alignment: .leading, spacing: 8) {
//                    HStack {
//                        Text("ISBN")
//                            .font(.subheadline)
//                            .foregroundColor(.gray)
//                        Spacer()
//                        Text(book.isbn)
//                            .font(.subheadline)
//                    }
//                    
//                    HStack {
//                        Text("Publisher")
//                            .font(.subheadline)
//                            .foregroundColor(.gray)
//                        Spacer()
//                        Text(book.publisher)
//                            .font(.subheadline)
//                    }
//                    
//                    HStack {
//                        Text("Published Date")
//                            .font(.subheadline)
//                            .foregroundColor(.gray)
//                        Spacer()
//                        Text(book.publishedDate)
//                            .font(.subheadline)
//                    }
//                }
//                .padding()
//                .background(Color(.systemGray6))
//                .cornerRadius(8)
//                .padding(.horizontal)
//                
//                Text("Description")
//                    .font(.headline)
//                    .padding(.horizontal)
//                
//                Text(book.description)
//                    .font(.body)
//                    .foregroundColor(.gray)
//                    .padding(.horizontal)
//                
//                .font(.footnote)
//                .padding()
//                .background(Color(.systemGray6))
//                .cornerRadius(8)
//                .padding(.horizontal)
//                
//                Button(action: {
//                    print("Issue Book tapped")
//                }) {
//                    Text("Issue Book")
//                        .font(.headline)
//                        .frame(maxWidth: .infinity)
//                        .padding()
//                        .background(Color.black)
//                        .foregroundColor(.white)
//                        .cornerRadius(12)
//                }
//                .padding(.horizontal)
//                
////                Text("You May Also Like")
////                    .font(.headline)
////                    .padding(.horizontal)
////                
////                ScrollView(.horizontal, showsIndicators: false) {
////                    HStack(spacing: 16) {
////                        ForEach(BookData.books.prefix(3)) { similarBook in
////                            BookCard(book: similarBook)
////                        }
////                    }
////                    .padding(.horizontal)
////                }
//            }
//            .navigationTitle("Book Details")
//            .navigationBarTitleDisplayMode(.inline)
//        }
    }
}

struct BookDetailsView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
//            BookDetailsView(book: BookData.books.first!)
        }
    }
}
