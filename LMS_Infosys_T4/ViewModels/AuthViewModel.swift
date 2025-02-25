import Foundation
import SwiftUI
import FirebaseAuth

class AuthViewModel: ObservableObject {
    // Input Properties
    @Published var email = ""
    @Published var password = ""
    @Published var newPassword = ""
    @Published var confirmPassword = ""
    
    // State Properties
    @Published var isLoading = false
    @Published var error: String?
    @Published var showUpdatePassword = false
    @Published var currentUser: AuthUser?
    @Published var isAuthenticated = false {
        didSet {
            print("🚀 isAuthenticated changed to: \(isAuthenticated)")
            objectWillChange.send() // Ensure SwiftUI is notified
        }
    }
    
    // Password Validation
    @Published var passwordCriteria = PasswordCriteria()
    
    // Private Services
    private let authService = AuthenticationService()
    private var authStateHandle: AuthStateDidChangeListenerHandle?
    
    // Computed Properties
    var isPasswordValid: Bool {
        passwordCriteria.isValid && newPassword == confirmPassword
    }
    
    init() {
        // Monitor Firebase auth state changes
        authStateHandle = Auth.auth().addStateDidChangeListener { [weak self] _, user in
            Task { @MainActor in
                guard let self = self else { return }
                if let user = user {
                    // User is signed in; fetch details if needed
                    if self.currentUser == nil && !self.email.isEmpty && !self.password.isEmpty {
                        do {
                            let authUser = try await self.authService.signIn(email: self.email, password: self.password)
                            self.currentUser = authUser
                            self.isAuthenticated = true
                            self.showUpdatePassword = authUser.isFirstLogin
                        } catch {
                            self.error = "Failed to fetch user data: \(error.localizedDescription)"
                            self.isAuthenticated = false
                            self.currentUser = nil
                        }
                    }
                } else {
                    // User is signed out
                    self.currentUser = nil
                    self.isAuthenticated = false
                    self.showUpdatePassword = false
                    self.email = ""
                    self.password = ""
                    self.error = nil
                    print("🔍 Firebase auth state: Signed out")
                }
            }
        }
    }
    
    deinit {
        if let handle = authStateHandle {
            Auth.auth().removeStateDidChangeListener(handle)
            print("🧹 Removed Firebase auth state listener")
        }
    }
    
    func signIn() async {
        await MainActor.run {
            self.isLoading = true
            self.error = nil
        }
        
        do {
            let user = try await authService.signIn(email: email, password: password)
            await MainActor.run {
                print("✅ User authenticated successfully: \(user)")
                self.currentUser = user
                self.isAuthenticated = true
                self.showUpdatePassword = user.isFirstLogin
                self.isLoading = false
                print("🔍 Authentication State - User Type: \(user.userType.rawValue), Is First Login: \(user.isFirstLogin)")
            }
        } catch {
            await MainActor.run {
                print("❌ Authentication failed: \(error.localizedDescription)")
                self.error = error.localizedDescription
                self.isLoading = false
                self.isAuthenticated = false
                self.currentUser = nil
            }
        }
    }
    
    func updatePassword() async {
        guard isPasswordValid else {
            await MainActor.run {
                self.error = "Password does not meet criteria or does not match"
            }
            return
        }
        
        await MainActor.run {
            self.isLoading = true
            self.error = nil
        }
        
        do {
            try await authService.updatePassword(newPassword: newPassword)
            await MainActor.run {
                self.showUpdatePassword = false
                self.isLoading = false
                self.newPassword = ""
                self.confirmPassword = ""
                print("✅ Password updated successfully")
            }
        } catch {
            await MainActor.run {
                self.error = error.localizedDescription
                self.isLoading = false
                print("❌ Password update failed: \(error.localizedDescription)")
            }
        }
    }
    
    func evaluatePassword() {
        passwordCriteria.evaluate(newPassword)
    }
    
    func signOut() async {
        await MainActor.run {
            self.isLoading = true
            self.error = nil
        }
        
        do {
            try authService.signOut()
            await MainActor.run {
                self.currentUser = nil
                self.isAuthenticated = false
                self.showUpdatePassword = false
                self.email = ""
                self.password = ""
                self.newPassword = ""
                self.confirmPassword = ""
                self.isLoading = false
                print("🔓 User signed out successfully")
            }
        } catch {
            await MainActor.run {
                self.error = error.localizedDescription
                self.isLoading = false
                print("❌ Sign out failed: \(error.localizedDescription)")
            }
        }
    }
}
