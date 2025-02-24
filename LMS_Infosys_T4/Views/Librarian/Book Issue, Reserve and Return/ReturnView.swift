import SwiftUI

struct ReturnView: View {
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    
                    // Section Header
                    Text("Current Reservations")
                        .font(.title2)
                        .bold()
                        .padding(.horizontal)

                    // Scan Book QR Button
                    Button(action: {
                        // Handle scan action
                    }) {
                        VStack {
                            Image(systemName: "qrcode.viewfinder")
                                .font(.system(size: 40))
                                .foregroundColor(.blue)
                            Text("Scan Book Barcode/QR")
                                .foregroundColor(.gray)
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color(UIColor.systemGray6))
                        .cornerRadius(12)
                    }
                    .padding(.horizontal)

                    // Book Details Card
                    VStack(alignment: .leading, spacing: 10) {
                        HStack {
                            Image(systemName: "book.fill")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 50, height: 70)
                                .foregroundColor(.blue)
                                .padding(.trailing, 10)
                            
                            VStack(alignment: .leading, spacing: 4) {
                                Text("The Library Book")
                                    .font(.headline)
                                Text("Susan Orlean")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                                Text("ISBN: 978-1-4767-4018-8")
                                    .font(.footnote)
                                    .foregroundColor(.gray)
                                
                                HStack {
                                    Label("Overdue by 3 days", systemImage: "exclamationmark.triangle.fill")
                                        .foregroundColor(.red)
                                }
                                Text("Fine: $1.50")
                                    .font(.footnote)
                                    .foregroundColor(.red)
                            }
                            
                            Spacer()
                        }
                        .padding()
                        .background(Color(.systemBackground))
                        .cornerRadius(12)
                        .shadow(radius: 2)
                    }
                    .padding(.horizontal)

                    // Confirm Return Button
                    Button("Confirm Return") {
                        // Handle return confirmation
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.blue)
                    .frame(maxWidth: .infinity)
                    .padding(.horizontal)

                    // Book Cover Image Section
                    VStack {
                        Image("book_cover") // Replace with actual image asset name
                            .resizable()
                            .scaledToFit()
                            .frame(width: 150, height: 200)
                            .cornerRadius(8)
                            .shadow(radius: 5)
                        
                        Text("Book Cover")
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                    .frame(maxWidth: .infinity)
                    .padding()

                    // Overdue Books Section
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Overdue Books")
                            .font(.headline)
                            .padding(.horizontal)

                        VStack(spacing: 12) {
                            OverdueBookCard(title: "Dune", author: "Frank Herbert", borrower: "John Smith", overdueDays: 3, fine: 1.50, imageName: "dune")
                            OverdueBookCard(title: "Foundation", author: "Isaac Asimov", borrower: "Sarah Johnson", overdueDays: 5, fine: 2.50, imageName: "foundation")
                        }
                        .padding(.horizontal)
                    }
                }
                .padding(.top)
            }
        }
    }
}

// Overdue Book Card View
struct OverdueBookCard: View {
    let title: String
    let author: String
    let borrower: String
    let overdueDays: Int
    let fine: Double
    let imageName: String
    
    var body: some View {
        HStack {
            Image(imageName)
                .resizable()
                .frame(width: 50, height: 75)
                .cornerRadius(5)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                Text(author)
                    .font(.subheadline)
                    .foregroundColor(.gray)
                Text("Borrowed by: \(borrower)")
                    .font(.footnote)
                    .foregroundColor(.gray)
                
                HStack {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundColor(.red)
                    Text("Overdue by \(overdueDays) days  Fine: $\(String(format: "%.2f", fine))")
                        .foregroundColor(.red)
                        .font(.footnote)
                }
            }
            
            Spacer()
        }
        .padding()
        .background(Color(UIColor.systemGray6))
        .cornerRadius(10)
    }
}

#Preview {
    ReturnView()
}
