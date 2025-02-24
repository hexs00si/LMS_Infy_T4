//
//  LibrarianDashboardView.swift
//  LMS_Infosys_T4
//
//  Created by Shravan Rajput on 18/02/25.
//

import SwiftUI

struct LibrarianDashboardView: View {
    @StateObject private var viewModel = LibraryViewModel()
    
    var body: some View {
        TabView {
            NavigationView {
                ScrollView {
                    VStack(spacing: 20) {
                        // Stats Grid
                        LazyVGrid(columns: [
                            GridItem(.flexible()),
                            GridItem(.flexible())
                        ], spacing: 15) {
                            RoundRectangleView(title: "Total Books", value: "\(1)", color: .blue)
                            RoundRectangleView(title: "Books Issued", value: "\(2)", color: .green)
                            RoundRectangleView(title: "Due Returns", value: "\(3)", color: .orange)
                            RoundRectangleView(title: "New Imports", value: "\(4)", color: .purple)
//                            RoundRectangleView(title: "Total Books", value: "\(viewModel.totalBooks)", color: .blue)
//                            RoundRectangleView(title: "Books Issued", value: "\(viewModel.booksIssued)", color: .green)
//                            RoundRectangleView(title: "Due Returns", value: "\(viewModel.dueReturns)", color: .orange)
//                            RoundRectangleView(title: "New Imports", value: "\(viewModel.newImports)", color: .purple)
                        }
                        .padding()
                        
                        // Recent Activities
                        VStack(alignment: .leading, spacing: 15) {
                            Text("Recent Activities")
                                .font(.headline)
                            
//                            ForEach(viewModel.recentActivities, id: \.self) { activity in
//                                HStack {
//                                    Circle()
//                                        .fill(Color.blue)
//                                        .frame(width: 8, height: 8)
//                                    Text(activity)
//                                    Spacer()
//                                    Text("2 hours ago")
//                                        .foregroundColor(.gray)
//                                }
//                            }
                        }
                        .padding()
                        
                        // Profile Section
                        ProfileView()
                    }
                }
                .navigationTitle("Dashboard")
            }
            .tabItem {
                Label("Dashboard", systemImage: "square.grid.2x2")
            }
            
            NavigationView {
                AddBooksOptionView(viewModel: viewModel)
            }
            .tabItem {
                Label("Import", systemImage: "arrow.up.doc")
            }
            
            Text("Issue")
                .tabItem { Label("Issue", systemImage: "book") }
            Text("Profile")
                .tabItem { Label("Profile", systemImage: "person") }
        }
    }
}

#Preview {
    LibrarianDashboardView()
}
