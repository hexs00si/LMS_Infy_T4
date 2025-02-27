//
//  LibrarianProfileView.swift
//  LMS_Infosys_T4
//
//  Created by Gaganveer Bawa on 27/02/25.
//
import SwiftUI
import FirebaseAuth
import FirebaseFirestore

struct LibrarianProfileView: View {
    @State private var name: String = ""
    @State private var email: String = ""
    @State private var libraryName: String = ""
    @State private var libraryLocation: String = ""
    @State private var loanDuration: Int = 0
    @State private var finePerDay: Int = 0
    @State private var maxBooksPerUser: Int = 0
    @State private var lastUpdated: String = ""
    @State private var libraryID: String = ""
    
    @State private var showingSignOutConfirmation = false
    @State private var showingResetPasswordAlert = false
    @State private var resetPasswordMessage: String = ""
    
    @State private var showingCSVDownloadAlert = false
    @State private var csvDownloadMessage: String = ""
    @State private var isDownloading: Bool = false
    
    var body: some View {
        NavigationView {
            List {
                Section(header: Text("Librarian Information")) {
                    HStack {
                        Text("Name")
                            .foregroundColor(.gray)
                        Spacer()
                        Text(name)
                    }
                    
                    HStack {
                        Text("Email")
                            .foregroundColor(.gray)
                        Spacer()
                        Text(email)
                    }
                }
                
                Section(header: Text("Library Information")) {
                    HStack {
                        Text("Library Name")
                            .foregroundColor(.gray)
                        Spacer()
                        Text(libraryName)
                    }
                    
                    HStack {
                        Text("Location")
                            .foregroundColor(.gray)
                        Spacer()
                        Text(libraryLocation)
                    }
                    
                    HStack {
                        Text("Loan Duration")
                            .foregroundColor(.gray)
                        Spacer()
                        Text("\(loanDuration) days")
                    }
                    
                    HStack {
                        Text("Fine Per Day")
                            .foregroundColor(.gray)
                        Spacer()
                        Text("$\(finePerDay)")
                    }
                    
                    HStack {
                        Text("Max Books Per User")
                            .foregroundColor(.gray)
                        Spacer()
                        Text("\(maxBooksPerUser)")
                    }
                    
                    HStack {
                        Text("Last Updated")
                            .foregroundColor(.gray)
                        Spacer()
                        Text(lastUpdated)
                    }
                }
                
                Section {
                    Button(action: {
                        showingCSVDownloadAlert = true
                    }) {
                        HStack {
                            Text("Download Books CSV")
                                .foregroundColor(.blue)
                            
                            if isDownloading {
                                Spacer()
                                ProgressView()
                            }
                        }
                    }
                    .disabled(isDownloading)
                }
                
                Section {
                    Button(action: {
                        showingResetPasswordAlert = true
                    }) {
                        Text("Reset Password")
                            .foregroundColor(.blue)
                    }
                    
                    Button(action: {
                        showingSignOutConfirmation = true
                    }) {
                        Text("Sign Out")
                            .foregroundColor(.red)
                    }
                }
            }
            .navigationTitle("Librarian Profile")
            .onAppear {
                fetchLibrarianData()
            }
            .alert("Reset Password", isPresented: $showingResetPasswordAlert) {
                Button("Send Reset Email", action: sendPasswordResetEmail)
                Button("Cancel", role: .cancel) { }
            } message: {
                Text("A password reset email will be sent to \(email).")
            }
            .alert("Sign Out", isPresented: $showingSignOutConfirmation) {
                Button("Cancel", role: .cancel) { }
                Button("Sign Out", role: .destructive, action: signOut)
            } message: {
                Text("Are you sure you want to sign out?")
            }
            .alert("Password Reset", isPresented: .constant(!resetPasswordMessage.isEmpty)) {
                Button("OK", role: .cancel) {
                    resetPasswordMessage = "" // Clear the message after showing
                }
            } message: {
                Text(resetPasswordMessage)
            }
            .alert("Download Books CSV", isPresented: $showingCSVDownloadAlert) {
                Button("Download", action: downloadCSV)
                Button("Cancel", role: .cancel) { }
            } message: {
                Text("A CSV file with all books in your library will be generated and downloaded.")
            }
            .alert("CSV Download", isPresented: .constant(!csvDownloadMessage.isEmpty)) {
                Button("OK", role: .cancel) {
                    csvDownloadMessage = "" // Clear the message after showing
                }
            } message: {
                Text(csvDownloadMessage)
            }
        }
    }
    
    func downloadCSV() {
        guard !libraryID.isEmpty else {
            csvDownloadMessage = "Error: Library ID not found. Please try again."
            return
        }
        
        isDownloading = true
        
        Task {
            do {
                let csvData = try await generateBooksCSVData()
                let csvURL = try saveCSVToFile(csvData: csvData)
                
                // Switch to main thread for UI operations
                await MainActor.run {
                    shareCSVFile(csvURL: csvURL)
                    isDownloading = false
                }
            } catch {
                await MainActor.run {
                    csvDownloadMessage = "Error downloading CSV: \(error.localizedDescription)"
                    isDownloading = false
                }
            }
        }
    }
    
