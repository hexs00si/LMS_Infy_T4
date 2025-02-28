//
//  FinesView.swift
//  LMS_Infosys_T4
//
//  Created by Dakshdeep Singh on 28/02/25.
//

import SwiftUI
import Firebase

struct FinesView: View {
    @ObservedObject var viewModel: LibraryViewModel
    @State private var fines: [Fine] = []
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var showError = false
    @State private var showingPaidFines = true
    
    var filteredFines: [Fine] {
        showingPaidFines ? fines : fines.filter { !$0.isPaid }
    }
    
    var totalUnpaidAmount: Double {
        fines.filter { !$0.isPaid }.reduce(0) { $0 + $1.fineAmount }
    }

    var body: some View {
        ZStack {
            VStack {
                // Summary Card
                VStack(spacing: 0) {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Total Unpaid Fines")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                            
                            Text("Rs. \(totalUnpaidAmount, specifier: "%.2f")")
                                .font(.title2)
                                .fontWeight(.bold)
                                .foregroundColor(totalUnpaidAmount > 0 ? .red : .green)
                        }
                        
                        Spacer()
                        
                        VStack(alignment: .trailing, spacing: 4) {
                            Text("Total Fines")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                            
                            Text("\(fines.count)")
                                .font(.title2)
                                .fontWeight(.bold)
                        }
                    }
                    .padding()
                    
                    // Filter Options
                    Picker("Filter", selection: $showingPaidFines) {
                        Text("All Fines").tag(true)
                        Text("Unpaid Only").tag(false)
                    }
                    .pickerStyle(.segmented)
                    .padding(.horizontal)
                    .padding(.bottom)
                }
                .background(Color(.systemBackground))
                .cornerRadius(10)
                .shadow(color: Color.black.opacity(0.1), radius: 5)
                .padding(.horizontal)
                .padding(.top, 8)
                
                if filteredFines.isEmpty && !isLoading {
                    Spacer()
                    VStack(spacing: 15) {
                        Image(systemName: "indianrupeesign.circle")
                            .font(.system(size: 50))
                            .foregroundColor(.secondary)
                        
                        Text(showingPaidFines ? "No fines found" : "No unpaid fines")
                            .font(.headline)
                        
                        Text(showingPaidFines ? "Any fines imposed will appear here" : "All fines have been paid")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                    }
                    Spacer()
                } else {
                    List {
                        ForEach(filteredFines) { fine in
                            FineRow(fine: fine, viewModel: viewModel)
                        }
                    }
                    .listStyle(InsetGroupedListStyle())
                    .refreshable {
                        await loadFines()
                    }
                }
            }
            .navigationTitle("Fines")
            .navigationBarTitleDisplayMode(.inline)
            .onAppear {
                Task {
                    await loadFines()
                }
            }

            if isLoading {
                Color.black.opacity(0.2)
                    .edgesIgnoringSafeArea(.all)
                
                ProgressView()
                    .scaleEffect(1.5)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .alert("Error", isPresented: $showError) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(errorMessage ?? "An unknown error occurred")
        }
    }

    private func loadFines() async {
        isLoading = true
        defer { isLoading = false }

        do {
            fines = try await viewModel.fetchFines()
            fines.sort { !$0.isPaid && $1.isPaid } // Show unpaid fines first
        } catch {
            errorMessage = error.localizedDescription
            showError = true
        }
    }
}
struct FineRow: View {
    let fine: Fine
    @ObservedObject var viewModel: LibraryViewModel
    @State private var isMarkingAsPaid = false
    @State private var showDetails = false
    @State private var userName: String? = nil

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Fine #\(fine.id.prefix(8).uppercased())")
                        .font(.headline)

                    HStack(spacing: 12) {
                        Label {
                            Text("\(fine.imposedDate.formatted(date: .abbreviated, time: .omitted))")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        } icon: {
                            Image(systemName: "calendar")
                                .foregroundColor(.secondary)
                        }

                        Text("•")
                            .foregroundColor(.secondary)

                        Label {
                            Text("\(fine.fineAmount, specifier: "%.2f")")
                                .font(.subheadline)
                                .fontWeight(.semibold)
                                .foregroundColor(.primary)
                        } icon: {
                            Image(systemName: "indianrupeesign")
                                .foregroundColor(.secondary)
                        }
                    }
                }

                Spacer()

                VStack(alignment: .trailing) {
                    Text(fine.isPaid ? "Paid" : "Unpaid")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(fine.isPaid ? Color.green.opacity(0.2) : Color.red.opacity(0.2))
                        .foregroundColor(fine.isPaid ? .green : .red)
                        .cornerRadius(10)

                    Button(action: {
                        withAnimation {
                            showDetails.toggle()
                        }
                    }) {
                        Text(showDetails ? "Hide Details" : "Show Details")
                            .font(.caption)
                            .foregroundColor(.blue)
                    }
                    .padding(.top, 4)
                }
            }
            .padding(.vertical, 12)
            .contentShape(Rectangle()) // Ensures only this part is tappable
            .onTapGesture {
                showDetails.toggle()
            }

            // Expandable details
            if showDetails {
                Divider()
                    .padding(.vertical, 8)

                VStack(alignment: .leading, spacing: 10) {
                    Text("Fine Details")
                        .font(.headline)
                        .foregroundColor(.secondary)

                    DetailRow(title: "Fine ID", value: fine.id)
                    DetailRow(title: "User ID", value: fine.userId)

                    if let userName = userName {
                        DetailRow(title: "User Name", value: userName)
                    }

                    DetailRow(title: "Imposed Date", value: fine.imposedDate.formatted())
                    DetailRow(title: "Status", value: fine.isPaid ? "Paid" : "Unpaid")

                    if !fine.isPaid {
                        Button(action: {
                            Task {
                                await markAsPaid()
                            }
                        }) {
                            HStack {
                                Text("Mark as Paid")

                                if isMarkingAsPaid {
                                    Spacer()
                                    ProgressView()
                                        .scaleEffect(0.8)
                                }
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(10)
                        }
                        .disabled(isMarkingAsPaid)
                        .padding(.top, 8)
                    }
                }
                .padding(.bottom, 10)
            }
        }
        .padding(.horizontal, 8)
        .background(Color(.systemBackground))
        .cornerRadius(10)
        .onAppear {
            Task {
                await fetchUserName()
            }
        }
    }

    private func markAsPaid() async {
        isMarkingAsPaid = true
        defer { isMarkingAsPaid = false }

        do {
            try await viewModel.markFineAsPaid(fineId: fine.id)
        } catch {
            print("Failed to mark fine as paid: \(error.localizedDescription)")
        }
    }

    private func fetchUserName() async {
        do {
            userName = try await viewModel.fetchUserName(for: fine.userId)
        } catch {
            print("Failed to fetch user name: \(error.localizedDescription)")
        }
    }
}



struct DetailRow: View {
    let title: String
    let value: String
    
    var body: some View {
        HStack(alignment: .top) {
            Text(title)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .frame(width: 100, alignment: .leading)
            
            Text(value)
                .font(.subheadline)
            
            Spacer()
        }
    }
}
