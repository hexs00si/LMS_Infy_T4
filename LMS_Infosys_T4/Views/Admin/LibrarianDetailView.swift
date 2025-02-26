//
//  LibrarianDetailView.swift
//  LMS_Infosys_T4
//

import SwiftUI

struct LibrarianDetailView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var viewModel: LibrarianViewModel
    let librarian: Librarian
    
    @State private var isEditing = false
    @State private var showingDeleteAlert = false
    @State private var editedName: String
    @State private var editedGender: String
    @State private var editedPhoneNumber: String
    
    init(librarian: Librarian, viewModel: LibrarianViewModel) {
        self.librarian = librarian
        self.viewModel = viewModel
        _editedName = State(initialValue: librarian.name)
        _editedGender = State(initialValue: librarian.gender)
        _editedPhoneNumber = State(initialValue: librarian.phoneNumber)
    }
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("PERSONAL DETAILS")) {
                    if isEditing {
                        TextField("Name", text: $editedName)
                        Picker("Gender", selection: $editedGender) {
                            ForEach(["Male", "Female", "Other"], id: \.self) { gender in
                                Text(gender).tag(gender)
                            }
                        }
                        TextField("Phone Number", text: $editedPhoneNumber)
                            .keyboardType(.phonePad)
                    } else {
                        LabeledContent("Name", value: librarian.name)
                        LabeledContent("Gender", value: librarian.gender)
                        LabeledContent("Phone", value: librarian.phoneNumber)
                    }
                }
                
                Section(header: Text("LIBRARY ASSIGNMENT")) {
                    LabeledContent("Library", value: librarian.libraryName ?? "Unknown Library")
                    if let location = librarian.libraryLocation {
                        LabeledContent("Location", value: location)
                    }
                }
                
                Section(header: Text("ACCOUNT DETAILS")) {
                    LabeledContent("Email", value: librarian.email)
                    LabeledContent("Join Date", value: librarian.joinDate.formatted(date: .long, time: .omitted))
                }
                
                if !isEditing {
                    Section {
                        Button(role: .destructive) {
                            showingDeleteAlert = true
                        } label: {
                            HStack {
                                Spacer()
                                Text("Delete Librarian")
                                Spacer()
                            }
                        }
                    }
                }
            }
            .navigationTitle(isEditing ? "Edit Librarian" : "Librarian Details")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(
                leading: Button("Done") { dismiss() },
                trailing: Button(isEditing ? "Save" : "Edit") {
                    if isEditing {
                        Task {
                            await viewModel.updateLibrarian(
                                librarian,
                                name: editedName,
                                gender: editedGender,
                                phoneNumber: editedPhoneNumber
                            )
                            isEditing = false
                            dismiss()
                        }
                    } else {
                        isEditing = true
                    }
                }
            )
            .alert("Delete Librarian", isPresented: $showingDeleteAlert) {
                Button("Cancel", role: .cancel) { }
                Button("Delete", role: .destructive) {
                    Task {
                        await viewModel.deleteLibrarian(librarian)
                        dismiss()
                    }
                }
            } message: {
                Text("Are you sure you want to delete this librarian? This action cannot be undone.")
            }
        }
    }
}


struct LibraryPickerView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var librariesVM = LibrariesViewModel()
    @Binding var selectedLibrary: Library?
    
    var body: some View {
        NavigationView {
            List(librariesVM.libraries) { library in
                Button {
                    selectedLibrary = library
                    dismiss()
                } label: {
                    HStack {
                        VStack(alignment: .leading) {
                            Text(library.name)
                                .font(.headline)
                            Text(library.location)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        Spacer()
                        if selectedLibrary?.id == library.id {
                            Image(systemName: "checkmark")
                                .foregroundColor(.blue)
                        }
                    }
                }
            }
            .navigationTitle("Select Library")
            .navigationBarItems(trailing: Button("Cancel") { dismiss() })
        }
    }
}
