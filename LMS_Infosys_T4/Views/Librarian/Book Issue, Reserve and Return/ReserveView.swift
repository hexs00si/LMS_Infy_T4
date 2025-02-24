//
//  ReserveView.swift
//  library
//
//  Created by Udayveer Chhina on 20/02/25.
//

import SwiftUI

struct BookReservation: Identifiable {
    let id = UUID()
    let name: String
    let author: String
    let queue: String
    let issueDate: String
    let status: String
    let imageName: String
}

struct ReserveView: View {
    @State private var searchText = ""
    
    let reservations = [
        BookReservation(name: "The Design of Everyday Things", author: "Don Norman", queue: "Queue #1 • Student", issueDate: "Jan 15, 2024", status: "Reserved", imageName: "book.fill"),
        BookReservation(name: "Clean Code: A Handbook of Agile Software", author: "Robert C. Martin", queue: "Queue #2 • Faculty", issueDate: "Jan 14, 2024", status: "Available", imageName: "book.fill"),
        BookReservation(name: "Learning Python", author: "Mark Lutz", queue: "Queue #3 • Student", issueDate: "Jan 13, 2024", status: "Reserved", imageName: "book.fill")
    ]
    
    var filteredReservations: [BookReservation] {
        if searchText.isEmpty {
            return reservations
        } else {
            return reservations.filter { $0.name.localizedCaseInsensitiveContains(searchText) }
        }
    }
    
    var body: some View {
        NavigationStack {
            List {
                Section(header: Text("Current Reservations (\(filteredReservations.count))").font(.headline)) {
                    ForEach(filteredReservations) { book in
                        BookReservationCard(book: book)
                    }
                }
            }
            .listStyle(.insetGrouped)
            .searchable(text: $searchText, prompt: "Search by book title or author")
            .refreshable {
                // Simulate data refresh (You can replace this with real API fetching)
                await Task.sleep(1_000_000_000)
            }
        }
    }
}

struct BookReservationCard: View {
    let book: BookReservation
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: book.imageName)
                .resizable()
                .scaledToFit()
                .frame(width: 40, height: 40)
                .foregroundColor(.blue)
            
            VStack(alignment: .leading) {
                Text(book.name)
                    .font(.headline)
                Text(book.author)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                HStack {
                    Image(systemName: "person.circle.fill")
                    Text(book.queue)
                    Spacer()
                    Text(book.status)
                        .font(.caption)
                        .padding(6)
                        .background(book.status == "Available" ? Color.green.opacity(0.2) : Color.red.opacity(0.2))
                        .foregroundColor(book.status == "Available" ? .green : .red)
                        .cornerRadius(6)
                }
                .font(.subheadline)
                .foregroundColor(.gray)
                
                HStack {
                    Image(systemName: "clock.fill")
                    Text("Reserved on \(book.issueDate)")
                        .font(.footnote)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding(.vertical, 8)
    }
}

#Preview {
    ReserveView()
}
