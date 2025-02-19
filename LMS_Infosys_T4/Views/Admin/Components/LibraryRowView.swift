//
//  LibraryRowView.swift
//  LMS_Infosys_T4
//
//  Created by Shravan Rajput on 19/02/25.
//

import SwiftUI

struct LibraryRowView: View {
    let library: Library
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 16) {
                // Header with Library Name
                Text(library.name)
                    .font(.system(size: 18, weight: .semibold))
                
                // Location with icon
                HStack(spacing: 8) {
                    Image(systemName: "location.fill")
                        .font(.system(size: 14))
                        .foregroundColor(.gray)
                    Text(library.location)
                        .font(.system(size: 15))
                        .foregroundColor(.gray)
                }
                
                Divider()
                
                // Footer with Date
                HStack {
                    Image(systemName: "calendar")
                        .font(.system(size: 12))
                        .foregroundColor(.gray)
                    Text(library.lastUpdated, style: .date)
                        .font(.system(size: 13))
                        .foregroundColor(.gray)
                }
            }
            .padding(.vertical, 16)
            .padding(.horizontal, 20)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.white)
                    .shadow(
                        color: Color.black.opacity(0.08),
                        radius: 8,
                        x: 0,
                        y: 4
                    )
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(Color.gray.opacity(0.1), lineWidth: 1)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}
