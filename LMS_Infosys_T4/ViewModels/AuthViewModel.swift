//
//  AuthViewModel.swift
//  LMS_Infosys_T4
//
//  Created by Shravan Rajput on 18/02/25.
//

import Foundation
import SwiftUI
import Combine

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
            print("🚀 isAuthenticated changed: \(isAuthenticated)")
            // Optionally trigger any side effects or UI updates
            objectWillChange.send()
        }
    }
    
    // Password Validation
    @Published var passwordCriteria = PasswordCriteria()
    
    // Private Services
    private let authService = AuthenticationService()
    
    // Computed Properties
    var isPasswordValid: Bool {
        passwordCriteria.isValid && newPassword == confirmPassword
    }
    
    // Staff Sign In Method
    func staffSignIn() async {
        // Reset state before sign in attempt
        await MainActor.run {
            isLoading = true
            error = nil
            isAuthenticated = false
        }
        
        do {
            // Attempt authentication
            let user = try await authService.staffSignIn(email: email, password: password)
            
            // Update state on main thread
            await MainActor.run {
                print("✅ User authenticated successfully")
                print("User Details: \(user)")
                
                // Update all relevant state properties
                self.currentUser = user
                self.isAuthenticated = true
                self.showUpdatePassword = user.isFirstLogin
                self.isLoading = false
                
                // Additional debugging
                print("🔍 Authentication State:")
                print("- User Type: \(user.userType.rawValue)")
                print("- Is First Login: \(user.isFirstLogin)")
                print("- isAuthenticated: \(self.isAuthenticated)")
                print("- showUpdatePassword: \(self.showUpdatePassword)")
                
                // Explicitly notify observers of changes
                self.objectWillChange.send()
            }
        } catch {
            // Handle authentication errors
            await MainActor.run {
                print("❌ Authentication Failed: \(error.localizedDescription)")
                
                self.error = error.localizedDescription
                self.isLoading = false
                self.isAuthenticated = false
                self.currentUser = nil
                
                // Explicitly notify observers of changes
                self.objectWillChange.send()
            }
        }
    }
    
    // Update Password Method
    func updatePassword() async {
        // Validate password before proceeding
        guard isPasswordValid else {
            error = "Password does not meet criteria or does not match"
            return
        }
        
        // Reset state
        await MainActor.run {
            isLoading = true
            error = nil
        }
        
        do {
            // Attempt password update
            try await authService.updatePassword(newPassword: newPassword)
            
            await MainActor.run {
                self.showUpdatePassword = false
                self.isLoading = false
                self.isAuthenticated = true
                
                // Reset password fields
                self.newPassword = ""
                self.confirmPassword = ""
                
                // Notify observers
                self.objectWillChange.send()
            }
        } catch {
            await MainActor.run {
                self.error = error.localizedDescription
                self.isLoading = false
                
                // Notify observers
                self.objectWillChange.send()
            }
        }
    }
    
    // Password Evaluation Method
    func evaluatePassword() {
        passwordCriteria.evaluate(newPassword)
    }
    
    // Optional: Sign Out Method (uncomment if needed)
    /*
    func signOut() {
        do {
            try authService.signOut()
            // Reset all state
            currentUser = nil
            isAuthenticated = false
            showUpdatePassword = false
            email = ""
            password = ""
            error = nil
            objectWillChange.send()
        } catch {
            self.error = error.localizedDescription
        }
    }
    */
}
