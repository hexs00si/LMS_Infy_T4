//
//  StaffLoginView.swift
//  LMS_Infosys_T4
//
//  Created by Shravan Rajput on 18/02/25.
//

import Foundation
import SwiftUI
import Combine

struct StaffLoginView: View {
    @StateObject private var viewModel = AuthViewModel()
    @Environment(\.dismiss) private var dismiss
    @State private var navigateToDashboard = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                Text("Staff Sign In")
                    .font(.largeTitle)
                    .bold()
                
                VStack(alignment: .leading) {
                    // Email Field
                    Text("Your Email")
                        .foregroundColor(.gray)
                    
                    TextField("Email", text: $viewModel.email)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .autocapitalization(.none)
                        .keyboardType(.emailAddress)
                    
                    // Password Field
                    Text("Password")
                        .foregroundColor(.gray)
                        .padding(.top, 15)
                    
                    HStack {
                        SecureField("Password", text: $viewModel.password)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                        
                        Button(action: {
                            // Toggle password visibility (optional implementation)
                        }) {
                            Image(systemName: "eye.fill")
                                .foregroundColor(.gray)
                        }
                    }
                }
                .padding(.top, 30)
                
                // Error Message
                if let error = viewModel.error {
                    Text(error)
                        .foregroundColor(.red)
                        .font(.caption)
                }
                
                // Sign In Button
                Button(action: {
                    Task {
                        await viewModel.staffSignIn()
                        
                        // Explicitly handle navigation on main thread
                        DispatchQueue.main.async {
                            if viewModel.isAuthenticated && !viewModel.showUpdatePassword {
                                navigateToDashboard = true
                                print("🚀 Navigation triggered for user type: \(viewModel.currentUser?.userType.rawValue ?? "Unknown")")
                            }
                        }
                    }
                }) {
                    if viewModel.isLoading {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    } else {
                        Text("Sign In")
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.black)
                            .cornerRadius(10)
                    }
                }
                .disabled(viewModel.isLoading)
                
                Spacer()
                
                // Hidden NavigationLink for explicit routing
                NavigationLink(
                    destination:
                        Group {
                            if let userType = viewModel.currentUser?.userType {
                                switch userType {
                                case .admin:
                                    AdminDashboardView()
                                case .librarian:
                                    LibrarianDashboardView()
                                case .member:
                                    UserDashboardView()
                                }
                            } else {
                                Text("Error: Unable to determine user type")
                            }
                        },
                    isActive: $navigateToDashboard
                ) {
                    EmptyView()
                }
            }
            .padding()
            .navigationBarItems(leading: Button("Back") {
                dismiss()
            })
        }
        .fullScreenCover(isPresented: $viewModel.showUpdatePassword) {
            UpdatePasswordView(viewModel: viewModel)
        }
        // Debug print statements
        .onAppear {
            print("🔍 StaffLoginView appeared")
        }
    }
}

#Preview {
    StaffLoginView()
}
