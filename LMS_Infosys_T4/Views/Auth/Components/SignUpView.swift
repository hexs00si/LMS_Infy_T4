//
//  SignUpView.swift
//  LMS_Infosys_T4
//
//  Created by Shravan Rajput on 19/02/25.
//

import SwiftUI

struct SignUpView: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var isPresented: Bool
    
    @State private var name = ""
    @State private var email = ""
    @State private var organizationID = ""
    @State private var selectedGender = ""
    @State private var phoneNumber = ""
    @State private var showGenderMenu = false
    
    let genderOptions = ["Male", "Female", "Other"]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Create Account")
                .font(.title)
                .bold()
                .padding(.bottom, 8)
            
            VStack(alignment: .leading, spacing: 6) {
                Text("Name")
                    .foregroundColor(.gray)
                TextField("Enter your name", text: $name)
                    .textFieldStyle(.plain)
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(10)
            }
            
            VStack(alignment: .leading, spacing: 6) {
                Text("Email")
                    .foregroundColor(.gray)
                TextField("Enter your email", text: $email)
                    .textFieldStyle(.plain)
                    .keyboardType(.emailAddress)
                    .autocapitalization(.none)
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(10)
            }
            
            VStack(alignment: .leading, spacing: 6) {
                Text("Organization ID (Optional)")
                    .foregroundColor(.gray)
                TextField("Enter organization ID", text: $organizationID)
                    .textFieldStyle(.plain)
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(10)
            }
            
            VStack(alignment: .leading, spacing: 6) {
                Text("Gender (Optional)")
                    .foregroundColor(.gray)
                Menu {
                    ForEach(genderOptions, id: \.self) { gender in
                        Button(gender) {
                            selectedGender = gender
                        }
                    }
                } label: {
                    HStack {
                        Text(selectedGender.isEmpty ? "Select gender" : selectedGender)
                            .foregroundColor(selectedGender.isEmpty ? .gray : .primary)
                        Spacer()
                        Image(systemName: "chevron.down")
                            .foregroundColor(.blue)
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(10)
                }
            }
            
            VStack(alignment: .leading, spacing: 6) {
                Text("Phone Number (Optional)")
                    .foregroundColor(.gray)
                TextField("Enter phone number", text: $phoneNumber)
                    .textFieldStyle(.plain)
                    .keyboardType(.phonePad)
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(10)
            }
            
            Spacer()
            
            // Verify Button
            Button(action: {
                // Verification action will be added later
            }) {
                Text("Verify")
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.black)
                    .cornerRadius(10)
            }
            
            // Cancel Button
            Button(action: {
                dismiss()
            }) {
                Text("Cancel")
                    .foregroundColor(.red)
                    .frame(maxWidth: .infinity)
            }
            .padding(.top, 8)
        }
        .padding()
    }
}
