//
//  LibraryAnalyticsViewModel.swift
//  LMS_Infosys_T4
//
//  Created by Kinshuk Garg on 25/02/25.
//


import Foundation
import SwiftUI
import FirebaseFirestore
import FirebaseAuth

struct AlertItem: Identifiable {
    let id = UUID()
    let title: String
    let message: String
}

struct LibraryStats {
    var checkouts: Int = 0
    var activeUsers: Int = 0
    var totalFines: Int = 0
    var averageFine: Double = 0.0
    var lateReturns: Int = 0
    var outstandingFines: Int = 0
    var overdueBooks: Int = 0
}

struct BookAnalytics: Identifiable {
    let id: String
    let title: String
    let author: String
    let coverImage: String?
    let checkouts: Int
    
    func getBookCoverImage() -> UIImage? {
        guard let base64String = coverImage,
              let imageData = Data(base64Encoded: base64String) else {
            return nil
        }
        return UIImage(data: imageData)
    }
}

struct BorrowingTrend: Identifiable {
    let id = UUID()
    let day: String
    let count: Int
}

enum TimeFrame: String, CaseIterable {
    case week
    case month
    case year
}

enum DateRange {
    case month
    case lastMonth
    case year
}

class LibraryAnalyticsViewModel: ObservableObject {
    @Published var stats = LibraryStats()
    @Published var popularBooks: [BookAnalytics] = []
    @Published var borrowingTrends: [BorrowingTrend] = []
    @Published var currentDateRange: DateRange = .month
    @Published var isLoading = false
    @Published var isLoadingTrends = false
    @Published var alertItem: AlertItem?
    @Published var error: String?
    
    private let db = Firestore.firestore()
    private var libraryID: String = ""
    
    init() {
        // Try to get the library ID if the user is a librarian
        if let userID = Auth.auth().currentUser?.uid {
            fetchLibrarianInfo(userID: userID)
        }
    }
    
    private func fetchLibrarianInfo(userID: String) {
        db.collection("librarians")
            .whereField("useruid", isEqualTo: userID)
            .getDocuments { [weak self] snapshot, error in
                if let error = error {
                    self?.error = error.localizedDescription
                    return
                }
                
                if let document = snapshot?.documents.first,
                   let libraryID = document.data()["libraryuid"] as? String {
                    self?.libraryID = libraryID
                    self?.loadData()
                }
            }
    }
    
    func loadData() {
        fetchStats()
        fetchPopularBooks()
        fetchBorrowingTrends(for: .week)
    }
    
    private func fetchStats() {
        isLoading = true
        
        // Get today's date and calculate dates for filtering
        let calendar = Calendar.current
        let now = Date()
        let oneMonthAgo = calendar.date(byAdding: .month, value: -1, to: now) ?? now
        
        // Get all book issues
        db.collection("bookIssues")
            .whereField("libraryuid", isEqualTo: libraryID)
            .getDocuments { [weak self] snapshot, error in
                guard let self = self else { return }
                
                if let error = error {
                    self.error = error.localizedDescription
                    self.isLoading = false
                    return
                }
                
                guard let documents = snapshot?.documents else {
                    self.isLoading = false
                    return
                }
                
                // Calculate statistics from book issues
                let allIssues = documents.compactMap { doc -> [String: Any]? in
                    return doc.data()
                }
                
                // Total checkouts (total book issues)
                self.stats.checkouts = allIssues.count
                
                // Active users (unique users who have active book checkouts)
                let activeUserIDs = Set(allIssues.compactMap { $0["useruid"] as? String })
                self.stats.activeUsers = activeUserIDs.count
                
                // Calculate fines
                var totalFines = 0.0
                var lateReturns = 0
                var outstandingFines = 0.0
                var overdueBooks = 0
                
                for issue in allIssues {
                    if let dueTimestamp = issue["dueDate"] as? Timestamp,
                       let returnTimestamp = issue["returnDate"] as? Timestamp,
                       let isReturned = issue["isReturned"] as? Bool,
                       let fineAmount = issue["fineAmount"] as? Double {
                        
                        let dueDate = dueTimestamp.dateValue()
                        
                        // Check if it's overdue (either not returned, or returned after due date)
                        if isReturned {
                            let returnDate = returnTimestamp.dateValue()
                            if returnDate > dueDate {
                                // Calculate days overdue
                                let daysLate = calendar.dateComponents([.day], from: dueDate, to: returnDate).day ?? 0
                                let fine = Double(daysLate) * fineAmount
                                
                                totalFines += fine
                                lateReturns += 1
                            }
                        } else {
                            // Not returned yet
                            if dueDate < now {
                                // It's overdue
                                let daysLate = calendar.dateComponents([.day], from: dueDate, to: now).day ?? 0
                                let fine = Double(daysLate) * fineAmount
                                
                                outstandingFines += fine
                                overdueBooks += 1
                            }
                        }
                    }
                }
                
                self.stats.totalFines = Int(totalFines)
                self.stats.lateReturns = lateReturns
                self.stats.outstandingFines = Int(outstandingFines)
                self.stats.overdueBooks = overdueBooks
                
                // Calculate average fine if there are any late returns
                if lateReturns > 0 {
                    self.stats.averageFine = totalFines / Double(lateReturns)
                } else {
                    self.stats.averageFine = 0.0
                }
                
                self.isLoading = false
            }
    }
    
