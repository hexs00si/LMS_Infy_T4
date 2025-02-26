import SwiftUI


struct AdminDashboardView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @State private var isReportsViewPresented = true // Add this state

    var body: some View {
        TabView {
            ReportsView(isPresented: $isReportsViewPresented) // Pass the binding
                .environmentObject(authViewModel)
                .tabItem {
                    Image(systemName: "chart.bar.fill")
                    Text("Reports")
                }
            LibrariesView()
                .environmentObject(authViewModel)
                .tabItem {
                    Image(systemName: "books.vertical.fill")
                    Text("Libraries")
                }

            LibrariansView()
                .environmentObject(authViewModel)
                .tabItem {
                    Image(systemName: "person.2.fill")
                    Text("Librarians")
                }

//            ReportsView(isPresented: $isReportsViewPresented) // Pass the binding
//                .environmentObject(authViewModel)
//                .tabItem {
//                    Image(systemName: "chart.bar.fill")
//                    Text("Reports")
//                }
        }
        .navigationBarBackButtonHidden(true) // Prevent going back to login
    }
}
