//
//  TapBookCard.swift
//  LMS_Infosys_T4
//
//  Created by Shravan Rajput on 27/02/25.
//

import SwiftUI

struct TopBookCard: View {
    let book: Book
    let rank: Int
    @State private var showingBookDetail = false
    
    var body: some View {
        Button(action: {
            showingBookDetail = true
        }) {
            HStack(spacing: 12) {
                // Rank label
                ZStack {
                    Circle()
                        .fill(getColorForRank(rank))
                        .frame(width: 36, height: 36)
                    
                    Text("\(rank)")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(.white)
                }
                
                // Book cover
                if let coverImage = book.getCoverImage() {
                    Image(uiImage: coverImage)
                        .resizable()
                        .scaledToFill()
                        .frame(width: 60, height: 90)
                        .clipped()
                        .cornerRadius(6)
                } else {
                    Image(systemName: "book")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 60, height: 90)
                        .padding()
                        .foregroundColor(.gray)
                        .background(Color.gray.opacity(0.1))
                        .cornerRadius(6)
                }
                
                // Book details
                VStack(alignment: .leading, spacing: 4) {
                    Text(book.title)
                        .font(.headline)
                        .lineLimit(2)
                        .foregroundColor(.primary)
                    
                    Text(book.author)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                    
                    HStack {
                        Text("Issued:")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        Text("\(book.bookIssueCount) times")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(.blue)
                    }
                    
                    Text("Genre: \(book.genre)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                // Chevron indicator
                Image(systemName: "chevron.right")
                    .foregroundColor(.gray)
                    .font(.system(size: 14))
            }
            .padding()
            .background(Color.white)
            .cornerRadius(12)
            .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
        }
        .buttonStyle(PlainButtonStyle())
        .sheet(isPresented: $showingBookDetail) {
            NavigationView {
                BookDetailView(book: book)
            }
        }
    }
    
    private func getColorForRank(_ rank: Int) -> Color {
        switch rank {
        case 1:
            return Color.yellow // Gold for 1st place
        case 2:
            return Color.gray // Silver for 2nd place
        case 3:
            return Color(red: 0.8, green: 0.5, blue: 0.2) // Bronze for 3rd place
        default:
            return Color.blue // Blue for other ranks
        }
    }
}
