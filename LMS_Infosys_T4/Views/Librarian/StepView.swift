//
//  StepView.swift
//  libraraian 1
//
//  Created by Kinshuk Garg on 14/02/25.
//


import SwiftUI

struct StepView: View {
    let number: Int
    let text: String
    
    var body: some View {
        HStack(spacing: 15) {
            Text("\(number)")
                .font(.subheadline)
                .foregroundColor(.white)
                .frame(width: 24, height: 24)
                .background(Color.blue)
                .cornerRadius(12)
            
            Text(text)
                .font(.subheadline)
        }
    }
}
