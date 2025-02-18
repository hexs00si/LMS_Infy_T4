//
//  UpdatePasswordView.swift
//  LMS_Infosys_T4
//
//  Created by Shravan Rajput on 18/02/25.
//

import SwiftUI

import SwiftUI

struct UpdatePasswordView: View {
    @ObservedObject var viewModel: AuthViewModel
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                // Password Fields
                VStack(alignment: .leading, spacing: 8) {
                    Text("New Password")
                        .foregroundColor(.gray)
                    
                    SecureField("Enter new password", text: $viewModel.newPassword)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .onChange(of: viewModel.newPassword) { _ in
                            viewModel.evaluatePassword()
                        }
                    
                    // Password Criteria
                    PasswordCriteriaView(criteria: viewModel.passwordCriteria)
                        .padding(.vertical)
                    
                    Text("Confirm Password")
                        .foregroundColor(.gray)
                    
                    SecureField("Confirm new password", text: $viewModel.confirmPassword)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                }
                
                // Error Message
                if let error = viewModel.error {
                    Text(error)
                        .foregroundColor(.red)
                        .font(.caption)
                }
                
                // Update Button
                Button {
                    Task {
                        await viewModel.updatePassword()
                        // After successful password update, dismiss view
                        if viewModel.error == nil {
                            dismiss()
                        }
                    }
                } label: {
                    if viewModel.isLoading {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    } else {
                        Text("Update Password")
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                    }
                }
                .padding()
                .background(viewModel.isPasswordValid ? Color.blue : Color.gray)
                .cornerRadius(10)
                .disabled(!viewModel.isPasswordValid || viewModel.isLoading)
            }
            .padding()
            .navigationTitle("Update Password")
            // Add navigation bar items if needed
            .navigationBarItems(trailing:
                Button("Cancel") {
                    dismiss()
                }
            )
        }
    }
}
