//
//  ReturnView.swift
//  LMS_Infosys_T4
//
//  Created by Gaganveer Bawa on 26/02/25.
//


import SwiftUI

struct ReturnView: View {
    @State private var bookID: String = ""
    @State private var returnMessage: String = ""
    @State private var showAlert: Bool = false

    var body: some View {
        VStack {
            Text("Return a Book")
                .font(.largeTitle)
                .padding()

            TextField("Enter Book ID", text: $bookID)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding()

            Button(action: {
                returnBook()
            }) {
                Text("Return Book")
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(8)
            }
            .alert(isPresented: $showAlert) {
                Alert(title: Text("Return Status"), message: Text(returnMessage), dismissButton: .default(Text("OK")))
            }
        }
        .padding()
    }

    private func returnBook() {
        // Logic to handle book return will go here
        // For now, we'll just simulate a successful return
        if !bookID.isEmpty {
            returnMessage = "Book with ID \(bookID) returned successfully!"
        } else {
            returnMessage = "Please enter a valid Book ID."
        }
        showAlert = true
    }
}

#Preview {
    ReturnView()
}
