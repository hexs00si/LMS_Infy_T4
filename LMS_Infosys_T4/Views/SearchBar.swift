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

func filterBooks(items: [Book], searchText: String) -> [Book] {
    if searchText.count < 2 {
        return items
    }
    
    let searchText = searchText.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
    
    return items.filter { book in
        
        let titleMatch = book[keyPath: \Book.title].localizedCaseInsensitiveContains(searchText)
        let authorMatch = book[keyPath: \Book.author].localizedCaseInsensitiveContains(searchText)
        let genreMatch = book[keyPath: \Book.genre].localizedCaseInsensitiveContains(searchText)
        
        // Special handling for year
        let yearMatch: Bool
        if let searchYear = Int(searchText) {
            yearMatch = book[keyPath: \Book.publishYear] == searchYear
        } else {
            yearMatch = false
        }
        
        return titleMatch || authorMatch || genreMatch || yearMatch
    }
}
