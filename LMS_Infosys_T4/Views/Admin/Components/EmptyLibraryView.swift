//
//  EmptyLibraryView.swift
//  LMS_Infosys_T4
//
//  Created by Shravan Rajput on 19/02/25.
//

import SwiftUI

import SwiftUI

struct EmptyLibraryView: View {
    var body: some View {
        VStack(spacing: 24) {
            Image(systemName: "books.vertical")
                .font(.system(size: 60))
                .foregroundColor(.gray.opacity(0.8))
            
            VStack(spacing: 8) {
                Text("No Libraries Added Yet")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(.primary)
                
                Text("Add your first library using the + button above")
                    .font(.system(size: 15))
                    .foregroundColor(.gray)
                    .multilineTextAlignment(.center)
            }
        }
        .padding()
        .background(Color(.systemGroupedBackground))
    }
}


#Preview {
    EmptyLibraryView()
}
