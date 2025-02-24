//
//  IssueView.swift
//  library
//
//  Created by Udayveer Chhina on 20/02/25.
//

import SwiftUI

struct IssueView: View {
    @State private var bookRequests = BookRequestData.requests
    @State private var showAlert = false
    @State private var alertMessage = ""

    var body: some View {
        NavigationStack {
            List {
                Section(header: Text("Pending Book Requests (\(bookRequests.count))").font(.headline)) {
                    ForEach(bookRequests) { request in
                        BookRequestCard(
                            bookRequest: request,
                            showAlert: $showAlert,
                            alertMessage: $alertMessage
                        )
                    }
                }
            }
            .listStyle(.insetGrouped)
            .refreshable {
                // Simulate a refresh, replace this with API call if needed
                await Task.sleep(1_000_000_000)
            }
            .alert("Notice", isPresented: $showAlert) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(alertMessage)
            }
        }
    }
}

#Preview {
    IssueView()
}
