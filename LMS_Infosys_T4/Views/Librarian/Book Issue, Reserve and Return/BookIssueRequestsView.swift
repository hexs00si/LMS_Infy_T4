//
//  BookIssueRequestsView.swift
//  library
//
//  Created by Udayveer Chhina on 20/02/25.
//

import SwiftUI

struct BookIssueRequestsView: View {
    @State private var selectedSegment = 0
    let segments = ["Issue", "Reserve", "Return"]
    
    var body: some View {
        VStack {
            // Segmented Picker
            Picker("Library Actions", selection: $selectedSegment) {
                ForEach(0..<segments.count, id: \.self) { index in
                    Text(segments[index]).tag(index)
                }
            }
            .pickerStyle(.segmented)
            .padding(.horizontal)

            // Dynamic View Display
            Spacer()
            Group {
                switch selectedSegment {
                case 0:
                    IssueView()
                case 1:
                    ReserveView()
                default:
                    ReturnView()
                }
            }
            .animation(.easeInOut, value: selectedSegment)
        }
        .navigationTitle("Requests")
    }
}

// Preview
#Preview {
    BookIssueRequestsView()
}
