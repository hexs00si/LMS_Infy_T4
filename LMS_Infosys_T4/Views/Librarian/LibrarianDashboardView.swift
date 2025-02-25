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
                        }
                        .padding()
                        
                        // Recent Activities
                        VStack(alignment: .leading, spacing: 15) {
                            Text("Recent Activities")
                                .font(.headline)
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
            
            NavigationView {
//                BookIssueRequestsView()
                BookRequestsView()
            }
            .tabItem {
                Label("Issue Requests", systemImage: "doc.text.magnifyingglass")
            }
            
            Text("Profile")
                .tabItem { Label("Profile", systemImage: "person") }
        }
    }
}

#Preview {
    LibrarianDashboardView()
}
