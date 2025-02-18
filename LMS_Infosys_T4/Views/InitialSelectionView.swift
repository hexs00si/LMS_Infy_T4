//
//  InitialSelectionView.swift
//  LMS_Infosys_T4
//
//  Created by Shravan Rajput on 18/02/25.
//

import SwiftUI

struct InitialSelectionView: View {
    @State private var navigateToStaffLogin = false
    @State private var navigateToUserLogin = false
    
    var body: some View {
        VStack(spacing: 30) {
            // Library Icon
            Image("books_stack")
                .resizable()
                .scaledToFit()
                .frame(width: 120, height: 120)
            
            Text("Welcome to Library")
                .font(.largeTitle)
                .bold()
            
            Spacer()
            
            // User Button
            Button(action: {
                navigateToUserLogin = true
            }) {
                Text("I'm a User")
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.black)
                    .cornerRadius(10)
            }
            
            // Staff Button
            Button(action: {
                navigateToStaffLogin = true
            }) {
                Text("I'm a Staff")
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.black)
                    .cornerRadius(10)
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 40)
        .navigationBarHidden(true)
        .fullScreenCover(isPresented: $navigateToStaffLogin) {
            StaffLoginView()
        }
        .fullScreenCover(isPresented: $navigateToUserLogin) {
            UserLoginView()
        }
    }
}

#Preview{
    InitialSelectionView()
}
