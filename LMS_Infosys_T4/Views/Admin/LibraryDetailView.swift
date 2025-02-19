//
//  LibraryDetailView.swift
//  LMS_Infosys_T4
//
//  Created by Shravan Rajput on 19/02/25.
//

import SwiftUI
import FirebaseFirestore

struct LibraryDetailView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var viewModel: LibrariesViewModel
    let library: Library
    
    @State private var isEditing = false
    @State private var showingDeleteAlert = false
    @State private var editedName: String
    @State private var editedLocation: String
    @State private var editedFinePerDay: Float
    @State private var editedMaxBooksPerUser: Int
    
    init(library: Library, viewModel: LibrariesViewModel) {
        self.library = library
        self.viewModel = viewModel
        _editedName = State(initialValue: library.name)
        _editedLocation = State(initialValue: library.location)
        _editedFinePerDay = State(initialValue: library.finePerDay)
        _editedMaxBooksPerUser = State(initialValue: library.maxBooksPerUser)
    }
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("LIBRARY DETAILS")) {
                    if isEditing {
                        TextField("Name", text: $editedName)
                        TextField("Location", text: $editedLocation)
                    } else {
                        LabeledContent("Name", value: library.name)
                        LabeledContent("Location", value: library.location)
                    }
                }
                
                Section(header: Text("CONFIGURATION")) {
                    if isEditing {
                        HStack {
                            Text("$")
                            TextField("Fine Per Day", value: $editedFinePerDay, format: .number)
                                .keyboardType(.decimalPad)
                        }
                        Stepper("Max Books: \(editedMaxBooksPerUser)", value: $editedMaxBooksPerUser, in: 1...20)
                    } else {
                        LabeledContent("Fine Per Day", value: "$\(String(format: "%.2f", library.finePerDay))")
                        LabeledContent("Max Books Per User", value: "\(library.maxBooksPerUser)")
                        LabeledContent("Loan Duration", value: "\(library.loanDuration) days")
                        LabeledContent("Total Books", value: "\(library.totalBooks)")
                    }
                }
                
                Section(header: Text("STATUS")) {
                    LabeledContent("Active", value: library.isActive ? "Yes" : "No")
                    LabeledContent("Last Updated", value: library.lastUpdated.formatted(date: .long, time: .shortened))
                }
                
                if !isEditing {
                    Section {
                        Button(role: .destructive) {
                            showingDeleteAlert = true
                        } label: {
                            HStack {
                                Spacer()
                                Text("Delete Library")
                                Spacer()
                            }
                        }
                    }
                }
            }
            .navigationTitle(isEditing ? "Edit Library" : "Library Details")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(
                leading: Button("Done") {
                    dismiss()
                },
                trailing: Button(isEditing ? "Save" : "Edit") {
                    if isEditing {
                        Task {
                            await viewModel.updateLibrary(
                                library,
                                name: editedName,
                                location: editedLocation,
                                finePerDay: editedFinePerDay,
                                maxBooksPerUser: editedMaxBooksPerUser
                            )
                            isEditing = false
                        }
                    } else {
                        isEditing = true
                    }
                }
            )
            .alert("Delete Library", isPresented: $showingDeleteAlert) {
                Button("Cancel", role: .cancel) { }
                Button("Delete", role: .destructive) {
                    Task {
                        await viewModel.deleteLibrary(library)
                        dismiss()
                    }
                }
            } message: {
                Text("Are you sure you want to delete this library? This action cannot be undone.")
            }
        }
    }
}
