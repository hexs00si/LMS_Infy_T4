import SwiftUI

struct LoginView: View {
    @StateObject private var viewModel = AuthViewModel()
    @Environment(\.dismiss) private var dismiss
    @State private var navigateToDashboard = false
    @State private var showSignUp = false
    @State private var showInvalidLoginAlert = false
    @State private var isPasswordVisible = false
    
    @Binding var isUser: Bool
    
    var body: some View {
        NavigationStack {
            Spacer()
            
            VStack(spacing: 30) {
                
                Text(isUser ? "Member Sign In" : "Staff Sign In")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundColor(.black)
                
                VStack(alignment: .leading, spacing: 8) {
                    Text("Your Email")
                        .foregroundColor(.gray)
                        .font(.footnote)
                    
                    HStack {
                        TextField("Email", text: $viewModel.email)
                            .padding()
                            .background(Color(UIColor.systemGray6))
                            .cornerRadius(10)
                            .autocapitalization(.none)
                            .keyboardType(.emailAddress)
                            .textContentType(.emailAddress)
                    }
                }
                
                VStack(alignment: .leading, spacing: 8) {
                    Text("Password")
                        .foregroundColor(.gray)
                        .font(.footnote)
//
//                    SecureField("Password", text: $viewModel.password)
//                        .textFieldStyle(RoundedBorderTextFieldStyle())
                    
                    HStack {
                        if isPasswordVisible {
                            TextField("Password", text: $viewModel.password)
                                
                        } else {
                            SecureField("Password", text: $viewModel.password)
                        }
                        
                        Button(action: {
                            isPasswordVisible.toggle()
                        }) {
                            Image(systemName: isPasswordVisible ? "eye.slash" : "eye")
                                .foregroundColor(.gray)
                        }
                    }
                    .frame(height: 25)
                    .padding()
                    .background(Color(UIColor.systemGray6))
                    .cornerRadius(10)
                }
//                .padding(.top, 20)
                
                
                if let error = viewModel.error {
                    Text(error)
                        .foregroundColor(.red)
                        .font(.caption)
                }
                
                Button(action: handleLogin) {
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
                
                if isUser {
                    HStack {
                        Text("Don't have an account?")
                            .foregroundColor(.gray)
                        Button("Create an Account") {
                            showSignUp = true
                        }
                    }
                }
                Spacer()
            }
            .padding()
            .navigationBarItems(leading: Button("Back") {
                dismiss()
            })
            .navigationDestination(isPresented: $navigateToDashboard) {
                getDashboardView()
            }
        }
        .fullScreenCover(isPresented: $viewModel.showUpdatePassword) {
            UpdatePasswordView(viewModel: viewModel)
        }
        .alert("Invalid Login", isPresented: $showInvalidLoginAlert) {
            Button("OK", role: .cancel) {
                viewModel.email = ""
                viewModel.password = ""
            }
        } message: {
            Text(isUser ? "Please use the 'I'm a Staff' button to login as staff." : "Please use the 'I'm a User' button to login as a member.")
        }
        .sheet(isPresented: $showSignUp) {
            CreateUserAccountView(isPresented: $showSignUp)
        }
    }
    
    private func handleLogin() {
        Task {
            await viewModel.signIn()
            
            DispatchQueue.main.async {
                if let userType = viewModel.currentUser?.userType {
                    if (isUser && (userType == .admin || userType == .librarian)) || (!isUser && userType == .member) {
                        showInvalidLoginAlert = true
                        viewModel.isAuthenticated = false
                        return
                    }
                    if viewModel.isAuthenticated && !viewModel.showUpdatePassword {
                        navigateToDashboard = true
                    }
                }
            }
        }
    }
    
    @ViewBuilder
    private func getDashboardView() -> some View {
        if let userType = viewModel.currentUser?.userType {
            switch userType {
            case .member:
                MemberHomeView()
            case .admin:
                AdminDashboardView()
            case .librarian:
                LibrarianDashboardView()
            }
        } else {
            Text("Error: Unable to determine user type")
        }
    }
}
#Preview{
    LoginView(isUser: Binding.constant(true))
}
