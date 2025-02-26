//
//  ReadOnlyTextField.swift
//  LMS_Infosys_T4
//
//  Created by Gaganveer Bawa on 27/02/25.
//


import SwiftUI
import Swift
import Foundation


// Read-Only Text Field for Displaying Book Details
struct ReadOnlyTextField: View {
    let label: String
    let text: String
    
    var body: some View {
        VStack(alignment: .leading) {
            Text(label + ":")
                .foregroundColor(.gray)
            Text(text.isEmpty ? "-" : text)
                .lineLimit(nil)
                .multilineTextAlignment(.leading)
        }
    }
}
