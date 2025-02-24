import SwiftUI
import MapKit
import CoreLocation

struct AddLibraryView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var viewModel: LibrariesViewModel
    
    @State private var name = ""
    @State private var customLocation = ""
    @State private var finePerDay: Double = 1.0
    @State private var maxBooksPerUser = 5
    @State private var loanDuration = 14
    @State private var showLibrarianSelection = false
    @State private var showLocationPicker = false
    
    // Map related states
    @State private var selectedCoordinate: CLLocationCoordinate2D?
    @State private var locationName = ""
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("LIBRARY DETAILS")) {
                    TextField("Library Name", text: $name)
                    
                    // Show either mapped location or a message to select location
                    if !locationName.isEmpty {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Location")
                                .font(.caption)
                                .foregroundColor(.gray)
                            Text(locationName)
                                .lineLimit(2)
                        }
                    }
                    
                    // Custom location field is optional and can be used with map location
                    if !customLocation.isEmpty {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Custom Location")
                                .font(.caption)
                                .foregroundColor(.gray)
                            Text(customLocation)
                        }
                    }
                    
                    Button(action: {
                        showLocationPicker = true
                    }) {
                        HStack {
                            Image(systemName: "map")
                                .foregroundColor(.blue)
                            Text(selectedCoordinate == nil ? "Select Location on Map" : "Change Location on Map")
                                .foregroundColor(.blue)
                        }
                        .padding(.vertical, 8)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(PlainButtonStyle())
                }
                
                Section(header: Text("CONFIGURATION")) {
                    HStack {
                        Text("₹")
                        TextField("", value: $finePerDay, format: .number)
                            .keyboardType(.decimalPad)
                            .frame(width: 60)
                        Text("/day")
                            .foregroundColor(.gray)
                    }
                    
                    Stepper("Maximum Books: \(maxBooksPerUser)", value: $maxBooksPerUser, in: 1...20)
                    
                    // Added loan duration configuration
                    Stepper("Loan Duration: \(loanDuration) days", value: $loanDuration, in: 1...60)
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
                .disabled(!canSave)
            )
            .sheet(isPresented: $showLocationPicker) {
                MapSelectionView(
                    coordinate: $selectedCoordinate,
                    locationName: $locationName,
                    customLocation: $customLocation,
                    initialRegion: selectedCoordinate.map { coord in
                        MKCoordinateRegion(
                            center: coord,
                            span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
                        )
                    }
                )
            }
        }
    }
    
    private var canSave: Bool {
        return !name.isEmpty && selectedCoordinate != nil && (!locationName.isEmpty || !customLocation.isEmpty)
    }
    
    private func saveLibrary() {
        // Use the custom location if provided, otherwise use the map location name
        let finalLocation = !customLocation.isEmpty ? customLocation : locationName
        
        guard let coordinates = selectedCoordinate else { return }
        
        Task {
            await viewModel.createLibrary(
                name: name,
                location: finalLocation,
                latitude: coordinates.latitude,
                longitude: coordinates.longitude,
                finePerDay: Float(finePerDay),
                maxBooksPerUser: maxBooksPerUser,
                loanDuration: loanDuration // Add the loan duration parameter
            )
            dismiss()
        }
    }
}