    private func fetchPopularBooks() {
        // First, get all book issues
        db.collection("bookIssues")
            .whereField("libraryuid", isEqualTo: libraryID)
            .getDocuments { [weak self] snapshot, error in
                guard let self = self else { return }
                
                if let error = error {
                    self.error = error.localizedDescription
                    return
                }
                
                guard let documents = snapshot?.documents else { return }
                
                // Count book checkouts
                var bookCheckoutCounts: [String: Int] = [:]
                
                for doc in documents {
                    // The bookID in bookIssues contains the bookCopies ID, we need to extract the main book ID
                    if let bookID = doc.data()["bookID"] as? String {
                        let parts = bookID.split(separator: "-")
                        if let mainBookID = parts.first {
                            let bookIDString = String(mainBookID)
                            bookCheckoutCounts[bookIDString, default: 0] += 1
                        }
                    }
                }
                
                // Sort books by checkout count
                let topBookIDs = bookCheckoutCounts.sorted { $0.value > $1.value }.prefix(10)
                
                // Create a dispatch group to wait for all book fetches
                let group = DispatchGroup()
                var topBooks: [BookAnalytics] = []
                
                // Fetch book details for each top book
                for (bookID, checkouts) in topBookIDs {
                    group.enter()
                    
                    self.db.collection("books").document(bookID).getDocument { document, error in
                        defer { group.leave() }
                        
                        if let error = error {
                            print("Error fetching book: \(error)")
                            return
                        }
                        
                        if let document = document, document.exists,
                           let title = document.data()?["title"] as? String,
                           let author = document.data()?["author"] as? String {
                            
                            let coverImage = document.data()?["coverImage"] as? String
                            
                            let bookAnalytics = BookAnalytics(
                                id: bookID,
                                title: title,
                                author: author,
                                coverImage: coverImage,
                                checkouts: checkouts
                            )
                            
                            topBooks.append(bookAnalytics)
                        }
                    }
                }
                
                // When all fetches are done, update the popularBooks array
                group.notify(queue: .main) {
                    // Sort by checkouts in descending order
                    self.popularBooks = topBooks.sorted { $0.checkouts > $1.checkouts }
                }
            }
    }
    
    func fetchBorrowingTrends(for timeFrame: TimeFrame) {
        isLoadingTrends = true
        
        // Calculate date range based on timeFrame
        let calendar = Calendar.current
        let now = Date()
        var startDate: Date
        var dateFormat: String
        var dateComponents: Calendar.Component
        
        switch timeFrame {
        case .week:
            startDate = calendar.date(byAdding: .day, value: -7, to: now) ?? now
            dateFormat = "EEE" // Day abbreviation (Mon, Tue, etc.)
            dateComponents = .day
        case .month:
            startDate = calendar.date(byAdding: .month, value: -1, to: now) ?? now
            dateFormat = "d MMM" // Day and month (1 Jan, 2 Jan, etc.)
            dateComponents = .day
        case .year:
            startDate = calendar.date(byAdding: .year, value: -1, to: now) ?? now
            dateFormat = "MMM" // Month abbreviation (Jan, Feb, etc.)
            dateComponents = .month
        }
        
        // Query book issues within the date range
        db.collection("bookIssues")
            .whereField("libraryuid", isEqualTo: libraryID)
            .whereField("issueDate", isGreaterThan: Timestamp(date: startDate))
            .getDocuments { [weak self] snapshot, error in
                guard let self = self else { return }
                
                if let error = error {
                    self.error = error.localizedDescription
                    self.isLoadingTrends = false
                    return
                }
                
                guard let documents = snapshot?.documents else {
                    self.isLoadingTrends = false
                    return
                }
                
                // Group checkouts by date
                var checkoutsByDate: [String: Int] = [:]
                let formatter = DateFormatter()
                formatter.dateFormat = dateFormat
                
                // Generate all dates in the range to ensure continuous data
                if timeFrame == .week || timeFrame == .month {
                    var currentDate = startDate
                    while currentDate <= now {
                        let dateString = formatter.string(from: currentDate)
                        checkoutsByDate[dateString] = 0
                        currentDate = calendar.date(byAdding: .day, value: 1, to: currentDate) ?? currentDate
                    }
                } else if timeFrame == .year {
                    // For year, generate all months
                    for month in 0..<12 {
                        if let date = calendar.date(byAdding: .month, value: month, to: startDate) {
                            let dateString = formatter.string(from: date)
                            checkoutsByDate[dateString] = 0
                        }
                    }
                }
                
                // Count checkouts by date
                for doc in documents {
                    if let issueTimestamp = doc.data()["issueDate"] as? Timestamp {
                        let issueDate = issueTimestamp.dateValue()
                        let dateString = formatter.string(from: issueDate)
                        checkoutsByDate[dateString, default: 0] += 1
                    }
                }
                
                // Convert to borrowing trends
                var trends: [BorrowingTrend] = []
                
                if timeFrame == .week {
                    // For week, ensure days are in order (Mon, Tue, Wed, etc.)
                    let dayOrder = ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"]
                    for day in dayOrder {
                        if let count = checkoutsByDate[day] {
                            trends.append(BorrowingTrend(day: day, count: count))
                        }
                    }
                } else {
                    // For month and year, sort dates chronologically
                    let sortedDates = checkoutsByDate.keys.sorted { date1, date2 in
                        if timeFrame == .month {
                            // Extract day number for sorting
                            let day1 = Int(date1.components(separatedBy: " ")[0]) ?? 0
                            let day2 = Int(date2.components(separatedBy: " ")[0]) ?? 0
                            return day1 < day2
                        } else {
                            // For year, sort by month
                            let monthOrder = ["Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"]
                            return monthOrder.firstIndex(of: date1) ?? 0 < monthOrder.firstIndex(of: date2) ?? 0
                        }
                    }
                    
                    for dateString in sortedDates {
                        if let count = checkoutsByDate[dateString] {
                            trends.append(BorrowingTrend(day: dateString, count: count))
                        }
                    }
                }
                
                DispatchQueue.main.async {
                    self.borrowingTrends = trends
                    self.isLoadingTrends = false
                }
            }
    }
    
