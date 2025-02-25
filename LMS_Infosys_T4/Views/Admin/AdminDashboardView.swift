//
//  AdminDashboardView.swift
//  LMS_Infosys_T4
//
//  Created by Shravan Rajput on 18/02/25.
//

import SwiftUI

struct AdminDashboardView: View {
    var body: some View {
        TabView {
            LibrariesView()
                .tabItem {
                    Image(systemName: "books.vertical.fill")
                    Text("Libraries")
                }
            
            LibrariansView()
                .tabItem {
                    Image(systemName: "person.2.fill")
                    Text("Librarians")
                }
            
            LibraryAnalyticsView()
                .tabItem {
                    Image(systemName: "chart.bar.fill")
                    Text("Reports")
                }
        }
    }
}
