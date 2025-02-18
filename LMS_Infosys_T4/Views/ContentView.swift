//
//  ContentView.swift
//  LMS_Infosys_T4
//
//  Created by Shravan Rajput on 18/02/25.
//

import SwiftUI

struct ContentView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    
    var body: some View {
        Group {
            if authViewModel.isAuthenticated {
                // Add debug print statements
                Text("Debug: Authenticated - User Type: \(authViewModel.currentUser?.userType.rawValue ?? "Unknown")")
                    .onAppear {
                        print("🔍 ContentView: Authenticated")
                        print("🔍 Current User: \(String(describing: authViewModel.currentUser))")
                        print("🔍 Is Authenticated: \(authViewModel.isAuthenticated)")
                    }
                
                if authViewModel.showUpdatePassword {
                    UpdatePasswordView(viewModel: authViewModel)
                } else {
                    if let userType = authViewModel.currentUser?.userType {
                        switch userType {
                        case .admin:
                            AdminDashboardView()
                        case .librarian:
                            LibrarianDashboardView()
                        case .member:
                            UserDashboardView()
                        }
                    } else {
                        Text("❌ Error: User type is nil")
                    }
                }
            } else {
                InitialSelectionView()
            }
        }
    }
}
