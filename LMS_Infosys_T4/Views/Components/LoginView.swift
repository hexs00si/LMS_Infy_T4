import SwiftUI

struct LoginView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var showSignUp = false
    @State private var showInvalidLoginAlert = false
    @State private var isPasswordVisible = false
    @Environment(\.colorScheme) var colorScheme
    
    @Binding var isUser: Bool
    
    var body: some View {
        VStack(spacing: 30) {
            Text(isUser ? "Member Sign In" : "Staff Sign In")
                .font(.largeTitle)
                .fontWeight(.bold)
//                .foregroundColor(.black)
            
            VStack(alignment: .leading, spacing: 8) {
                Text("Your Email")
                    .foregroundColor(.gray)
                    .font(.footnote)
                
                HStack {
                    TextField("Email", text: $authViewModel.email)
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
                
                HStack {
                    if isPasswordVisible {
                        TextField("Password", text: $authViewModel.password)
                    } else {
                        SecureField("Password", text: $authViewModel.password)
                    }
                    
                    Button(action: { isPasswordVisible.toggle() }) {
                        Image(systemName: isPasswordVisible ? "eye.slash" : "eye")
                            .foregroundColor(.gray)
                    }
                }
                .frame(height: 25)
                .padding()
                .background(Color(UIColor.systemGray6))
                .cornerRadius(10)
            }
            
            if let error = authViewModel.error {
                Text(error)
                    .foregroundColor(.red)
                    .font(.caption)
            }
            
            Button(action: handleLogin) {
                if authViewModel.isLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                } else {
                    Text("Sign in")
                        .foregroundColor(colorScheme == .dark ? Color.black : Color.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.primary)
                        .cornerRadius(10)
                }
            }
            .disabled(authViewModel.isLoading)
            
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
        .fullScreenCover(isPresented: $authViewModel.showUpdatePassword) {
            UpdatePasswordView(viewModel: authViewModel)
        }
        .alert("Invalid Login", isPresented: $showInvalidLoginAlert) {
            Button("OK", role: .cancel) {
                authViewModel.email = ""
                authViewModel.password = ""
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
            await authViewModel.signIn()
            if let userType = authViewModel.currentUser?.userType {
                if (isUser && (userType == .admin || userType == .librarian)) || (!isUser && userType == .member) {
                    await MainActor.run {
                        showInvalidLoginAlert = true
                        authViewModel.isAuthenticated = false
                    }
                }
            }
        }
    }
}

#Preview {
    LoginView(isUser: .constant(true))
        .environmentObject(AuthViewModel())
}
