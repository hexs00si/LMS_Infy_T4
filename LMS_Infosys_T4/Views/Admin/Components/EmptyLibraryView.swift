import SwiftUI

struct EmptyLibraryView: View {
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "books.vertical")
                .font(.system(size: 70))
                .foregroundColor(.gray)
            
            Text("No Libraries")
                .font(.title2)
                .fontWeight(.bold)
            
            Text("Tap + to add your first library")
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.systemGroupedBackground))
    }
}

#Preview {
    EmptyLibraryView()
}
