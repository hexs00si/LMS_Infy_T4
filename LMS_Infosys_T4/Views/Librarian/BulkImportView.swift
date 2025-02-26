//
//  BulkImportView.swift
//  libraraian 1
//
//  Created by Kinshuk Garg on 14/02/25.
//
//import SwiftUI
//
//struct BulkImportView: View {
//    @ObservedObject var viewModel: LibraryViewModel
//    @State private var showingFilePicker = false
//
//    var body: some View {
//        ScrollView {
//            VStack(spacing: 20) {
//                // File Requirements Section
//                VStack(alignment: .leading, spacing: 20) {
//                    Text("File Requirements")
//                        .font(.title2)
//                        .fontWeight(.semibold)
//
//                    Group {
//                        HStack {
//                            Image(systemName: "doc.text.fill")
//                            Text("Required Columns")
//                        }
//                        .font(.subheadline)
//
//                        Text("ISBN, Title, Author, Publisher, Year")
//                            .foregroundColor(.gray)
//                    }
//
//                    Group {
//                        HStack {
//                            Image(systemName: "info.circle.fill")
//                            Text("File Format")
//                        }
//                        .font(.subheadline)
//
//                        Text("First row must contain column headers")
//                            .foregroundColor(.gray)
//                    }
//                }
//                .padding(.horizontal)
//
//                // Choose File Button Section (now at the top)
//                VStack(spacing: 15) {
//                    Button(action: {
//                        showingFilePicker = true
//                    }) {
//                        Text("Choose File")
//                            .font(.headline)
//                            .foregroundColor(.white)
//                            .frame(maxWidth: .infinity)
//                            .padding(.vertical, 14)
//                            .background(Color.blue)
//                            .cornerRadius(12)
//                    }
//
//                    Text("Supported format: .CSV")
//                        .font(.caption)
//                        .foregroundColor(.gray)
//                }
//                .padding(.horizontal)
//
//                // Import Button Section (just below Choose File)
//                Button(action: {
//                    // Import action
//                }) {
//                    Text("Import Books")
//                        .font(.headline)
//                        .foregroundColor(.white)
//                        .frame(maxWidth: .infinity)
//                        .padding(.vertical, 14)
//                        .background(Color.blue)
//                        .cornerRadius(12)
//                }
//                .padding(.horizontal)
//                .padding(.bottom, 20)
//            }
//            .padding(.top)
//        }
//        .navigationTitle("Bulk Import")
//        .sheet(isPresented: $showingFilePicker) {
//            Text("File Picker")
//        }
//        .ignoresSafeArea(.keyboard, edges: .bottom) // Avoids keyboard issues
//    }
//}
//
//
//#Preview {
//    BulkImportView(viewModel: LibraryViewModel())
//}



import SwiftUI
import UniformTypeIdentifiers

struct BulkImportView: View {
    @ObservedObject var viewModel: LibraryViewModel
    @State private var showingFilePicker = false
    @State private var fileURL: URL? = nil
    @State private var importStatus: String = ""
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // File Requirements Section
                VStack(alignment: .leading, spacing: 20) {
                    Text("File Requirements")
                        .font(.title2)
                        .fontWeight(.semibold)
                    
                    Group {
                        HStack {
                            Image(systemName: "doc.text.fill")
                            Text("Required Columns")
                        }
                        .font(.subheadline)
                        
                        Text("ISBN, Title, Author, Publisher, Publication Year")
                            .foregroundColor(.gray)
                    }
                    
                    Group {
                        HStack {
                            Image(systemName: "info.circle.fill")
                            Text("File Format")
                        }
                        .font(.subheadline)
                        
                        Text("First row must contain column headers")
                            .foregroundColor(.gray)
                    }
                }
                .padding(.horizontal)
                
