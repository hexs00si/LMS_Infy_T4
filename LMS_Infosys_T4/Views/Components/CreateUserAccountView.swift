//
//  SignUpView.swift
//  LMS_Infosys_T4
//
//  Created by Shravan Rajput on 19/02/25.
//
import SwiftUI
import FirebaseAuth
import FirebaseFirestore

struct CreateUserAccountView: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var isPresented: Bool
    @Environment(\.colorScheme) var colorScheme
    
    @State private var name = ""
    @State private var email = ""
    @State private var organizationID = ""
    @State private var selectedGender = ""
    @State private var phoneNumber = ""
    
    @State private var showVerificationScreen = false
    @State private var showAlert = false
    @State private var alertMessage = ""
    @State private var isLoading = false  // Loading state

    let genderOptions = ["Male", "Female", "Other"]
    private let db = Firestore.firestore()

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Create Account")
                .font(.title)
                .bold()
                .padding(.bottom, 8)
            
            VStack(alignment: .leading, spacing: 6) {
                Text("Name")
                    .foregroundColor(.gray)
                TextField("Enter your name", text: $name)
                    .textFieldStyle(.plain)
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(10)
                    .disabled(isLoading)  // Disable during loading
            }
            
            VStack(alignment: .leading, spacing: 6) {
                Text("Email")
                    .foregroundColor(.gray)
                TextField("Enter your email", text: $email)
                    .textFieldStyle(.plain)
                    .keyboardType(.emailAddress)
                    .autocapitalization(.none)
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(10)
                    .disabled(isLoading)
            }
            
            VStack(alignment: .leading, spacing: 6) {
                Text("Organization ID (Optional)")
                    .foregroundColor(.gray)
                TextField("Enter organization ID", text: $organizationID)
                    .textFieldStyle(.plain)
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(10)
                    .disabled(isLoading)
            }
            
            VStack(alignment: .leading, spacing: 6) {
                Text("Gender (Optional)")
                    .foregroundColor(.gray)
                Menu {
                    ForEach(genderOptions, id: \.self) { gender in
                        Button(gender) {
                            selectedGender = gender
                        }
                    }
                } label: {
                    HStack {
                        Text(selectedGender.isEmpty ? "Select gender" : selectedGender)
                            .foregroundColor(selectedGender.isEmpty ? .gray : .primary)
                        Spacer()
                        Image(systemName: "chevron.down")
                            .foregroundColor(.blue)
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(10)
                }
                .disabled(isLoading)
            }
            
            VStack(alignment: .leading, spacing: 6) {
                Text("Phone Number (Optional)")
                    .foregroundColor(.gray)
                TextField("Enter phone number", text: $phoneNumber)
                    .textFieldStyle(.plain)
                    .keyboardType(.phonePad)
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(10)
                    .disabled(isLoading)
            }
            
            Spacer()
            
            // Create Account Button
            Button(action: {
                checkIfEmailExists()
            }) {
                HStack {
                    if isLoading {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    }
                    Text(isLoading ? "Processing..." : "Create Account")
                        .foregroundColor(colorScheme == .dark ? Color.black : Color.white)
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(isLoading ? Color.gray : (colorScheme == .dark ? Color.white : Color.black))
                .cornerRadius(10)
            }
            .disabled(name.isEmpty || email.isEmpty || isLoading)
            
            // Cancel Button
            Button(action: {
                dismiss()
            }) {
                Text("Cancel")
                    .foregroundColor(.red)
                    .frame(maxWidth: .infinity)
            }
            .padding(.top, 8)
            .fullScreenCover(isPresented: $showVerificationScreen) {
                VerificationView(
                    isPresented: $isPresented,
                    email: email,
                    user: User(
                        id: nil,
                        name: name,
                        email: email,
                        password: "",
                        gender: selectedGender == "Select gender" ? "" : selectedGender,
                        phoneNumber: phoneNumber,
                        joinDate: Date(),
                        issuedBooks: [],
                        currentlyIssuedCount: 0
                    ),
                    organizationID: organizationID
                )
            }
            .alert(isPresented: $showAlert) {
                Alert(title: Text("Error"), message: Text(alertMessage), dismissButton: .default(Text("OK")))
            }
        }
        .padding()
    }
    
    // Check if email already exists in Firebase Auth
    private func checkIfEmailExists() {
        isLoading = true  // Start loading
        let authUsersCollection = db.collection("authUsers")
        
        authUsersCollection.whereField("email", isEqualTo: email).getDocuments { snapshot, error in
            if let error = error {
                alertMessage = "Error checking email: \(error.localizedDescription)"
                showAlert = true
                isLoading = false  // Stop loading
                return
            }
            
            if let documents = snapshot?.documents, !documents.isEmpty {
                // Email already exists
                alertMessage = "An account with this email already exists. Please use a different email."
                showAlert = true
                isLoading = false  // Stop loading
            } else {
                // Email does not exist, proceed with OTP
                sendOTP()
            }
        }
    }
    
    // Send OTP if email is unique
    private func sendOTP() {
        OTPCommands.shared.sendOTP(email: email, name: name) { success, errorMessage in
            if success {
                showVerificationScreen = true
            } else {
                alertMessage = "OTP sending failed: \(errorMessage ?? "Unknown error")"
                showAlert = true
            }
            isLoading = false  // Stop loading after completion
        }
    }
}

#Preview {
    CreateUserAccountView(isPresented: Binding.constant(true))
}
