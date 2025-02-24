import SwiftUI

struct EmptyLibraryView: View {
    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: "books.vertical")
                .font(.system(size: 50))
                .foregroundColor(.gray.opacity(0.5)) // Lighter for subtle effect
            
            Text("No Libraries Added Yet")
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(.primary)
            
            Text("Add your first library using the + button above")
                .font(.system(size: 14))
                .foregroundColor(.gray.opacity(0.7))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 30)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity) // Centering inside parent
    }
}

#Preview {
    EmptyLibraryView()
}