                // Choose File Button Section
                VStack(spacing: 15) {
                    Button(action: {
                        showingFilePicker = true
                    }) {
                        Text("Choose File")
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(Color.blue)
                            .cornerRadius(12)
                    }
                    
                    Text("Supported format: .CSV")
                        .font(.caption)
                        .foregroundColor(.gray)
                }
                .padding(.horizontal)
                
                // Display selected file name
                if let fileURL = fileURL {
                    Text("Selected File: \(fileURL.lastPathComponent)")
                        .font(.subheadline)
                        .foregroundColor(.blue)
                }
                
                // Import Button Section
                Button(action: {
                    if let fileURL = fileURL {
                        parseCSV(fileURL: fileURL)
                    } else {
                        importStatus = "Please select a file first."
                    }
                }) {
                    Text("Import Books")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(Color.blue)
                        .cornerRadius(12)
                }
                .padding(.horizontal)
                .padding(.bottom, 20)
                
                // Import Status
                if !importStatus.isEmpty {
                    Text(importStatus)
                        .font(.subheadline)
                        .foregroundColor(.red)
                }
            }
            .padding(.top)
        }
        .navigationTitle("Bulk Import")
        .fileImporter(
            isPresented: $showingFilePicker,
            allowedContentTypes: [UTType.commaSeparatedText],
            allowsMultipleSelection: false
        ) { result in
            switch result {
            case .success(let fileURLs):
                if let url = fileURLs.first {
                    // Retain access to this file for future use
                    if url.startAccessingSecurityScopedResource() {
                        fileURL = url
                        importStatus = "File selected: \(url.lastPathComponent)"
                    } else {
                        importStatus = "Error: Unable to access the selected file."
                    }
                }
            case .failure(let error):
                // Specific error handling for permission issues
                if let errorCode = (error as NSError?)?.code {
                    if errorCode == NSFileReadNoPermissionError {
                        print(error)
                        importStatus = "Error: You do not have permission to read this file."
                    } else {
                        importStatus = "Error selecting file: \(error.localizedDescription)"
                    }
                } else {
                    importStatus = "Error selecting file: \(error.localizedDescription)"
                }
            }
        }
        .ignoresSafeArea(.keyboard, edges: .bottom)
    }
    private func parseCSV(fileURL: URL) {
        // Start accessing the security-scoped resource
        guard fileURL.startAccessingSecurityScopedResource() else {
            importStatus = "Permission denied: Cannot access the file."
            return
        }
        
        defer {
            // Ensure we stop accessing the resource when done
            fileURL.stopAccessingSecurityScopedResource()
        }
        
        do {
            let data = try String(contentsOf: fileURL, encoding: .utf8)
            let rows = data.components(separatedBy: "\n")
            guard rows.count > 1 else {
                importStatus = "CSV file is empty or invalid."
                return
            }
            
            // Parse rows
            for (index, row) in rows.enumerated() {
                if index == 0 { continue } // Skip header row
                let columns = row.components(separatedBy: ",")
                if columns.count >= 5 {
                    let isbn = columns[0].trimmingCharacters(in: .whitespacesAndNewlines)
                    let title = columns[1].trimmingCharacters(in: .whitespacesAndNewlines)
                    let author = columns[2].trimmingCharacters(in: .whitespacesAndNewlines)
                    let publisher = columns[3].trimmingCharacters(in: .whitespacesAndNewlines)
                    let year = columns[4].trimmingCharacters(in: .whitespacesAndNewlines)
                    let genre = columns.count > 5 ? columns[5].trimmingCharacters(in: .whitespacesAndNewlines) : nil
                    
//                    let newBook = Book(
//                        isbn: isbn,
//                        title: title,
//                        author: author,
//                        publisher: publisher,
//                        year: year,
//                        genre: genre
//                    )
                    
//                    viewModel.addBook(newBook)
                }
            }
            importStatus = "Books imported successfully!"
        } catch {
            importStatus = "Error reading CSV file: \(error.localizedDescription)"
        }
    }
}

#Preview {
    BulkImportView(viewModel: LibraryViewModel())
}
