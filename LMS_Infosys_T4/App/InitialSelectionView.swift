import SwiftUI

struct InitialSelectionView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @Binding var selectedRole: Bool?
    @Environment(\.colorScheme) var colorScheme

    var body: some View {
        VStack(spacing: 30) {
            Spacer()
            Image(systemName: "books.vertical")
                .resizable()
                .scaledToFit()
                .frame(width: 200, height: 200)

            Text("Welcome to Library")
                .font(.largeTitle)
                .fontWeight(.bold)

            Spacer()

            Button(action: {
                selectedRole = true // User
            }) {
                Text("I'm a User")
                    .foregroundColor(colorScheme == .dark ? .black : .white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(colorScheme == .dark ? Color.white : Color.black)
                    .cornerRadius(10)
            }
            .buttonStyle(ScaleButtonStyle())

            Button(action: {
                selectedRole = false // Staff
            }) {
                Text("I'm a Staff")
                    .foregroundColor(colorScheme == .dark ? .black : .white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(colorScheme == .dark ? Color.white : Color.black)
                    .cornerRadius(10)
            }
            .buttonStyle(ScaleButtonStyle())
            
            Spacer()
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 40)
        .navigationBarBackButtonHidden(true)
    }
}

struct ScaleButtonStyle: ButtonStyle {
    func makeBody(configuration: Self.Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}

#Preview {
    InitialSelectionView(selectedRole: .constant(nil))
        .environmentObject(AuthViewModel())
}
