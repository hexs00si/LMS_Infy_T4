//
//  UserProfileView.swift
//  LMS_Infosys_T4
//
//  Created by Gaganveer Bawa on 26/02/25.
//


import SwiftUI
import FirebaseAuth
import FirebaseFirestore

struct UserProfileView: View {
    @State private var name: String = ""
    @State private var email: String = ""
    @State private var gender: String = ""
    @State private var issuedCount: Int = 0
    @State private var joinDate: String = ""
    @State private var organizationID: String = ""
    @State private var phoneNumber: String = ""
    
    @State private var showingNameUpdateAlert = false
    @State private var newName: String = ""
    
    var body: some View {
        NavigationView {
            List {
                Section(header: Text("User Information")) {
                    HStack {
                        Text("Name")
                            .foregroundColor(.gray)
                        Spacer()
                        Text(name)
                    }
                    .onTapGesture {
                        showingNameUpdateAlert = true
                    }
                    
                    HStack {
                        Text("Email")
                            .foregroundColor(.gray)
                        Spacer()
                        Text(email)
                    }
                    
                    HStack {
                        Text("Gender")
                            .foregroundColor(.gray)
                        Spacer()
                        Text(gender)
                    }
                    
                    HStack {
                        Text("Organization ID")
                            .foregroundColor(.gray)
                        Spacer()
                        Text(organizationID)
                    }
                    
                    HStack {
                        Text("Phone Number")
                            .foregroundColor(.gray)
                        Spacer()
                        Text(phoneNumber)
                    }
                    
                    HStack {
                        Text("Join Date")
                            .foregroundColor(.gray)
                        Spacer()
                        Text(joinDate)
                    }
                }
                
                Section(header: Text("Library Info")) {
                    HStack {
                        Text("Books Borrowed")
                            .foregroundColor(.gray)
                        Spacer()
                        Text("\(issuedCount)")
                            .fontWeight(.bold)
                            .foregroundColor(.blue)
                    }
                }
                
                Section {
                    Button(action: signOut) {
                        Text("Sign Out")
                            .foregroundColor(.red)
                    }
                }
            }
            .navigationTitle("Profile")
            .onAppear {
                fetchUserData()
            }
            .alert("Update Name", isPresented: $showingNameUpdateAlert) {
                TextField("Enter new name", text: $newName)
                Button("Update", action: updateName)
                Button("Cancel", role: .cancel) { }
            }
        }
    }
    
    func fetchUserData() {
        guard let currentUser = Auth.auth().currentUser else { return }
        
        let db = Firestore.firestore()
        db.collection("members").document(currentUser.uid).getDocument { document, error in
            if let document = document, document.exists {
                let data = document.data()
                self.name = data?["name"] as? String ?? "N/A"
                self.email = data?["email"] as? String ?? "N/A"
                self.gender = data?["gender"] as? String ?? "N/A"
                self.issuedCount = data?["issuedCount"] as? Int ?? 0
                self.organizationID = data?["organizationID"] as? String ?? "N/A"
                self.phoneNumber = data?["phoneNumber"] as? String ?? "N/A"
                
                // Format the join date
                if let timestamp = data?["joinDate"] as? Timestamp {
                    let dateFormatter = DateFormatter()
                    dateFormatter.dateStyle = .medium
                    dateFormatter.timeStyle = .short
                    self.joinDate = dateFormatter.string(from: timestamp.dateValue())
                } else {
                    self.joinDate = "N/A"
                }
            } else {
                print("Document does not exist")
            }
        }
    }
    
    func updateName() {
        guard let currentUser = Auth.auth().currentUser else { return }
        
        let db = Firestore.firestore()
        db.collection("members").document(currentUser.uid).updateData(["name": newName]) { error in
            if let error = error {
                print("Error updating name: \(error.localizedDescription)")
            } else {
                fetchUserData() // Refresh user data
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
    UserProfileView()
}