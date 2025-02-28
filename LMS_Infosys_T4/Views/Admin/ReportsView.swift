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
                    // Fines Summary Section
                    VStack(spacing: 16) {
                        HStack {
                            Text("Fines Summary")
                                .font(.title2)
                                .fontWeight(.bold)
                            
                            Spacer()
                        }
//                        .padding(.horizontal)
                        
                        // Fines Collected Card
                        SummaryCard(title: "Total Fines Collected", value: "Rs. \(String(format: "%.2f", viewModel.totalFinesCollected))", iconName: "indianrupeesign.circle", color: .green)

                        // Fines Pending Card
                        SummaryCard(title: "Total Fines Pending", value: "Rs. \(String(format: "%.2f", viewModel.totalFinesPending))", iconName: "exclamationmark.circle", color: .red)
                        
                        // Total Books Card
                        SummaryCard(title: "Total Books", value: "\(viewModel.totalBooks)", iconName: "book.closed", color: .blue)
                    }
                    .padding(.horizontal)
                    
                    // Most Issued Books Section
                    HStack {
                        Text("Most Issued Books")
                            .font(.title2)
                            .fontWeight(.bold)
                        
                        Spacer()
                    }
                    .padding(.horizontal)
//                    .padding(.top)
                    
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
                viewModel.fetchFinesSummary()
            }
            .onAppear {
                viewModel.fetchFinesSummary()
            }
        }
    }
}

// Summary Card Component
struct SummaryCard: View {
    let title: String
    let value: String
    let iconName: String
    let color: Color
    
    var body: some View {
        HStack {
            Image(systemName: iconName)
                .font(.system(size: 24))
                .foregroundColor(color)
                .padding(12)
                .background(color.opacity(0.2))
                .cornerRadius(10)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                Text(value)
                    .font(.title3)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
            }
            
            Spacer()
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(10)
        .shadow(color: Color.black.opacity(0.1), radius: 5)
    }
}

struct ReportsView_Previews: PreviewProvider {
    static var previews: some View {
        ReportsView(isPresented: .constant(true))
            .environmentObject(AuthViewModel())
    }
}
