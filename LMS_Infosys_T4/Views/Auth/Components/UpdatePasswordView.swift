//
//  UpdatePasswordView.swift
//  LMS_Infosys_T4
//
//  Created by Shravan Rajput on 18/02/25.
//

import SwiftUI

struct UpdatePasswordView: View {
    @ObservedObject var viewModel: AuthViewModel
    @Environment(\.dismiss) private var dismiss
    
    @State private var isPasswordVisible = false
    @State private var isNewPasswordVisible = false
    var isSaveEnabled: Bool {
        return !viewModel.newPassword.isEmpty &&
               !viewModel.confirmPassword.isEmpty &&
               passwordsMatch() &&
               meetsSecurityRequirements()
    }
    
    func passwordsMatch() -> Bool {
        return viewModel.newPassword == viewModel.confirmPassword
    }
    
    func meetsSecurityRequirements() -> Bool {
        let passwordRegex = #"^(?=.*[A-Z])(?=.*[a-z])(?=.*\d)(?=.*[\W_]).{8,}$"#
        return viewModel.newPassword.range(of: passwordRegex, options: .regularExpression) != nil
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                VStack(alignment: .leading, spacing: 5) {
                    Text("New Password")
                        .font(.headline)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    
                    HStack {
                        if isPasswordVisible {
                            TextField("Password", text: $viewModel.newPassword)
                                .textFieldStyle(.plain)
                                .onChange(of: viewModel.newPassword) {
                                    viewModel.evaluatePassword()
                                }
                                
                        } else {
                            SecureField("Enter new password", text: $viewModel.newPassword)
                                .textFieldStyle(.plain)
                                .onChange(of: viewModel.newPassword) {
                                    viewModel.evaluatePassword()
                                }
                        }
                        
                        Button(action: {
                            isPasswordVisible.toggle()
                        }) {
                            Image(systemName: isPasswordVisible ? "eye.slash" : "eye")
                                .foregroundColor(.gray)
                        }
                    }
                    .padding()
                    .frame(height: 50)
                    .background(RoundedRectangle(cornerRadius: 8).stroke(Color.gray, lineWidth: 1))
                }
                
                VStack(alignment: .leading, spacing: 10) {
                    HStack {
                        Image(systemName: viewModel.newPassword.count >= 8 ? "checkmark.circle.fill" : "multiply.circle.fill")
                            .foregroundColor(viewModel.newPassword.count >= 8 ? .green : .red)
                        Text("At least 8 characters")
                    }
                    HStack {
                        Image(systemName: viewModel.newPassword.range(of: "[A-Z]", options: .regularExpression) != nil ? "checkmark.circle.fill" : "multiply.circle.fill")
                            .foregroundColor(viewModel.newPassword.range(of: "[A-Z]", options: .regularExpression) != nil ? .green : .red)
                        Text("Include uppercase and lowercase")
                    }
                    HStack {
                        Image(systemName: viewModel.newPassword.range(of: "\\d", options: .regularExpression) != nil ? "checkmark.circle.fill" : "multiply.circle.fill")
                            .foregroundColor(viewModel.newPassword.range(of: "\\d", options: .regularExpression) != nil ? .green : .red)
                        Text("Include at least one number")
                    }
                    HStack {
                        Image(systemName: viewModel.newPassword.range(of: "[\\W_]", options: .regularExpression) != nil ? "checkmark.circle.fill" : "multiply.circle.fill")
                            .foregroundColor(viewModel.newPassword.range(of: "[\\W_]", options: .regularExpression) != nil ? .green : .red)
                        Text("Include at least one special character")
                    }
                }
                .font(.subheadline)

                VStack(alignment: .leading, spacing: 5) {
                    Text("Confirm Password")
                        .font(.headline)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    
                    HStack {
                        if isNewPasswordVisible {
                            TextField("Re-enter Password", text: $viewModel.confirmPassword)
                                .textFieldStyle(.plain)
                                
                        } else {
                            SecureField("Re-enter password", text: $viewModel.confirmPassword)
                                .textFieldStyle(.plain)
                        }
                        
                        Button(action: {
                            isNewPasswordVisible.toggle()
                        }) {
                            Image(systemName: isPasswordVisible ? "eye.slash" : "eye")
                                .foregroundColor(.gray)
                        }
                    }
                    .padding()
                    .frame(height: 50)
                    .background(RoundedRectangle(cornerRadius: 8).stroke(Color.gray, lineWidth: 1))
                    
                    if !passwordsMatch() && !viewModel.confirmPassword.isEmpty {
                        Text("Passwords do not match")
                            .foregroundColor(.red)
                            .font(.caption)
                    }
                }
                
                if let error = viewModel.error {
                    Text(error)
                        .foregroundColor(.red)
                        .font(.caption)
                }

                Spacer()
            }
            .padding()
            .navigationTitle("Update Password")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(leading:
                Button("Cancel") {
                    dismiss()
                }
            )
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        Task {
                            await viewModel.updatePassword()
                            if viewModel.error == nil {
                                dismiss()
                            }
                        }
                    }) {
                        Text("Save")
                            .foregroundColor(isSaveEnabled ? .blue : .gray)
                    }
                    .disabled(!isSaveEnabled)
                }
            }
        }
    }
}

#Preview {
    UpdatePasswordView(viewModel: AuthViewModel())
}
