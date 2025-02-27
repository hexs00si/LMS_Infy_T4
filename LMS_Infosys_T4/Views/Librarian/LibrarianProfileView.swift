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
    
    @State private var showingSignOutConfirmation = false
    @State private var showingResetPasswordAlert = false
    @State private var resetPasswordMessage: String = ""
    
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
