//
//  BookListView.swift
//  LMS_Infosys_T4
//
//  Created by Bhumi on 27/02/25.
//

import SwiftUI

struct BookListView: View {
    let title: String
    let books: [Book]
    @ObservedObject var viewModel: LibraryViewModel
    
    @State private var selectedBook: Book? // Tracks selected book
    
    var body: some View {
        List {
            ForEach(books) { book in
                Button(action: {
                    selectedBook = book
                }) {
                    BookListItemView(book: book, viewModel: viewModel)
                }
                .buttonStyle(PlainButtonStyle()) 
            }
        }
        .navigationTitle(title)
        .listStyle(PlainListStyle())
        .navigationDestination(item: $selectedBook) { book in
            BookDetailsView(book: book, viewModel: viewModel)
        }
    }
}
