import SwiftUI

struct VerificationView: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var isPresented: Bool
    
    var email: String
    let user: User
    var organizationID: String
    
    @State private var otp: String = ""
    @State private var showError = false
    @FocusState private var isFocused: Bool
    @State private var navigateToPasswordSetup = false
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                Spacer()
                
                Text("Verify Your Account")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundColor(.black)
                
                Text("Enter the 4-digit code sent to \(email)")
                    .foregroundColor(.gray)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 20)
                
                TextField("Enter OTP", text: $otp)
                    .frame(height: 20)
                    .padding()
                    .background(Color(UIColor.systemGray6))
                    .cornerRadius(10)
                    .multilineTextAlignment(.center)
                    .keyboardType(.numberPad)
                    .focused($isFocused)
                    .onChange(of: otp) { newValue in
                        if newValue.count > 4 {
                            otp = String(newValue.prefix(4))
                        }
                    }
                    .padding(20)
                
                if showError {
                    Text("Invalid Code. Try Again.")
                        .foregroundColor(.red)
                        .font(.footnote)
                }
                
                Button(action: {
                    if otp.count == 4 {
                        OTPCommands.shared.verifyOTP(otp: otp) { success, _ in
                            DispatchQueue.main.async {
                                if success {
                                    navigateToPasswordSetup = true
                                    showError = false
                                } else {
                                    showError = true
                                }
                            }
                        }
                    } else {
                        showError = true
                    }
                }) {
                    Text("Submit")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.black)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                }
                .padding(.horizontal, 40)
                
                Button(action: {
                    OTPCommands.shared.sendOTP(email: user.email, name: user.name) { success, error in
                        if error != nil {
                            print("An error occurred: \(error!)")
                        }
                    }
                }) {
                    Text("Resend Code")
                        .foregroundColor(.blue)
                        .fontWeight(.bold)
                }
                // Add a back button
                Button(action: {
                    isPresented = false  // This will trigger the dismissal
                }) {
                    Text("Cancel")
                        .foregroundColor(.blue)
                        .frame(maxWidth: .infinity)
                        .padding()
                }
                .padding(.top, 8)
                
                Spacer()
                NavigationLink(destination: CreatePasswordView(user: user, organizationID: organizationID), isActive: $navigateToPasswordSetup) {
                    EmptyView()
                }
                .hidden()
            }
            .padding()
            .onAppear { isFocused = true }
        }
    }
}


#Preview {
    VerificationView(isPresented: Binding.constant(true), email: "", user: User(id: "", name: "", email: "", password: "", gender: "", phoneNumber: "", joinDate: Date(), issuedBooks: [], currentlyIssuedCount: 0), organizationID: "")
}
