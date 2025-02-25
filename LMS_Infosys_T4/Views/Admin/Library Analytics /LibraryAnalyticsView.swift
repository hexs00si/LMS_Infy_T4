//
//  LibraryAnalyticsView.swift
//  LMS_Infosys_T4
//
//  Created by Kinshuk Garg on 25/02/25.
//

import SwiftUI
import Charts
import FirebaseFirestore

struct LibraryAnalyticsView: View {
    @StateObject private var viewModel = LibraryAnalyticsViewModel()
    @State private var timeFrame: TimeFrame = .week
    @State private var selectedTimeRange: String = "This Month"
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    // Time range selector below navigation title
                    Menu {
                        Button("This Month", action: {
                            viewModel.setTimeRange(to: .month)
                            selectedTimeRange = "This Month"
                        })
                        Button("Last Month", action: {
                            viewModel.setTimeRange(to: .lastMonth)
                            selectedTimeRange = "Last Month"
                        })
                        Button("This Year", action: {
                            viewModel.setTimeRange(to: .year)
                            selectedTimeRange = "This Year"
                        })
                    } label: {
                        HStack {
                            Image(systemName: "calendar")
                            Text(selectedTimeRange)
                            Image(systemName: "chevron.down")
                        }
                        .foregroundColor(.blue)
                        .padding(.horizontal)
                    }
                    
                    // Top Stats - Fixed equal sizes
                    HStack(spacing: 16) {
                        StatCard(
                            value: "\(viewModel.stats.checkouts)",
                            label: "Checkouts"
                        )
                        .frame(height: 100)
                        
                        StatCard(
                            value: "\(viewModel.stats.activeUsers)",
                            label: "Active\nUsers"
                        )
                        .frame(height: 100)
                        
                        StatCard(
                            value: "$\(viewModel.stats.totalFines)",
                            label: "Total Fines"
                        )
                        .frame(height: 100)
                    }
                    .padding(.horizontal)
                    
                    // Most Borrowed Books
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Most Borrowed Books")
                            .font(.title2)
                            .fontWeight(.bold)
                            .padding(.horizontal)
                        
