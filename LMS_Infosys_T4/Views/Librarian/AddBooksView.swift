//
//  AddBooksView.swift
//  libraraian 1
//
//  Created by Kinshuk Garg on 14/02/25.
//


import SwiftUI

struct AddBooksView: View {
    @ObservedObject var viewModel: LibraryViewModel
    
    var body: some View {
        List {
            NavigationLink(destination: AddSingleBookView(viewModel: viewModel)) {
                HStack {
                    Image(systemName: "doc.text")
                        .foregroundColor(.blue)
                        .frame(width: 40, height: 40)
                        .background(Color.blue.opacity(0.1))
                        .cornerRadius(8)
                    
                    VStack(alignment: .leading) {
                        Text("Add Single Book")
                            .font(.headline)
                        Text("Add books one at a time with detailed information")
                            .font(.subheadline)
                            .foregroundColor(.gray)
                    }
                }
            }
            
            NavigationLink(destination: BulkImportView(viewModel: viewModel)) {
                HStack {
                    Image(systemName: "arrow.up.doc")
                        .foregroundColor(.blue)
                        .frame(width: 40, height: 40)
                        .background(Color.blue.opacity(0.1))
                        .cornerRadius(8)
                    
                    VStack(alignment: .leading) {
                        Text("Bulk Import")
                            .font(.headline)
                        Text("Import multiple books using CSV file")
                            .font(.subheadline)
                            .foregroundColor(.gray)
                    }
                }
            }
        }
        .navigationTitle("Add Books")
    }
}

#Preview {
    AddBooksView(viewModel: LibraryViewModel())
}
