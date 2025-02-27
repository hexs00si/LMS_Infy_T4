import SwiftUI
import MapKit

struct LibraryRowView: View {
    let library: Library
    let onTap: () -> Void
    @ObservedObject var viewModel: LibrariesViewModel
    @State private var isActive: Bool
    
    init(library: Library, viewModel: LibrariesViewModel, onTap: @escaping () -> Void) {
        self.library = library
        self.viewModel = viewModel
        self.onTap = onTap
        _isActive = State(initialValue: library.isActive)
    }
    
    var body: some View {
        Button(action: onTap) {
            HStack(alignment: .top, spacing: 12) {
                // Library details
                VStack(alignment: .leading, spacing: 10) {
                    // Header with Library Name
                    Text(library.name)
                        .font(.system(size: 18, weight: .semibold))
                    
                    // Location information - show either custom or map location or both if available
                    if library.location.contains(",") {
                        // This is likely a map-provided location
                        HStack(spacing: 8) {
                            Image(systemName: "location.fill")
                                .font(.system(size: 14))
                                .foregroundColor(.gray)
                            Text(library.location)
                                .font(.system(size: 15))
                                .foregroundColor(.gray)
                                .lineLimit(1)
                        }
                    } else if !library.location.isEmpty {
                        // This is likely a custom location
                        HStack(spacing: 8) {
                            Image(systemName: "building.2.fill")
                                .font(.system(size: 14))
                                .foregroundColor(.gray)
                            Text(library.location)
                                .font(.system(size: 15))
                                .foregroundColor(.gray)
                                .lineLimit(1)
                        }
                    }
                    
                    // Display book count and loan duration
                    HStack(spacing: 8) {
                        Image(systemName: "book.fill")
                            .font(.system(size: 14))
                            .foregroundColor(.gray)
                        Text("\(library.totalBooks) books")
                            .font(.system(size: 15))
                            .foregroundColor(.gray)
                    }
                    
                    HStack(spacing: 8) {
                        Image(systemName: "clock.fill")
                            .font(.system(size: 14))
                            .foregroundColor(.gray)
                        Text("\(library.loanDuration) days loan period")
                            .font(.system(size: 15))
                            .foregroundColor(.gray)
                    }
                    
                    Spacer()
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                
                // Right side with map and active toggle
//                VStack(spacing: 12) {
//                    // Map preview
//                    Map(coordinateRegion: .constant(MKCoordinateRegion(
//                        center: library.coordinate,
//                        span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
//                    )), interactionModes: [], annotationItems: [MapAnnotationItem(coordinate: library.coordinate)]) { item in
//                        MapMarker(coordinate: item.coordinate, tint: .red)
//                    }
//                    .frame(width: 80, height: 80)
//                    .cornerRadius(8)
//                    .overlay(
//                        RoundedRectangle(cornerRadius: 8)
//                            .stroke(Color.gray.opacity(0.3), lineWidth: 1)
//                    )
//                    
//                    // Active toggle
//                    Toggle("", isOn: $isActive)
//                        .labelsHidden()
//                        .onChange(of: isActive) { newValue in
//                            Task {
//                                await viewModel.updateLibraryActiveStatus(library, isActive: newValue)
//                            }
//                        }
//                }
            }
            .padding(.vertical, 16)
            .padding(.horizontal, 20)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color(.systemGray6))
                    .shadow(
                        color: Color.black.opacity(0.08),
                        radius: 8,
                        x: 0,
                        y: 4
                    )
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(Color.gray.opacity(0.1), lineWidth: 1)
            )
        }
        .buttonStyle(PlainButtonStyle())
        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
            Button(role: .destructive) {
                Task {
                    await viewModel.deleteLibrary(library)
                }
            } label: {
                Label("Delete", systemImage: "trash")
            }
        }
    }
}
