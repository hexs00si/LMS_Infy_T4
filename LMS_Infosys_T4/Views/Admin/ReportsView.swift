import SwiftUI

struct ReportsView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @Binding var isPresented: Bool
    @State private var showingSignOutAlert = false
    
    var body: some View {
        NavigationView {
            VStack {
                Text("Reports coming soon")
                    .font(.title)
                    .foregroundColor(.gray)
                Spacer()
            }
            .navigationTitle("Reports")
            .navigationBarItems(trailing:
                                    Button(action: {
                showingSignOutAlert = true
            }) {
                Image(systemName: "rectangle.portrait.and.arrow.right")
                    .font(.system(size: 20))
                    .foregroundColor(.blue)
            }
            )
            .alert("Sign Out", isPresented: $showingSignOutAlert) {
                Button("Cancel", role: .cancel) { }
                Button("Sign Out", role: .destructive) {
                    Task {
                        await authViewModel.signOut()
                        // No need to set isPresented = false here; ContentView will handle navigation
                    }
                }
            } message: {
                Text("Are you sure you want to sign out?")
            }
        }
    }
}
