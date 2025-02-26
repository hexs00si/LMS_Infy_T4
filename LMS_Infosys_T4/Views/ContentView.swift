import SwiftUI

struct ContentView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @State private var navigationPath = NavigationPath()
    @State private var selectedRole: Bool? // nil = InitialSelection, true = User, false = Staff

    var body: some View {
        NavigationStack(path: $navigationPath) {
            Group {
                if authViewModel.isLoading {
                    ProgressView("Loading...")
                        .navigationBarBackButtonHidden(true)
                } else if authViewModel.isAuthenticated, let user = authViewModel.currentUser {
                    if authViewModel.showUpdatePassword {
                        UpdatePasswordView(viewModel: authViewModel)
                            .navigationBarBackButtonHidden(true)
                    } else {
                        switch user.userType {
                        case .admin:
                            AdminDashboardView()
                                .transition(.opacity)
                        case .librarian:
                            LibrarianDashboardView()
                                .transition(.opacity)
                        case .member:
                            MainTabView()
                                .transition(.opacity)
                        }
                    }
                } else {
                    if selectedRole == nil {
                        InitialSelectionView(selectedRole: $selectedRole)
                            .transition(.opacity)
                            .navigationBarBackButtonHidden(true)
                    } else {
                        LoginView(isUser: Binding(
                            get: { selectedRole ?? true },
                            set: { selectedRole = $0 }
                        ))
                        .transition(.opacity)
                        .navigationTitle("")
                        .toolbar {
                            ToolbarItem(placement: .navigationBarLeading) {
                                Button("Back") {
                                    selectedRole = nil
                                }
                            }
                        }
                    }
                }
            }
            .animation(.default, value: authViewModel.isAuthenticated)
            .onChange(of: authViewModel.isAuthenticated, { oldValue, newValue in
                print("🔍 ContentView - isAuthenticated changed to: \(newValue)")
                if !newValue {
                    navigationPath = NavigationPath()
                    selectedRole = nil // Reset to InitialSelectionView after sign-out
                    print("🧹 Navigation path and role reset")
                }
            })
            .onAppear {
                print("🔍 ContentView appeared - isAuthenticated: \(authViewModel.isAuthenticated)")
            }
        }
    }
}