    func generateBooksCSVData() async throws -> String {
        // Get the books for the current library
        guard !libraryID.isEmpty else {
            throw NSError(domain: "LibraryError", code: 404, userInfo: [NSLocalizedDescriptionKey: "Library ID not found"])
        }
        
        let db = Firestore.firestore()
        let booksCollection = db.collection("books").whereField("libraryID", isEqualTo: libraryID)
        let booksSnapshot = try await booksCollection.getDocuments()
        
        // CSV Header - updated to match your actual Firestore fields
        var csvString = "Title,Author,ISBN,Genre,Publish Year,Description,Available Copies,Quantity,Status\n"
        
        // Add each book as a row
        for document in booksSnapshot.documents {
            let bookData = document.data()
            
            let title = bookData["title"] as? String ?? ""
            let author = bookData["author"] as? String ?? ""
            let isbn = bookData["isbn"] as? String ?? ""
            let genre = bookData["genre"] as? String ?? ""
            let publishYear = bookData["publishYear"] as? Int ?? 0
            let description = bookData["description"] as? String ?? ""
            let availableCopies = bookData["availableCopies"] as? Int ?? 0
            let quantity = bookData["quantity"] as? Int ?? 0
            let status = bookData["availabilityStatus"] as? Int ?? 0
            
            // Escape any commas in string fields with quotes
            let escapedTitle = escapeCSVField(title)
            let escapedAuthor = escapeCSVField(author)
            let escapedGenre = escapeCSVField(genre)
            let escapedDescription = escapeCSVField(description)
            
            csvString += "\(escapedTitle),\(escapedAuthor),\(isbn),\(escapedGenre),\(publishYear),\(escapedDescription),\(availableCopies),\(quantity),\(status)\n"
        }
        
        return csvString
    }
    // Helper function to escape CSV fields with quotes if they contain commas
    func escapeCSVField(_ field: String) -> String {
        if field.contains(",") {
            return "\"\(field)\""
        }
        return field
    }
    
    func saveCSVToFile(csvData: String) throws -> URL {
        let fileManager = FileManager.default
        let tempDirectoryURL = fileManager.temporaryDirectory
        let fileURL = tempDirectoryURL.appendingPathComponent("library_books.csv")
        
        try csvData.write(to: fileURL, atomically: true, encoding: .utf8)
        
        // Debug prints
        print("CSV file saved at: \(fileURL)")
        print("File exists: \(FileManager.default.fileExists(atPath: fileURL.path))")
        print("File size: \(try? FileManager.default.attributesOfItem(atPath: fileURL.path)[.size] as? Int ?? 0) bytes")
        
        return fileURL
    }
    
    func shareCSVFile(csvURL: URL) {
        // Create a UIActivityViewController to handle sharing
        let activityVC = UIActivityViewController(
            activityItems: [csvURL],
            applicationActivities: nil
        )
        
        // Present the share sheet
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let rootVC = windowScene.windows.first?.rootViewController else {
            print("Failed to get root view controller")
            csvDownloadMessage = "Error: Could not display share options"
            return
        }
        
        // For iPad support
        if let popoverController = activityVC.popoverPresentationController {
            popoverController.sourceView = rootVC.view
            popoverController.sourceRect = CGRect(x: UIScreen.main.bounds.midX, y: UIScreen.main.bounds.midY, width: 0, height: 0)
            popoverController.permittedArrowDirections = []
        }
        
        DispatchQueue.main.async {
            rootVC.present(activityVC, animated: true) {
                print("Activity view controller presented successfully")
            }
        }
    }
    
    func fetchLibrarianData() {
        guard let currentUser = Auth.auth().currentUser else { return }
        
        let db = Firestore.firestore()
        db.collection("librarians").document(currentUser.uid).getDocument { document, error in
            if let document = document, document.exists {
                let data = document.data()
                self.name = data?["name"] as? String ?? "N/A"
                self.email = data?["email"] as? String ?? "N/A"
                
                // Fetch library details
                if let libraryID = data?["libraryID"] as? String {
                    self.libraryID = libraryID // Store the library ID
                    
                    db.collection("libraries").document(libraryID).getDocument { libraryDocument, libraryError in
                        if let libraryDocument = libraryDocument, libraryDocument.exists {
                            let libraryData = libraryDocument.data()
                            self.libraryName = libraryData?["name"] as? String ?? "N/A"
                            self.libraryLocation = libraryData?["location"] as? String ?? "N/A"
                            self.loanDuration = libraryData?["loanDuration"] as? Int ?? 0
                            self.finePerDay = libraryData?["finePerDay"] as? Int ?? 0
                            self.maxBooksPerUser = libraryData?["maxBooksPerUser"] as? Int ?? 0
                            
                            // Format the last updated date
                            if let timestamp = libraryData?["lastUpdated"] as? Timestamp {
                                let dateFormatter = DateFormatter()
                                dateFormatter.dateStyle = .medium
                                dateFormatter.timeStyle = .short
                                self.lastUpdated = dateFormatter.string(from: timestamp.dateValue())
                            } else {
                                self.lastUpdated = "N/A"
                            }
                        }
                    }
                }
            } else {
                print("Document does not exist")
            }
        }
    }
    
    func sendPasswordResetEmail() {
        guard let currentUser = Auth.auth().currentUser else { return }
        
        Auth.auth().sendPasswordReset(withEmail: currentUser.email!) { error in
            if let error = error {
                resetPasswordMessage = "Failed to send reset email: \(error.localizedDescription)"
            } else {
                resetPasswordMessage = "A password reset email has been sent to \(currentUser.email!)."
            }
        }
    }
    
    func signOut() {
        do {
            try Auth.auth().signOut()
            // Navigate to login screen or handle sign-out
        } catch let signOutError as NSError {
            print("Error signing out: \(signOutError.localizedDescription)")
        }
    }
}

#Preview {
    LibrarianProfileView()
}
