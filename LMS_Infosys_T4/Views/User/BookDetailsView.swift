


import SwiftUI

struct BookDetailsView: View {
    let book: Book
    @ObservedObject var viewModel: LibraryViewModel
    @State private var isLoading = false
    @State private var showAlert = false
    @State private var alertMessage = ""
    @State private var libraryName: String = "Loading..."

    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .bottom) { // Keeps the button fixed at the bottom
                ScrollView {
                    VStack(alignment: .center, spacing: 16) {
                        // Book Cover
                        BookCoverView(book: book)

                        // Book Metadata
                        BookMetadataView(book: book)

                        // Book Description
                        BookDescriptionView(book: book)

                        Spacer() // Pushes the button to the bottom
                            .frame(height: 80) // Keeps space for the button
                    }
                    .frame(minHeight: geometry.size.height) // Ensures content fits inside the screen
                }

                // Reserve Button
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

            Text(book.availabilityStatus.description)
                .font(.caption)
                .padding(10)
                .background(book.availabilityStatus == .available ? Color.green : Color.red)
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
                        .background(Color.black)
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
                ForEach(book.genre.split(separator: ",").map { String($0) }, id: \.self) { category in
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
        }
    }
}

//import SwiftUI
//
//struct BookDetailsView: View {
//    let book: Book
//    @ObservedObject var viewModel: LibraryViewModel
//    @State private var isLoading = false
//    @State private var showAlert = false
//    @State private var alertMessage = ""
//
//    var body: some View {
//        GeometryReader { geometry in
//            ZStack(alignment: .bottom) { // Keeps the button fixed at the bottom
//                ScrollView {
//                    VStack(alignment: .center, spacing: 16) {
//                        ZStack(alignment: .topTrailing) {
//                            if let uiImage = book.getCoverImage() {
//                                Image(uiImage: uiImage)
//                                    .resizable()
//                                    .scaledToFit()
//                                    .frame(height: 250)
//                                    .cornerRadius(12)
//                                    .padding()
//                            } else {
//                                Image(systemName: "book") // Placeholder image
//                                    .resizable()
//                                    .scaledToFit()
//                                    .frame(height: 250)
//                                    .cornerRadius(12)
//                                    .padding()
//                            }
//
//                            Text(book.availabilityStatus.description)
//                                .font(.caption)
//                                .padding(10)
//                                .background(book.availabilityStatus == .available ? Color.green : Color.red)
//                                .foregroundColor(.white)
//                                .cornerRadius(8)
//                                .padding()
//                        }
//
//                        Text(book.title)
//                            .font(.title)
//                            .fontWeight(.bold)
//                            .padding(.horizontal)
//
//                        Text("by \(book.author)")
//                            .font(.subheadline)
//                            .foregroundColor(.gray)
//                            .padding(.horizontal)
//
//                        LazyVGrid(columns: [GridItem(.adaptive(minimum: 100))], spacing: 8) {
//                            ForEach(book.genre.split(separator: ",").map { String($0) }, id: \.self) { category in
//                                Text(category.trimmingCharacters(in: .whitespacesAndNewlines))
//                                    .font(.caption)
//                                    .padding(8)
//                                    .background(Color(.systemGray5))
//                                    .cornerRadius(8)
//                            }
//                        }
//                        .padding(.horizontal)
//
//                        VStack(alignment: .leading, spacing: 8) {
//                            HStack {
//                                Text("ISBN")
//                                    .font(.subheadline)
//                                    .foregroundColor(.gray)
//                                Spacer()
//                                Text(book.isbn)
//                                    .font(.subheadline)
//                            }
//
//                            HStack {
//                                Text("Published Year")
//                                    .font(.subheadline)
//                                    .foregroundColor(.gray)
//                                Spacer()
//                                Text("\(book.publishYear)")
//                                    .font(.subheadline)
//                            }
//
//                            HStack {
//                                Text("Total Copies")
//                                    .font(.subheadline)
//                                    .foregroundColor(.gray)
//                                Spacer()
//                                Text("\(book.quantity)")
//                                    .font(.subheadline)
//                            }
//
//                            HStack {
//                                Text("Available Copies")
//                                    .font(.subheadline)
//                                    .foregroundColor(.gray)
//                                Spacer()
//                                Text("\(book.availableCopies)")
//                                    .font(.subheadline)
//                            }
//                        }
//                        .padding()
//                        .background(Color(.systemGray6))
//                        .cornerRadius(8)
//                        .padding(.horizontal)
//
//                        Text("Description")
//                            .font(.headline)
//                            .padding(.horizontal)
//
//                        Text(book.description)
//                            .font(.body)
//                            .foregroundColor(.gray)
//                            .padding()
//                            .background(Color(.systemGray6))
//                            .cornerRadius(8)
//                            .padding(.horizontal)
//                        
//                        Spacer() // Pushes the button to the bottom
//                            .frame(height: 80) // Keeps space for the button
//                    }
//                    .frame(minHeight: geometry.size.height) // Ensures content fits inside the screen
//                }
//                
//                // Button fixed at the bottom
//                               VStack {
//                                   Divider() // Adds a separator above the button
//                                   Button(action: {
//                                       // Reserve book button tapped
//                                       isLoading = true
//                                       Task {
//                                           do {
//                                               // Assuming you have a function to get the first available copy ID
//                                               if let copyID = viewModel.getFirstAvailableCopyID(for: book) {
//                                                   try await viewModel.createReservation(book: book, copyID: copyID)
//                                                   alertMessage = "Book reserved successfully!"
//                                                   showAlert = true
//                                               } else {
//                                                   alertMessage = "No available copies to reserve."
//                                                   showAlert = true
//                                               }
//                                           } catch {
//                                               alertMessage = "Error reserving book: \(error.localizedDescription)"
//                                               showAlert = true
//                                           }
//                                           isLoading = false
//                                       }
//                                   }) {
//                                       if isLoading {
//                                           ProgressView()
//                                               .progressViewStyle(CircularProgressViewStyle(tint: .white))
//                                               .frame(maxWidth: .infinity)
//                                               .padding()
//                                               .background(Color.black)
//                                               .cornerRadius(12)
//                                       } else {
//                                           Text("Reserve Book")
//                                               .font(.headline)
//                                               .frame(maxWidth: .infinity)
//                                               .padding()
//                                               .background(Color.black)
//                                               .foregroundColor(.white)
//                                               .cornerRadius(12)
//                                       }
//                                   }
//                                   .disabled(isLoading || book.availableCopies == 0) // Disable button if no copies are available
//                                   .padding(.horizontal)
//                                   .padding(.bottom, 10)
//                               }
//                               .background(Color.white)
//                           }
//                           .navigationTitle("Book Details")
//                           .navigationBarTitleDisplayMode(.inline)
//                           .alert(isPresented: $showAlert) {
//                               Alert(title: Text("Library"), message: Text(alertMessage), dismissButton: .default(Text("OK")))
//                           }
//                       }
//                   }
//    
//
////                // Button fixed at the bottom
////                VStack {
////                    Divider() // Adds a separator above the button
////                    Button(action: {
//////                        isLoading = true
//////                        Task {
//////                            do {
//////                                try await viewModel.issueBook(book: book)
//////                                alertMessage = "Book reserved successfully!"
//////                                showAlert = true
//////                            } catch {
//////                                alertMessage = "Error reserving book: \(error.localizedDescription)"
//////                                showAlert = true
//////                            }
//////                            isLoading = false
//////                        }
////                        isLoading = false
////                        print("Reserve book button tapped")
////                    }) {
////                        if isLoading {
////                            ProgressView()
////                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
////                                .frame(maxWidth: .infinity)
////                                .padding()
////                                .background(Color.black)
////                                .cornerRadius(12)
////                        } else {
////                            Text("Reserve Book")
////                                .font(.headline)
////                                .frame(maxWidth: .infinity)
////                                .padding()
////                                .background(Color.black)
////                                .foregroundColor(.white)
////                                .cornerRadius(12)
////                        }
////                    }
////                    .disabled(isLoading)
////                    .padding(.horizontal)
////                    .padding(.bottom, 10)
////                }
////                .background(Color.white)
////            }
////            .navigationTitle("Book Details")
////            .navigationBarTitleDisplayMode(.inline)
////            .alert(isPresented: $showAlert) {
////                Alert(title: Text("Library"), message: Text(alertMessage), dismissButton: .default(Text("OK")))
////            }
////        }
////    }
//}
//
//
//struct BookDetailsView_Previews: PreviewProvider {
//    static var previews: some View {
//        NavigationView {
//            BookDetailsView(book: Book(
//                libraryID: "123",
//                addedByLibrarian: "Librarian1",
//                title: "SwiftUI for Beginners",
//                author: "John Doe",
//                isbn: "978-3-16-148410-0",
//                availabilityStatus: .available,
//                publishYear: 2023,
//                genre: "Programming, Swift",
//                coverImage: nil,
//                description: "A beginner-friendly guide to SwiftUI development.",
//                quantity: 10,
//                availableCopies: 5
//            ), viewModel: LibraryViewModel())
//        }
//    }
//}
