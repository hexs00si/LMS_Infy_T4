//
//  AddLibrarianView.swift
//  LMS_Infosys_T4
//
//  Created by Gaganveer Bawa on 23/02/25.
//


// AddLibrarianView.swift
import SwiftUI

struct AddLibrarianView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var viewModel: LibrarianViewModel
    
    @State private var email = ""
    @State private var name = ""
    @State private var gender = "Male"
    @State private var phoneNumber = ""
    @State private var selectedLibrary: Library?
    @State private var showLibraryPicker = false
    
    let genderOptions = ["Male", "Female", "Other"]
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("PERSONAL DETAILS")) {
                    TextField("Full Name", text: $name)
                    TextField("Email", text: $email)
                        .keyboardType(.emailAddress)
                        .autocapitalization(.none)
                    TextField("Phone Number", text: $phoneNumber)
                        .keyboardType(.phonePad)
                    
                    Picker("Gender", selection: $gender) {
                        ForEach(genderOptions, id: \.self) { gender in
                            Text(gender).tag(gender)
                        }
                    }
                }
                
                Section(header: Text("LIBRARY ASSIGNMENT")) {
                    if let library = selectedLibrary {
                        HStack {
                            VStack(alignment: .leading) {
                                Text(library.name)
                                    .font(.headline)
                                Text(library.location)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            Spacer()
                            Button("Change") {
                                showLibraryPicker = true
                            }
                        }
                    } else {
                        Button("Select Library") {
                            showLibraryPicker = true
                        }
                    }
                }
            }
            .navigationTitle("Add Librarian")
            .navigationBarItems(
                leading: Button("Cancel") { dismiss() },
                trailing: Button("Save") {
                    saveLibrarian()
                }
                .disabled(!isFormValid)
            )
            .sheet(isPresented: $showLibraryPicker) {
                LibraryPickerView(selectedLibrary: $selectedLibrary)
            }
        }
    }
    
    private var isFormValid: Bool {
        !name.isEmpty &&
        !email.isEmpty &&
        email.contains("@") &&
        !phoneNumber.isEmpty &&
        selectedLibrary != nil
    }
    
    private func saveLibrarian() {
        guard let library = selectedLibrary else { return }
        
        Task {
            do {
                try await viewModel.createLibrarian(
                    email: email,
                    name: name,
                    gender: gender,
                    phoneNumber: phoneNumber,
                    libraryID: library.id ?? ""
                )
                await MainActor.run {
                    dismiss()
                }
            } catch {
                // Error handling is already done in viewModel
            }
        }
    }
}