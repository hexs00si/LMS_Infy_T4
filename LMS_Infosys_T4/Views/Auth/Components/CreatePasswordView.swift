//
//  PasswordSetupView.swift
//  LMS
//
//  Created by Dakshdeep Singh on 17/02/25.
//

import SwiftUI

struct CreatePasswordView: View {
    let user: User
    let organizationID: String
    
    @State private var password = ""
    @State private var confirmPassword = ""
    @State private var isPasswordVisible = false
    @State private var isConfirmPasswordVisible = false
    @State private var showError = false
    @State private var errorMessage = "Passwords do not match."
    @State private var presentLoginView = false
    @State private var isProcessing = false  // New state for loading indicator
    
    var isSaveEnabled: Bool {
        return !password.isEmpty &&
               !confirmPassword.isEmpty &&
               passwordsMatch() &&
               meetsSecurityRequirements()
    }

    func passwordsMatch() -> Bool {
        return password == confirmPassword
    }

    func meetsSecurityRequirements() -> Bool {
        let passwordRegex = #"^(?=.*[A-Z])(?=.*[a-z])(?=.*\d)(?=.*[\W_]).{8,}$"#
        return password.range(of: passwordRegex, options: .regularExpression) != nil
    }
    
    var body: some View {
        VStack(spacing: 20) {
            Spacer()
            
            Text("Set Your Password")
                .font(.largeTitle)
                .fontWeight(.bold)
                .foregroundColor(.black)
            
            VStack(alignment: .leading, spacing: 5) {
                Text("New Password")
                    .font(.headline)

                HStack {
                    if isPasswordVisible {
                        TextField("Enter Password", text: $password)
                    } else {
                        SecureField("Enter Password", text: $password)
                    }

                    Button(action: { isPasswordVisible.toggle() }) {
                        Image(systemName: isPasswordVisible ? "eye.slash" : "eye")
                            .foregroundColor(.gray)
                    }
                }
                .padding()
                .background(Color(UIColor.systemGray6))
                .cornerRadius(10)
            }
            
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Image(systemName: password.count >= 8 ? "checkmark.circle.fill" : "multiply.circle.fill")
                        .foregroundColor(password.count >= 8 ? .green : .red)
                    Text("At least 8 characters")
                }
                HStack {
                    Image(systemName: password.range(of: "[A-Z]", options: .regularExpression) != nil ? "checkmark.circle.fill" : "multiply.circle.fill")
                        .foregroundColor(password.range(of: "[A-Z]", options: .regularExpression) != nil ? .green : .red)
                    Text("Include uppercase and lowercase")
                }
                HStack {
                    Image(systemName: password.range(of: "\\d", options: .regularExpression) != nil ? "checkmark.circle.fill" : "multiply.circle.fill")
                        .foregroundColor(password.range(of: "\\d", options: .regularExpression) != nil ? .green : .red)
                    Text("Include at least one number")
                }
                HStack {
                    Image(systemName: password.range(of: "[\\W_]", options: .regularExpression) != nil ? "checkmark.circle.fill" : "multiply.circle.fill")
                        .foregroundColor(password.range(of: "[\\W_]", options: .regularExpression) != nil ? .green : .red)
                    Text("Include at least one special character")
                }
            }
            .font(.subheadline)

            VStack(alignment: .leading, spacing: 5) {
                Text("Confirm Password")
                    .font(.headline)

                HStack {
                    if isConfirmPasswordVisible {
                        TextField("Confirm Password", text: $confirmPassword)
                    } else {
                        SecureField("Confirm Password", text: $confirmPassword)
                    }

                    Button(action: { isConfirmPasswordVisible.toggle() }) {
                        Image(systemName: isConfirmPasswordVisible ? "eye.slash" : "eye")
                            .foregroundColor(.gray)
                    }
                }
                .padding()
                .background(Color(UIColor.systemGray6))
                .cornerRadius(10)

                if !passwordsMatch() && !confirmPassword.isEmpty {
                    Text("Passwords do not match")
                        .foregroundColor(.red)
                        .font(.caption)
                }
            }
            
            if showError {
                Text(errorMessage)
                    .foregroundColor(.red)
                    .font(.footnote)
            }

            Button(action: {
                isProcessing = true  // Start processing
                AuthenticationService().completeSignUp(password: password, user: user, organizationID: organizationID) { success, error in
                    isProcessing = false  // Stop processing
                    if success {
                        presentLoginView = true
                    } else {
                        showError = true
                        errorMessage = error ?? "An unknown error occurred."
                    }
                }
            }) {
                if isProcessing {
                    ProgressView()  // Show loading indicator
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.gray)
                        .cornerRadius(10)
                } else {
                    Text("Confirm")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(isSaveEnabled ? Color.black : Color.gray)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                }
            }
            .disabled(!isSaveEnabled || isProcessing)
            .padding(.horizontal, 40)
            .fullScreenCover(isPresented: $presentLoginView) {
                LoginView(isUser: Binding.constant(true))
            }

            Spacer()
        }
        .padding()
    }
}
