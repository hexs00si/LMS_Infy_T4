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
    var onLibrarianAdded: (() -> Void)?
    
    @State private var email = ""
    @State private var name = ""
    @State private var gender = "Male"
    @State private var phoneNumber = ""
    @State private var selectedLibrary: Library?
    @State private var showLibraryPicker = false
    @State private var showError = false
    @State private var errorMessage = ""
    @State private var phoneErrorMessage: String? = nil
    
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
                        .onChange(of: phoneNumber) { newValue in
                            phoneNumber = newValue.filter { $0.isNumber }
                            if phoneNumber.count > 10 || phoneNumber.count < 10 {
                                phoneErrorMessage = "Phone number must be of 10 digits"
                                phoneNumber = String(phoneNumber.prefix(10))
                            } else {
                                phoneErrorMessage = nil
                            }
                        }
                    
                    if let error = phoneErrorMessage {
                        Text(error)
                            .font(.caption)
                            .foregroundColor(.red)
                            .padding(.top, 2)
                    }
                    
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
                    dismiss()
                }
                    .disabled(!isFormValid)
            )
            .alert("Error", isPresented: $showError) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(errorMessage)
            }
            .sheet(isPresented: $showLibraryPicker) {
                LibraryPickerView(selectedLibrary: $selectedLibrary)
            }
        }
    }
    
    private var isFormValid: Bool {
        !name.isEmpty &&
        !email.isEmpty &&
        email.contains("@") &&
        //        !phoneNumber.isEmpty &&
        phoneNumber.count == 10 &&
        selectedLibrary != nil
    }
    
    private func saveLibrarian() {
        guard let library = selectedLibrary else { return }
        
        if viewModel.librarians.contains(where: { $0.name == name && $0.email == email }) {
            errorMessage = "A librarian with this name and email already exists."
            showError = true
            return
        }
        
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
                print(error)
            }
        }
    }
}
