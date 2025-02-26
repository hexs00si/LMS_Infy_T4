import SwiftUI

import SwiftUI

struct UserProfileView: View {
    @State private var user: User?
    @State private var library: Library?
    @State private var issuedBooks: [IssuedBook] = []
    @State private var fineAmount: Float = 0.0
    
    var body: some View {
        NavigationView {
            List {
                Section(header: Text("User Information")) {
                    HStack {
                        Text("Name")
                            .foregroundColor(.gray)
                        Spacer()
                        Text(user?.name ?? "John Doe")
                    }
                    
                    HStack {
                        Text("Email")
                            .foregroundColor(.gray)
                        Spacer()
                        Text(user?.email ?? "john.doe@example.com")
                    }
                    
                    HStack {
                        Text("Organization ID")
                            .foregroundColor(.gray)
                        Spacer()
                        Text(user?.id ?? "N/A")
                    }
                }
                
                Section(header: Text("Library Info")) {
                    HStack {
                        Text("Books Borrowed")
                            .foregroundColor(.gray)
                        Spacer()
                        Text("\(user?.currentlyIssuedCount ?? 0)")
                            .fontWeight(.bold)
                            .foregroundColor(.blue)
                    }
                    
                    HStack {
                        Text("Current Fine")
                            .foregroundColor(.gray)
                        Spacer()
                        Text("$\(String(format: "%.2f", fineAmount))")
                            .fontWeight(.bold)
                            .foregroundColor(.red)
                    }
                }
            }
            .navigationTitle("Profile")
            .onAppear {
                calculateFine()
            }
        }
    }
    
    func calculateFine() {
        guard let user = user else { return }
        let currentDate = Date()
        let calendar = Calendar.current
        var totalFine: Float = 0.0
        
        for book in issuedBooks where !book.isReturned {
            let daysOverdue = calendar.dateComponents([.day], from: book.issueDate, to: currentDate).day ?? 0
            if daysOverdue > library?.loanDuration ?? 14 {
                totalFine += Float(daysOverdue - (library?.loanDuration ?? 14)) * (library?.finePerDay ?? 2.0)
            }
        }
        fineAmount = totalFine
    }
}


#Preview {
    UserProfileView()
}