                        if viewModel.isLoading {
                            ProgressView()
                                .frame(maxWidth: .infinity)
                                .padding()
                        } else {
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 16) {
                                    // Temporary Book Card
                                    TemporaryBookCard(
                                        title: "The Great Gatsby",
                                        author: "F. Scott Fitzgerald",
                                        checkouts: 42
                                    )
                                    
                                    // Actual book data
                                    ForEach(viewModel.popularBooks) { book in
                                        PopularBookCard(book: book)
                                    }
                                }
                                .padding(.horizontal)
                            }
                        }
                    }
                    
                    // Fines & Late Returns
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Fines & Late Returns")
                            .font(.title2)
                            .fontWeight(.bold)
                            .padding(.horizontal)
                        
                        HStack(spacing: 16) {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Average Fine")
                                    .foregroundColor(.secondary)
                                    .font(.subheadline)
                                
                                Text("$\(String(format: "%.2f", viewModel.stats.averageFine))")
                                    .font(.title)
                                    .fontWeight(.bold)
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                            
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Late Returns")
                                    .foregroundColor(.secondary)
                                    .font(.subheadline)
                                
                                Text("\(viewModel.stats.lateReturns)")
                                    .font(.title)
                                    .fontWeight(.bold)
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                        }
                        .padding(.horizontal)
                        
                        HStack(spacing: 16) {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Outstanding")
                                    .foregroundColor(.secondary)
                                    .font(.subheadline)
                                
                                Text("$\(viewModel.stats.outstandingFines)")
                                    .font(.title)
                                    .fontWeight(.bold)
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                            
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Overdue Books")
                                    .foregroundColor(.secondary)
                                    .font(.subheadline)
                                
                                Text("\(viewModel.stats.overdueBooks)")
                                    .font(.title)
                                    .fontWeight(.bold)
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                        }
                        .padding(.horizontal)
                    }
                    
                    // Borrowing Trends
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Borrowing Trends")
                            .font(.title2)
                            .fontWeight(.bold)
                            .padding(.horizontal)
                        
                        VStack {
                            // Time frame selector
                            HStack {
                                Picker("Time Frame", selection: $timeFrame) {
                                    ForEach(TimeFrame.allCases, id: \.self) { frame in
                                        Text(frame.rawValue.capitalized).tag(frame)
                                    }
                                }
                                .pickerStyle(SegmentedPickerStyle())
                                .onChange(of: timeFrame) { newValue in
                                    // Use the local timeFrame state variable instead of accessing it through viewModel
                                    viewModel.fetchBorrowingTrends(for: newValue)
                                }
                            }
                            .padding(.horizontal)
                            
                            if viewModel.isLoadingTrends {
                                ProgressView()
                                    .frame(height: 250)
                                    .frame(maxWidth: .infinity)
                            } else {
                                // Chart
                                Chart {
                                    ForEach(viewModel.borrowingTrends) { dataPoint in
                                        LineMark(
                                            x: .value("Day", dataPoint.day),
                                            y: .value("Checkouts", dataPoint.count)
                                        )
                                        .foregroundStyle(Color.blue)
                                        .symbol(Circle())
                                    }
                                }
                                .frame(height: 250)
                                .chartYScale(domain: 0...100)
                                .chartXAxis {
                                    AxisMarks(values: viewModel.borrowingTrends.map { $0.day }) { day in
                                        AxisValueLabel()
                                    }
                                }
                                .padding()
                            }
                        }
                        .background(Color(.systemGray6))
                        .cornerRadius(12)
                        .padding(.horizontal)
                    }
                    
                    // Download buttons
                    HStack(spacing: 16) {
                        Button(action: {
                            viewModel.downloadCSV()
                        }) {
                            Text("Download CSV")
                                .fontWeight(.medium)
                                .frame(maxWidth: .infinity)
                                .padding()
                        }
                        .buttonStyle(.bordered)
                        .tint(.blue)
                        
                        Button(action: {
                            viewModel.downloadPDF()
                        }) {
                            Text("Download PDF")
                                .fontWeight(.medium)
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding()
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(.blue)
                    }
                    .padding(.horizontal)
                }
                .padding(.vertical)
            }
            .navigationTitle("Library Analytics")
            .alert(item: $viewModel.alertItem) { alertItem in
                Alert(
                    title: Text(alertItem.title),
                    message: Text(alertItem.message),
                    dismissButton: .default(Text("OK"))
                )
            }
        }
        .onAppear {
            viewModel.loadData()
        }
    }
}

struct StatCard: View {
    let value: String
    let label: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(value)
                .font(.title)
                .fontWeight(.bold)
            
            Text(label)
                .foregroundColor(.secondary)
                .font(.subheadline)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

struct TemporaryBookCard: View {
    let title: String
    let author: String
    let checkouts: Int
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            ZStack {
                Rectangle()
                    .fill(Color.blue.opacity(0.2))
                    .frame(width: 120, height: 160)
                    .cornerRadius(8)
                
                Image(systemName: "book.fill")
                    .font(.system(size: 40))
                    .foregroundColor(.blue.opacity(0.6))
            }
            
            Text(title)
                .font(.headline)
                .lineLimit(1)
            
            Text(author)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .lineLimit(1)
            
            Text("\(checkouts) checkouts")
                .font(.caption)
                .foregroundColor(.blue)
        }
        .frame(width: 120)
        .padding(.vertical, 8)
        .padding(.horizontal, 8)
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

struct PopularBookCard: View {
    let book: BookAnalytics
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            ZStack {
                if let uiImage = book.getBookCoverImage() {
                    Image(uiImage: uiImage)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: 120, height: 160)
                        .cornerRadius(8)
                        .clipped()
                } else {
                    Rectangle()
                        .fill(Color.gray.opacity(0.3))
                        .frame(width: 120, height: 160)
                        .cornerRadius(8)
                    
                    Image(systemName: "book.closed")
                        .font(.system(size: 40))
                        .foregroundColor(.gray)
                }
            }
            
            Text(book.title)
                .font(.headline)
                .lineLimit(1)
            
            Text(book.author)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .lineLimit(1)
            
            Text("\(book.checkouts) checkouts")
                .font(.caption)
                .foregroundColor(.blue)
        }
        .frame(width: 120)
        .padding(.vertical, 8)
        .padding(.horizontal, 8)
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

struct LibraryAnalyticsView_Previews: PreviewProvider {
    static var previews: some View {
        LibraryAnalyticsView()
    }
}
