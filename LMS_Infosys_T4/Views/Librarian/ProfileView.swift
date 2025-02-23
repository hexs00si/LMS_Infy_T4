//
//  ProfileView.swift
//  libraraian 1
//
//  Created by Kinshuk Garg on 14/02/25.
//


import SwiftUI

struct ProfileView: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 15) {
            HStack {
                Image(systemName: "person.circle.fill")
                    .resizable()
                    .frame(width: 50, height: 50)
                    .foregroundColor(.gray)
                
                VStack(alignment: .leading) {
                    Text("Sarah Johnson")
                        .font(.headline)
                    Text("Library Administrator")
                        .foregroundColor(.gray)
                }
            }
            
            VStack(alignment: .leading, spacing: 8) {
                Text("Email")
                    .foregroundColor(.gray)
                Text("sarah.j@library.com")
                
                Text("Member Since")
                    .foregroundColor(.gray)
                    .padding(.top, 5)
                Text("Jan 2024")
            }
        }
        .padding()
        .background(Color.white)
        .cornerRadius(10)
        .shadow(radius: 2)
        .padding()
    }
}
