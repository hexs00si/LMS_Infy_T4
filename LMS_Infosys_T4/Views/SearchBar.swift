import SwiftUI

struct SearchBar: View {
    @Binding var text: String
    var placeholder: String
    
    var body: some View {
        HStack {
            TextField(placeholder, text: $text)
                .padding(10)
                .padding(.horizontal, 25)
                .background(Color(.systemGray6))
                .cornerRadius(8)
                .overlay(
                    HStack {
                        Image(systemName: "magnifyingglass")
                            .foregroundColor(.gray)
                            .padding(.leading, 8)
                        Spacer()
                    }
                )
                .padding(.horizontal)
        }
    }
}

func filterItems<T: Identifiable>(items: [T], searchText: String, keyPath: KeyPath<T, String>) -> [T] {
    if searchText.isEmpty {
        return items
    } else {
        return items.filter { $0[keyPath: keyPath].localizedCaseInsensitiveContains(searchText) }
    }
}
