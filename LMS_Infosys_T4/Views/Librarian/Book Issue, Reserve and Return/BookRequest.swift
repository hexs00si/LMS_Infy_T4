//
//  BookRequest.swift
//  library
//
//  Created by Udayveer Chhina on 20/02/25.
//

import SwiftUI

struct BookRequest: Identifiable {
    let id = UUID()
    let name: String
    let author: String
    let issuer: String
    let issueDate: String
    let imageName: String // New property for the image
}

struct BookRequestData {
    static let requests = [
        BookRequest(name: "The Great Gatsby", author: "F. Scott Fitzgerald", issuer: "John Smith ( STU001 )", issueDate: "Feb 10, 2024", imageName: "book.fill"),
        BookRequest(name: "To Kill a Mockingbird", author: "Harper Lee", issuer: "Sarah Johnson ( STU002 )", issueDate: "Feb 09, 2024", imageName: "book.fill")
    ]
}

struct BookRequestCard: View {
    let bookRequest: BookRequest
    @Binding var showAlert: Bool
    @Binding var alertMessage: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: bookRequest.imageName) // Display book image
                    .resizable()
                    .scaledToFit()
                    .frame(width: 50, height: 50)
                    .foregroundColor(.blue)
                    .padding(.trailing, 8)
                
                VStack(alignment: .leading) {
                    Text(bookRequest.name)
                        .font(.headline)
                    Text(bookRequest.author)
                        .font(.subheadline)
                        .foregroundColor(.gray)
                }
                Spacer()
            }
            
            HStack
            {
                Image(systemName: "person.circle.fill")
                    .foregroundColor(.gray)
                Text(bookRequest.issuer)
                    .font(.subheadline)
                    .foregroundColor(.gray)
            }
                    
            HStack
            {
                Image(systemName: "clock.fill")
                    .foregroundColor(.gray)
                Text(bookRequest.issueDate)
                    .font(.subheadline)
                    .foregroundColor(.gray)
            }
            
            HStack {
                Button(action: {
                    alertMessage = "Request Accepted"
                    showAlert = true
                }) {
                    Text("Accept")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.green)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                }
                
                Button(action: {
                    alertMessage = "Request Rejected"
                    showAlert = true
                }) {
                    Text("Reject")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.red)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                }
            }
        }
        .background(Color(.white))
    }
}
