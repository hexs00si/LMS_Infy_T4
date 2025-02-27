import SwiftUI

struct ReportsView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @Binding var isPresented: Bool
    @State private var showingSignOutAlert = false
    @StateObject private var viewModel = ReportsViewModel()
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // Top Issued Books Section
                    HStack {

                        Text("Most Issued Books")
                            .font(.title2)
                            .fontWeight(.bold)
                        
                        Spacer()
                    }
                    .padding(.horizontal)
                    .padding(.top)
                    
                    if viewModel.isLoading {
                        ProgressView("Loading top books...")
                            .padding()
                    } else if let error = viewModel.error {
                        Text("Error: \(error)")
                            .foregroundColor(.red)
                            .padding()
                    } else if viewModel.topIssuedBooks.isEmpty {
                        VStack(spacing: 12) {
                            Image(systemName: "book.closed")
                                .font(.system(size: 40))
                                .foregroundColor(.gray)
                                .padding()
                            
                            Text("No book issue data available yet")
                                .font(.headline)
                                .foregroundColor(.gray)
                            
                            Text("Data will appear once books start being issued")
                                .font(.subheadline)
                                .foregroundColor(.gray.opacity(0.8))
                                .multilineTextAlignment(.center)
                                .padding(.horizontal)
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                    } else {
                        VStack(spacing: 12) {
                            ForEach(Array(viewModel.topIssuedBooks.enumerated()), id: \.element.id) { index, book in
                                TopBookCard(book: book, rank: index + 1)
                                    .padding(.horizontal)
                            }
                        }
                    }
                    
                    Spacer(minLength: 30)
                }
            }
            .navigationTitle("Reports")
            .navigationBarItems(trailing:
                Button(action: {
                    showingSignOutAlert = true
                }) {
                    Image(systemName: "rectangle.portrait.and.arrow.right")
                        .font(.system(size: 20))
                        .foregroundColor(.blue)
                }
            )
            .alert("Sign Out", isPresented: $showingSignOutAlert) {
                Button("Cancel", role: .cancel) { }
                Button("Sign Out", role: .destructive) {
                    Task {
                        await authViewModel.signOut()
                    }
                }
            } message: {
                Text("Are you sure you want to sign out?")
            }
            .refreshable {
                viewModel.fetchTopIssuedBooks()
            }
        }
    }
}

struct ReportsView_Previews: PreviewProvider {
    static var previews: some View {
        ReportsView(isPresented: .constant(true))
            .environmentObject(AuthViewModel())
    }
}
