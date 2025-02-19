//
//  AddLibraryView.swift
//  LMS_Infosys_T4
//
//  Created by Shravan Rajput on 19/02/25.
//

import SwiftUI

struct AddLibraryView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var viewModel: LibrariesViewModel
    
    @State private var name = ""
    @State private var location = ""
    @State private var finePerDay: Double = 1.0
    @State private var maxBooksPerUser = 5
    @State private var showLibrarianSelection = false
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("LIBRARY DETAILS")) {
                    TextField("Library Name", text: $name)
                    TextField("Library Address", text: $location)
                }
                
                Section {
                    HStack {
                        Text("$")
                        TextField("Fine Per Day", value: $finePerDay, format: .number)
                            .keyboardType(.decimalPad)
                    }
                    
                    Stepper("Maximum Books: \(maxBooksPerUser)", value: $maxBooksPerUser, in: 1...20)
                }
                
                Section {
                    NavigationLink("Select Librarians") {
                        // We'll add librarian selection view later
                        Text("Librarian Selection")
                    }
                }
            }
            .navigationTitle("Add Library")
            .navigationBarItems(
                leading: Button("Cancel") { dismiss() },
                trailing: Button("Save") {
                    saveLibrary()
                }
                .disabled(name.isEmpty || location.isEmpty)
            )
        }
    }
    
    private func saveLibrary() {
        Task {
            await viewModel.createLibrary(
                name: name,
                location: location,
                finePerDay: Float(finePerDay),
                maxBooksPerUser: maxBooksPerUser
            )
            dismiss()
        }
    }
}
