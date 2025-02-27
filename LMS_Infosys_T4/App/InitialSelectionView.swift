import SwiftUI

struct InitialSelectionView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @Binding var selectedRole: Bool?
    @Environment(\.colorScheme) var colorScheme

    var body: some View {
        ZStack {
            // Subtle background gradient for sophistication
            LinearGradient(
                gradient: Gradient(colors: [Color(.systemGray6), Color(.systemGray5)]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .edgesIgnoringSafeArea(.all)

            VStack(spacing: 35) {
                Spacer()

                // Modern book stack icon
                ZStack {
                    Rectangle()
                        .fill(colorScheme == .dark ? Color.white.opacity(0.9) : Color.black.opacity(0.9))
                        .frame(width: 100, height: 15)
                        .rotationEffect(.degrees(-12))
                        .offset(y: -25)
                    Rectangle()
                        .fill(colorScheme == .dark ? Color.white.opacity(0.85) : Color.black.opacity(0.85))
                        .frame(width: 110, height: 15)
                        .offset(y: -10)
                    Rectangle()
                        .fill(colorScheme == .dark ? Color.white.opacity(0.8) : Color.black.opacity(0.8))
                        .frame(width: 120, height: 15)
                        .rotationEffect(.degrees(8))
                        .offset(y: 5)
                }
                .frame(width: 150, height: 150)
                .shadow(color: Color.black.opacity(0.15), radius: 8, x: 0, y: 4)

                // Original "Welcome to Library" text with no font change
                Text("Welcome to Library")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundColor(.black) // Explicitly keeping black as per original
                    .padding(.top, 10)

                Spacer()

                // Modernized User Button
                Button(action: {
                    selectedRole = true // User
                }) {
                    Text("I'm a User")
                        .foregroundColor(colorScheme == .dark ? .black : .white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(colorScheme == .dark ? Color.white : Color.black)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(LinearGradient(
                                            gradient: Gradient(colors: [Color.clear, Color.white.opacity(0.15)]),
                                            startPoint: .top,
                                            endPoint: .bottom
                                        ))
                                )
                        )
                        .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
                }
                .buttonStyle(ScaleButtonStyle())

                // Modernized Staff Button
                Button(action: {
                    selectedRole = false // Staff
                }) {
                    Text("I'm a Staff")
                        .foregroundColor(colorScheme == .dark ? .black : .white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(colorScheme == .dark ? Color.white : Color.black)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(LinearGradient(
                                            gradient: Gradient(colors: [Color.clear, Color.white.opacity(0.15)]),
                                            startPoint: .top,
                                            endPoint: .bottom
                                        ))
                                )
                        )
                        .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
                }
                .buttonStyle(ScaleButtonStyle())

                Spacer()
            }
            .padding(.horizontal, 25)
            .padding(.vertical, 45)
        }
        .navigationBarBackButtonHidden(true)
    }
}

struct ScaleButtonStyle: ButtonStyle {
    func makeBody(configuration: Self.Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.94 : 1.0)
            .animation(.spring(response: 0.25, dampingFraction: 0.7), value: configuration.isPressed)
    }
}

#Preview {
    InitialSelectionView(selectedRole: .constant(nil))
        .environmentObject(AuthViewModel())
}
