//
//  UserLoginView.swift
//  LMS_Infosys_T4
//
//  Created by Shravan Rajput on 18/02/25.
//

import SwiftUI

struct UserLoginView: View {
    @StateObject private var viewModel = AuthViewModel()
    @Environment(\.dismiss) private var dismiss
    @State private var navigateToDashboard = false
    @State private var showingStaffError = false
    @State private var showSignUp = false
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                Text("Member Sign In")
                    .font(.largeTitle)
                    .bold()
                
                VStack(alignment: .leading) {
                    Text("Your Email")
                        .foregroundColor(.gray)
                    
                    TextField("Email", text: $viewModel.email)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .autocapitalization(.none)
                        .keyboardType(.emailAddress)
                    
                    Text("Password")
                        .foregroundColor(.gray)
                        .padding(.top, 15)
                    
                    HStack {
                        SecureField("Password", text: $viewModel.password)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                    }
                }
                .padding(.top, 30)
                
                if let error = viewModel.error {
                    Text(error)
                        .foregroundColor(.red)
                        .font(.caption)
                }
                
                Button(action: {
                    Task {
                        await viewModel.signIn()
                        
                        await MainActor.run {
                            // Check if user is a staff member (admin or librarian)
                            if let userType = viewModel.currentUser?.userType {
                                switch userType {
                                case .admin, .librarian:
                                    showingStaffError = true
                                    viewModel.isAuthenticated = false
                                    return
                                case .member:
                                    if viewModel.isAuthenticated && !viewModel.showUpdatePassword {
                                        navigateToDashboard = true
                                    }
                                }
                            }
                        }
                    }
                }) {
                    if viewModel.isLoading {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    } else {
                        Text("Sign in")
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.black)
                            .cornerRadius(10)
                    }
                }
                .disabled(viewModel.isLoading)
                
                HStack {
                                    Text("Don't have an account?")
                                        .foregroundColor(.gray)
                                    Button("Create an Account") {
                                        showSignUp = true
                                    }
                                }
                                .padding(.top)
                                
                                Spacer()
                            }
                            .padding()
                            .navigationBarItems(leading: Button("Back") {
                                dismiss()
                            })
                            .navigationDestination(isPresented: $navigateToDashboard) {
                                if case .member = viewModel.currentUser?.userType {
                                    UserDashboardView()
                                }
                            }
                        }
                        .fullScreenCover(isPresented: $viewModel.showUpdatePassword) {
                            if case .member = viewModel.currentUser?.userType {
                                UpdatePasswordView(viewModel: viewModel)
                            }
                        }
                        .alert("Invalid Login", isPresented: $showingStaffError) {
                            Button("OK", role: .cancel) {
                                viewModel.email = ""
                                viewModel.password = ""
                            }
                        } message: {
                            Text("Please use the 'I'm a Staff' button to login as staff. This login is for members only.")
                        }
                        .sheet(isPresented: $showSignUp) {
                            SignUpView(isPresented: $showSignUp)  // Pass the binding here
                        }
                    }
                }
