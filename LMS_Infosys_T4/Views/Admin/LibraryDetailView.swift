import SwiftUI
import FirebaseFirestore
import MapKit
import CoreLocation

struct LibraryDetailView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var viewModel: LibrariesViewModel
    let library: Library
    
    @State private var isEditing = false
    @State private var showingDeleteAlert = false
    @State private var editedName: String
    @State private var editedFinePerDay: Float
    @State private var editedMaxBooksPerUser: Int
    @State private var showLocationPicker = false
    
    // Map related states
    @State private var selectedCoordinate: CLLocationCoordinate2D?
    @State private var locationName = ""
    @State private var customLocation = ""
    
    init(library: Library, viewModel: LibrariesViewModel) {
        self.library = library
        self.viewModel = viewModel
        _editedName = State(initialValue: library.name)
        _editedFinePerDay = State(initialValue: library.finePerDay)
        _editedMaxBooksPerUser = State(initialValue: library.maxBooksPerUser)
        _selectedCoordinate = State(initialValue: library.coordinate)
        _locationName = State(initialValue: "")
        
        // Check if the location appears to be a custom name
        if !library.location.contains(",") {
            _customLocation = State(initialValue: library.location)
        } else {
            _customLocation = State(initialValue: "")
            _locationName = State(initialValue: library.location)
        }
    }
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("LIBRARY DETAILS")) {
                    if isEditing {
                        TextField("Name", text: $editedName)
                        
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
                                Text("Update Location on Map")
                                    .foregroundColor(.blue)
                            }
                            .padding(.vertical, 8)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(PlainButtonStyle())
                    } else {
                        LabeledContent("Name", value: library.name)
                        LabeledContent("Location", value: library.location)
                        
                        // Show map in non-editing mode
                        Map(coordinateRegion: .constant(MKCoordinateRegion(
                            center: library.coordinate,
                            span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
                        )), annotationItems: [MapAnnotationItem(coordinate: library.coordinate)]) { item in
                            MapMarker(coordinate: item.coordinate, tint: .red)
                        }
                        .frame(height: 150)
                        .cornerRadius(8)
                    }
                }
                
                Section(header: Text("CONFIGURATION")) {
                    if isEditing {
                        HStack {
                            Text("₹")
                            TextField("", value: $editedFinePerDay, format: .number)
                                .keyboardType(.decimalPad)
                                .frame(width: 60)
                            Text("/day")
                                .foregroundColor(.gray)
                        }
                        Stepper("Max Books: \(editedMaxBooksPerUser)", value: $editedMaxBooksPerUser, in: 1...20)
                    } else {
                        LabeledContent("Fine Per Day", value: "₹\(String(format: "%.2f", library.finePerDay))")
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
                        saveChanges()
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
            .sheet(isPresented: $showLocationPicker) {
                MapSelectionView(
                    coordinate: $selectedCoordinate,
                    locationName: $locationName,
                    customLocation: $customLocation,
                    initialRegion: MKCoordinateRegion(
                        center: library.coordinate,
                        span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
                    )
                )
            }
        }
    }
    
    private func saveChanges() {
        // Use the custom location if provided, otherwise use the map location name
        let finalLocation = !customLocation.isEmpty ? customLocation : locationName
        
        // Use selected coordinates or fallback to library's existing coordinates
        let coordinates = selectedCoordinate ?? library.coordinate
        
        Task {
            await viewModel.updateLibrary(
                library,
                name: editedName,
                location: finalLocation,
                latitude: coordinates.latitude,
                longitude: coordinates.longitude,
                finePerDay: editedFinePerDay,
                maxBooksPerUser: editedMaxBooksPerUser
            )
            isEditing = false
            dismiss()
        }
    }
}