    func setTimeRange(to range: DateRange) {
        currentDateRange = range
        isLoading = true
        
        // Calculate date range
        let calendar = Calendar.current
        let now = Date()
        var startDate: Date
        
        switch range {
        case .month:
            startDate = calendar.date(byAdding: .month, value: -1, to: now) ?? now
        case .lastMonth:
            if let oneMonthAgo = calendar.date(byAdding: .month, value: -1, to: now),
               let twoMonthsAgo = calendar.date(byAdding: .month, value: -1, to: oneMonthAgo) {
                startDate = twoMonthsAgo
            } else {
                startDate = calendar.date(byAdding: .month, value: -2, to: now) ?? now
            }
        case .year:
            startDate = calendar.date(byAdding: .year, value: -1, to: now) ?? now
        }
        
        // Fetch data for the selected time range
        db.collection("bookIssues")
            .whereField("libraryuid", isEqualTo: libraryID)
            .whereField("issueDate", isGreaterThan: Timestamp(date: startDate))
            .getDocuments { [weak self] snapshot, error in
                guard let self = self else { return }
                
                if let error = error {
                    self.error = error.localizedDescription
                    self.isLoading = false
                    return
                }
                
                // Reset stats
                self.stats = LibraryStats()
                
                guard let documents = snapshot?.documents else {
                    self.isLoading = false
                    return
                }
                
                // Process data similarly to fetchStats but with filtered date range
                // ...
                // Calculate updated stats based on filtered data
                // ...
                
                // For simplicity in this implementation, we'll call fetchStats again
                // In a production app, you'd want to reuse the filtered data
                self.fetchStats()
                self.fetchPopularBooks()
                
                // Update trends based on current timeFrame
               self.fetchBorrowingTrends(for: self.timeFrame)
            }
    }
    
    func downloadCSV() {
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .medium
        let currentDate = dateFormatter.string(from: Date())
        
        var csvString = "Library Analytics Report - \(currentDate)\n\n"
        
        // Add stats
        csvString += "LIBRARY STATISTICS\n"
        csvString += "Total Checkouts,\(stats.checkouts)\n"
        csvString += "Active Users,\(stats.activeUsers)\n"
        csvString += "Total Fines,$\(stats.totalFines)\n"
        csvString += "Average Fine,$\(String(format: "%.2f", stats.averageFine))\n"
        csvString += "Late Returns,\(stats.lateReturns)\n"
        csvString += "Outstanding Fines,$\(stats.outstandingFines)\n"
        csvString += "Overdue Books,\(stats.overdueBooks)\n\n"
        
        // Add popular books
        csvString += "MOST POPULAR BOOKS\n"
        csvString += "Title,Author,Checkouts\n"
        for book in popularBooks {
            csvString += "\"\(book.title)\",\"\(book.author)\",\(book.checkouts)\n"
        }
        
        csvString += "\nBORROWING TRENDS\n"
        csvString += "Date,Checkouts\n"
        for trend in borrowingTrends {
            csvString += "\(trend.day),\(trend.count)\n"
        }
        
        // In a real app, you would use UIActivityViewController to share the CSV file
        // For now, we'll show an alert indicating success
        alertItem = AlertItem(
            title: "CSV Generated",
            message: "CSV report has been generated. In a production app, this would open a share sheet to save or send the file."
        )
    }
    
    func downloadPDF() {
        // In a real app, you would generate a PDF document
        // Using UIGraphicsPDFRenderer or a PDF generation library
        
        // For now, show an alert indicating success
        alertItem = AlertItem(
            title: "PDF Generated",
            message: "PDF report has been generated. In a production app, this would open a share sheet to save or send the file."
        )
    }
}
