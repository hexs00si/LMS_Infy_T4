//
//  InitialSelectionView.swift
//  LMS_Infosys_T4
//
//  Created by Shravan Rajput on 18/02/25.
//
import SwiftUI

struct InitialSelectionView: View {
    @State private var navigateToLogin = false
    @State private var isUser = false
    
    var body: some View {
        VStack(spacing: 30) {
            Spacer()
            Image(systemName: "books.vertical")
                .resizable()
                .scaledToFit()
                .frame(width: 200, height: 200)
                .foregroundColor(.black)
            
            // Welcome Text
            Text("Welcome to Library")
                .font(.largeTitle)
                .fontWeight(.bold)
                .foregroundColor(.black)
            
            Spacer()
            
            Button(action: {
                isUser = true
                navigateToLogin = true
            }) {
                Text("I'm a User")
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.black)
                    .cornerRadius(10)
            }
            
            Button(action: {
                isUser = false
                navigateToLogin = true
            }) {
                Text("I'm a Staff")
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.black)
                    .cornerRadius(10)
            }
            Spacer()
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 40)
        .navigationBarHidden(true)
        .fullScreenCover(isPresented: $navigateToLogin) {
            LoginView(isUser: $isUser)
        }
    }
}

#Preview {
    InitialSelectionView()
}
