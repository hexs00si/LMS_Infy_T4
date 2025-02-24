import SwiftUI
import MapKit

struct LibraryRowView: View {
    let library: Library
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack(alignment: .top, spacing: 12) {
                // Library details
                VStack(alignment: .leading, spacing: 12) {
                    // Header with Library Name
                    Text(library.name)
                        .font(.system(size: 18, weight: .semibold))
                    
                    // Location with icon
                    HStack(spacing: 8) {
                        Image(systemName: "location.fill")
                            .font(.system(size: 14))
                            .foregroundColor(.gray)
                        Text(library.location)
                            .font(.system(size: 15))
                            .foregroundColor(.gray)
                            .lineLimit(1)
                    }
                    
                    Spacer()
                    
                    // Footer with Date
                    HStack {
                        Image(systemName: "calendar")
                            .font(.system(size: 12))
                            .foregroundColor(.gray)
                        Text(library.lastUpdated, style: .date)
                            .font(.system(size: 13))
                            .foregroundColor(.gray)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                
                // Map preview
                Map(coordinateRegion: .constant(MKCoordinateRegion(
                    center: library.coordinate,
                    span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
                )), interactionModes: [], annotationItems: [MapAnnotationItem(coordinate: library.coordinate)]) { item in
                    MapMarker(coordinate: item.coordinate, tint: .red)
                }
                .frame(width: 80, height: 80)
                .cornerRadius(8)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                )
            }
            .padding(.vertical, 16)
            .padding(.horizontal, 20)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.white)
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
    }
}
