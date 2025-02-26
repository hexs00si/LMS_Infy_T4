//
//  BookRequestsView.swift
//  LMS_Infosys_T4
//
//  Created by Gaganveer Bawa on 25/02/25.
//

//
//  BookRequestsView.swift
//  LMS_Infosys_T4
//
//  Created by Gaganveer Bawa on 25/02/25.
//

//
//  BookRequestsView.swift
//  LMS_Infosys_T4
//
//  Created by Gaganveer Bawa on 25/02/25.
//

import SwiftUI
import FirebaseFirestore
import FirebaseAuth

enum RequestTab {
    case bookRequests
    case reservations
}

struct BookRequestsView: View {
    @StateObject private var viewModel = LibraryViewModel()
    @State private var alertMessage = ""
    @State private var showAlert = false
    @State private var selectedTab: RequestTab = .bookRequests
    
    // Grid layout configuration
    private let columns = [
        GridItem(.adaptive(minimum: 300, maximum: 500), spacing: 16)
    ]
    
    var body: some View {
        NavigationStack {
            VStack {
                // Segmented control for switching between requests and reservations
                Picker("Request Type", selection: $selectedTab) {
                    Text("Book Requests").tag(RequestTab.bookRequests)
                    Text("Reservations").tag(RequestTab.reservations)
                }
                .pickerStyle(.segmented)
                .padding(.horizontal)
                .padding(.top, 8)
                
                ScrollView {
                    if viewModel.isLoading {
                        loadingView
                    } else {
                        if selectedTab == .bookRequests {
                            if viewModel.pendingRequests.isEmpty {
                                emptyRequestsView
                            } else {
                                requestsGrid
                            }
                        } else { // Reservations tab
                            if viewModel.activeReservations.isEmpty {
                                emptyReservationsView
                            } else {
                                reservationsGrid
                            }
                        }
                    }
                }
                .refreshable {
                    await refreshData()
                }
            }
            .navigationTitle(selectedTab == .bookRequests ? "Book Requests" : "Book Reservations")
            .background(Color(.systemGroupedBackground))
            .alert(alertMessage, isPresented: $showAlert) {
                Button("OK", role: .cancel) {}
            }
            .task {
                await refreshData()
            }
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        Task { await refreshData() }
                    } label: {
                        Image(systemName: "arrow.clockwise")
                            .imageScale(.medium)
                    }
                }
            }
            .onChange(of: selectedTab) { _ in
                Task { await refreshData() }
            }
        }
    }
    
    private var loadingView: some View {
        VStack {
            Spacer()
            ProgressView()
                .scaleEffect(1.5)
                .padding()
            Text("Loading...")
                .font(.callout)
                .foregroundColor(.secondary)
            Spacer()
        }
        .frame(maxWidth: .infinity, minHeight: 300)
    }
    
    private var emptyRequestsView: some View {
        VStack(spacing: 20) {
            Spacer()
            
            Image(systemName: "book.closed")
                .font(.system(size: 70))
                .foregroundColor(.secondary)
                .symbolEffect(.pulse)
            
            Text("No Pending Requests")
                .font(.title2)
                .fontWeight(.semibold)
            
            Text("When users request books, they'll appear here for your approval.")
                .font(.callout)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
            
            Spacer()
        }
        .frame(maxWidth: .infinity, minHeight: 400)
    }
    
    private var emptyReservationsView: some View {
        VStack(spacing: 20) {
            Spacer()
            
            Image(systemName: "calendar.badge.clock")
                .font(.system(size: 70))
                .foregroundColor(.secondary)
                .symbolEffect(.pulse)
            
            Text("No Active Reservations")
                .font(.title2)
                .fontWeight(.semibold)
            
            Text("When users reserve books, they'll appear here waiting for pickup.")
                .font(.callout)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
            
            Spacer()
        }
        .frame(maxWidth: .infinity, minHeight: 400)
    }
    
    private var requestsGrid: some View {
        LazyVGrid(columns: columns, spacing: 16) {
            ForEach(viewModel.pendingRequests) { request in
                RequestCard(request: request, viewModel: viewModel) { success, message in
                    alertMessage = message
                    showAlert = true
                    
                    if success {
                        Task {
                            await refreshData()
                        }
                    }
                }
            }
        }
        .padding()
    }
    
    private var reservationsGrid: some View {
        LazyVGrid(columns: columns, spacing: 16) {
            ForEach(viewModel.activeReservations) { reservation in
                ReservationCard(reservation: reservation, viewModel: viewModel) { success, message in
                    alertMessage = message
                    showAlert = true
                    
                    if success {
                        Task {
                            await refreshData()
                        }
                    }
                }
            }
        }
        .padding()
    }
    
    private func refreshData() async {
        do {
            if selectedTab == .bookRequests {
                try await viewModel.fetchPendingBookRequests()
            } else {
                try await viewModel.fetchActiveReservations()
            }
        } catch {
            alertMessage = "Error refreshing: \(error.localizedDescription)"
            showAlert = true
        }
    }
}

struct RequestCard: View {
    let request: BookRequest
    let viewModel: LibraryViewModel
    let completionHandler: (Bool, String) -> Void
    
    @State private var bookDetails: Book?
    @State private var userDetails: UserProfile?
    @State private var isLoadingDetails = true
    @State private var isProcessing = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Card header with book info
            bookHeaderView
                .padding(.horizontal, 16)
                .padding(.top, 16)
                .padding(.bottom, 8)
            
            Divider()
                .padding(.horizontal, 8)
            
            // Request details
            requestDetailsView
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
            
            Divider()
                .padding(.horizontal, 8)
            
            // Action buttons
            actionButtonsView
                .padding(16)
        }
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .shadow(color: Color.black.opacity(0.1), radius: 3, x: 0, y: 1)
        .task {
            await loadRelatedData()
        }
    }
    
    private var bookHeaderView: some View {
        HStack(alignment: .center, spacing: 12) {
            bookCoverView
            
            VStack(alignment: .leading, spacing: 4) {
                if isLoadingDetails {
                    Text("Loading book details...")
                        .font(.headline)
                        .foregroundColor(.secondary)
                    ProgressView()
                        .scaleEffect(0.7)
                } else if let book = bookDetails {
                    Text(book.title)
                        .font(.headline)
                        .lineLimit(1)
                    
                    Text("By \(book.author)")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                } else {
                    Text("Book details unavailable")
                        .font(.headline)
                        .foregroundColor(.red)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
    
    private var bookCoverView: some View {
        ZStack {
            Rectangle()
                .fill(Color.accentColor.opacity(0.1))
                .frame(width: 50, height: 65)
                .clipShape(RoundedRectangle(cornerRadius: 6))
            
            Image(systemName: "book")
                .font(.system(size: 24))
                .foregroundColor(.accentColor)
        }
    }
    
    private var requestDetailsView: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Request Information")
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundColor(.secondary)
                .padding(.bottom, 2)
            
            VStack(alignment: .leading, spacing: 8) {
                detailRow(label: "Requested On", value: formattedDate(request.requestDate))
                
                if let user = userDetails {
                    detailRow(label: "Requested By", value: user.name)
                    detailRow(label: "User Email", value: user.email)
                } else {
                    detailRow(label: "User ID", value: request.userId)
                }
                
                statusView
            }
        }
    }
    
    private var statusView: some View {
        HStack {
            Text("Status")
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(.secondary)
            
            Spacer()
            
            Text(request.status.capitalized)
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundColor(.white)
                .padding(.horizontal, 10)
                .padding(.vertical, 4)
                .background(Color.orange)
                .clipShape(Capsule())
        }
    }
    
    private var actionButtonsView: some View {
        HStack(spacing: 12) {
            Button(action: {
                processRequest(approve: false)
            }) {
                HStack {
                    Image(systemName: "xmark.circle.fill")
                    Text("Decline")
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(Color(.systemGray5))
                .foregroundColor(.red)
                .clipShape(RoundedRectangle(cornerRadius: 10))
            }
            .buttonStyle(.borderless)
            
            Button(action: {
                processRequest(approve: true)
            }) {
                HStack {
                    Image(systemName: "checkmark.circle.fill")
                    Text("Approve")
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(Color.green)
                .foregroundColor(.white)
                .clipShape(RoundedRectangle(cornerRadius: 10))
            }
            .buttonStyle(.borderless)
        }
        .disabled(isProcessing)
        .opacity(isProcessing ? 0.6 : 1)
        .overlay(
            Group {
                if isProcessing {
                    HStack {
                        ProgressView()
                            .tint(.white)
                        Text("Processing...")
                            .foregroundColor(.secondary)
                    }
                }
            }
        )
    }
    
    private func processRequest(approve: Bool) {
        isProcessing = true
        Task {
            do {
                if approve {
                    try await viewModel.approveBookRequest(request)
                    completionHandler(true, "Request approved successfully!")
                } else {
                    try await viewModel.rejectBookRequest(request)
                    completionHandler(true, "Request rejected.")
                }
                isProcessing = false
            } catch {
                isProcessing = false
                completionHandler(false, "Error: \(error.localizedDescription)")
            }
        }
    }
    
    private func loadRelatedData() async {
        isLoadingDetails = true
        
        do {
            // Get book details
            if let bookID = request.bookId.split(separator: "-").first {
                let bookSnapshot = try await Firestore.firestore().collection("books")
                    .document(String(bookID)).getDocument()
                
                if bookSnapshot.exists {
                    bookDetails = try bookSnapshot.data(as: Book.self)
                }
            }
            
            // Get user details
            let userSnapshot = try await Firestore.firestore().collection("users")
                .document(request.userId).getDocument()
            
            if userSnapshot.exists {
                userDetails = try userSnapshot.data(as: UserProfile.self)
            }
        } catch {
            print("Error loading related data: \(error)")
        }
        
        isLoadingDetails = false
    }
    
    private func detailRow(label: String, value: String) -> some View {
        HStack(alignment: .top) {
            Text(label)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .frame(width: 100, alignment: .leading)
            
            Text(value)
                .font(.subheadline)
                .foregroundColor(.primary)
                .multilineTextAlignment(.leading)
        }
    }
    
    private func formattedDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

struct ReservationCard: View {
    let reservation: BookReservation
    let viewModel: LibraryViewModel
    let completionHandler: (Bool, String) -> Void
    
    @State private var bookDetails: Book?
    @State private var userDetails: UserProfile?
    @State private var isLoadingDetails = true
    @State private var isProcessing = false
    @State private var timeRemaining: String = ""
    @State private var timer: Timer? = nil
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Card header with book info
            bookHeaderView
                .padding(.horizontal, 16)
                .padding(.top, 16)
                .padding(.bottom, 8)
            
            Divider()
                .padding(.horizontal, 8)
            
            // Reservation details
            reservationDetailsView
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
            
            Divider()
                .padding(.horizontal, 8)
            
            // Action buttons
            actionButtonsView
                .padding(16)
        }
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .shadow(color: Color.black.opacity(0.1), radius: 3, x: 0, y: 1)
        .task {
            await loadRelatedData()
            updateTimeRemaining()
            // Set up timer to update countdown
            timer = Timer.scheduledTimer(withTimeInterval: 60, repeats: true) { _ in
                updateTimeRemaining()
            }
        }
        .onDisappear {
            timer?.invalidate()
            timer = nil
        }
    }
    
    private var bookHeaderView: some View {
        HStack(alignment: .center, spacing: 12) {
            bookCoverView
            
            VStack(alignment: .leading, spacing: 4) {
                if isLoadingDetails {
                    Text("Loading book details...")
                        .font(.headline)
                        .foregroundColor(.secondary)
                    ProgressView()
                        .scaleEffect(0.7)
                } else if let book = bookDetails {
                    Text(book.title)
                        .font(.headline)
                        .lineLimit(1)
                    
                    Text("By \(book.author)")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                } else {
                    Text("Book details unavailable")
                        .font(.headline)
                        .foregroundColor(.red)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
    
    private var bookCoverView: some View {
        ZStack {
            Rectangle()
                .fill(Color.purple.opacity(0.1))
                .frame(width: 50, height: 65)
                .clipShape(RoundedRectangle(cornerRadius: 6))
            
            Image(systemName: "calendar.badge.clock")
                .font(.system(size: 24))
                .foregroundColor(.purple)
        }
    }
    
    private var reservationDetailsView: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Reservation Information")
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundColor(.secondary)
                .padding(.bottom, 2)
            
            VStack(alignment: .leading, spacing: 8) {
                detailRow(label: "Reserved On", value: formattedDate(reservation.reservationDate))
                detailRow(label: "Expires On", value: formattedDate(reservation.expirationDate))
                
                if !timeRemaining.isEmpty {
                    detailRow(label: "Time Left", value: timeRemaining)
                }
                
                if let user = userDetails {
                    detailRow(label: "Reserved By", value: user.name)
                    detailRow(label: "User Email", value: user.email)
                } else {
                    detailRow(label: "User ID", value: reservation.userId)
                }
                
                statusView
            }
        }
    }
    
    private var statusView: some View {
        HStack {
            Text("Status")
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(.secondary)
            
            Spacer()
            
            Text(reservation.status.rawValue.capitalized)
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundColor(.white)
                .padding(.horizontal, 10)
                .padding(.vertical, 4)
                .background(Color.purple)
                .clipShape(Capsule())
        }
    }
    
    private var actionButtonsView: some View {
        HStack(spacing: 12) {
            Button(action: {
                processReservation(fulfill: false)
            }) {
                HStack {
                    Image(systemName: "xmark.circle.fill")
                    Text("Cancel")
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(Color(.systemGray5))
                .foregroundColor(.red)
                .clipShape(RoundedRectangle(cornerRadius: 10))
            }
            .buttonStyle(.borderless)
            
            Button(action: {
                processReservation(fulfill: true)
            }) {
                HStack {
                    Image(systemName: "checkmark.circle.fill")
                    Text("Issue Book")
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(Color.purple)
                .foregroundColor(.white)
                .clipShape(RoundedRectangle(cornerRadius: 10))
            }
            .buttonStyle(.borderless)
        }
        .disabled(isProcessing)
        .opacity(isProcessing ? 0.6 : 1)
        .overlay(
            Group {
                if isProcessing {
                    HStack {
                        ProgressView()
                            .tint(.white)
                        Text("Processing...")
                            .foregroundColor(.secondary)
                    }
                }
            }
        )
    }
    
    private func processReservation(fulfill: Bool) {
        isProcessing = true
        Task {
            do {
                if fulfill {
                    try await viewModel.fulfillReservation(reservation)
                    completionHandler(true, "Book successfully issued to user!")
                } else {
                    try await viewModel.cancelReservation(reservation)
                    completionHandler(true, "Reservation cancelled.")
                }
                isProcessing = false
            } catch {
                isProcessing = false
                completionHandler(false, "Error: \(error.localizedDescription)")
            }
        }
    }
    
    private func loadRelatedData() async {
        isLoadingDetails = true
        
        do {
            // Get book details
            if let bookID = reservation.bookId.split(separator: "-").first {
                let bookSnapshot = try await Firestore.firestore().collection("books")
                    .document(String(bookID)).getDocument()
                
                if bookSnapshot.exists {
                    bookDetails = try bookSnapshot.data(as: Book.self)
                }
            }
            
            // Get user details
            let userSnapshot = try await Firestore.firestore().collection("users")
                .document(reservation.userId).getDocument()
            
            if userSnapshot.exists {
                userDetails = try userSnapshot.data(as: UserProfile.self)
            }
        } catch {
            print("Error loading related data: \(error)")
        }
        
        isLoadingDetails = false
    }
    
    private func updateTimeRemaining() {
        let now = Date()
        let expirationDate = reservation.expirationDate
        
        if now >= expirationDate {
            timeRemaining = "Expired"
            return
        }
        
        let calendar = Calendar.current
        let components = calendar.dateComponents([.day, .hour, .minute], from: now, to: expirationDate)
        
        if let days = components.day, let hours = components.hour, let minutes = components.minute {
            if days > 0 {
                timeRemaining = "\(days)d \(hours)h remaining"
            } else if hours > 0 {
                timeRemaining = "\(hours)h \(minutes)m remaining"
            } else {
                timeRemaining = "\(minutes) minutes remaining"
            }
        }
    }
    
    private func detailRow(label: String, value: String) -> some View {
        HStack(alignment: .top) {
            Text(label)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .frame(width: 100, alignment: .leading)
            
            Text(value)
                .font(.subheadline)
                .foregroundColor(label == "Time Left" && timeRemaining.contains("remaining") ? .purple : .primary)
                .fontWeight(label == "Time Left" ? .medium : .regular)
                .multilineTextAlignment(.leading)
        }
    }
    
    private func formattedDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

// Supporting struct - same as original
struct UserProfile: Identifiable, Codable {
    @DocumentID var id: String?
    let name: String
    let email: String
    
    enum CodingKeys: String, CodingKey {
        case id
        case name
        case email
    }
}

//
//import SwiftUI
//import FirebaseFirestore
//import FirebaseAuth
//
//struct BookRequestsView: View {
//    @StateObject private var viewModel = LibraryViewModel()
//    @State private var alertMessage = ""
//    @State private var showAlert = false
//    
//    // Grid layout configuration
//    private let columns = [
//        GridItem(.adaptive(minimum: 300, maximum: 500), spacing: 16)
//    ]
//    
//    var body: some View {
//        NavigationStack {
//            ScrollView {
//                if viewModel.isLoading {
//                    loadingView
//                } else if viewModel.pendingRequests.isEmpty {
//                    emptyRequestsView
//                } else {
//                    requestsGrid
//                }
//            }
//            .navigationTitle("Book Requests")
//            .background(Color(.systemGroupedBackground))
//            .refreshable {
//                await refreshData()
//            }
//            .alert(alertMessage, isPresented: $showAlert) {
//                Button("OK", role: .cancel) {}
//            }
//            .task {
//                await refreshData()
//            }
//            .toolbar {
//                ToolbarItem(placement: .navigationBarTrailing) {
//                    Button {
//                        Task { await refreshData() }
//                    } label: {
//                        Image(systemName: "arrow.clockwise")
//                            .imageScale(.medium)
//                    }
//                }
//            }
//        }
//    }
//    
//    private var loadingView: some View {
//        VStack {
//            Spacer()
//            ProgressView()
//                .scaleEffect(1.5)
//                .padding()
//            Text("Loading requests...")
//                .font(.callout)
//                .foregroundColor(.secondary)
//            Spacer()
//        }
//        .frame(maxWidth: .infinity, minHeight: 300)
//    }
//    
//    private var emptyRequestsView: some View {
//        VStack(spacing: 20) {
//            Spacer()
//            
//            Image(systemName: "book.closed")
//                .font(.system(size: 70))
//                .foregroundColor(.secondary)
//                .symbolEffect(.pulse)
//            
//            Text("No Pending Requests")
//                .font(.title2)
//                .fontWeight(.semibold)
//            
//            Text("When users request books, they'll appear here for your approval.")
//                .font(.callout)
//                .foregroundColor(.secondary)
//                .multilineTextAlignment(.center)
//                .padding(.horizontal, 40)
//            
//            Spacer()
//        }
//        .frame(maxWidth: .infinity, minHeight: 400)
//    }
//    
//    private var requestsGrid: some View {
//        LazyVGrid(columns: columns, spacing: 16) {
//            ForEach(viewModel.pendingRequests) { request in
//                RequestCard(request: request, viewModel: viewModel) { success, message in
//                    alertMessage = message
//                    showAlert = true
//                    
//                    if success {
//                        Task {
//                            await refreshData()
//                        }
//                    }
//                }
//            }
//        }
//        .padding()
//    }
//    
//    private func refreshData() async {
//        do {
//            try await viewModel.fetchPendingBookRequests()
//        } catch {
//            alertMessage = "Error refreshing: \(error.localizedDescription)"
//            showAlert = true
//        }
//    }
//}
//
//struct RequestCard: View {
//    let request: BookRequest
//    let viewModel: LibraryViewModel
//    let completionHandler: (Bool, String) -> Void
//    
//    @State private var bookDetails: Book?
//    @State private var userDetails: UserProfile?
//    @State private var isLoadingDetails = true
//    @State private var isProcessing = false
//    
//    var body: some View {
//        VStack(alignment: .leading, spacing: 0) {
//            // Card header with book info
//            bookHeaderView
//                .padding(.horizontal, 16)
//                .padding(.top, 16)
//                .padding(.bottom, 8)
//            
//            Divider()
//                .padding(.horizontal, 8)
//            
//            // Request details
//            requestDetailsView
//                .padding(.horizontal, 16)
//                .padding(.vertical, 12)
//            
//            Divider()
//                .padding(.horizontal, 8)
//            
//            // Action buttons
//            actionButtonsView
//                .padding(16)
//        }
//        .background(Color(.systemBackground))
//        .clipShape(RoundedRectangle(cornerRadius: 12))
//        .shadow(color: Color.black.opacity(0.1), radius: 3, x: 0, y: 1)
//        .task {
//            await loadRelatedData()
//        }
//    }
//    
//    private var bookHeaderView: some View {
//        HStack(alignment: .center, spacing: 12) {
//            bookCoverView
//            
//            VStack(alignment: .leading, spacing: 4) {
//                if isLoadingDetails {
//                    Text("Loading book details...")
//                        .font(.headline)
//                        .foregroundColor(.secondary)
//                    ProgressView()
//                        .scaleEffect(0.7)
//                } else if let book = bookDetails {
//                    Text(book.title)
//                        .font(.headline)
//                        .lineLimit(1)
//                    
//                    Text("By \(book.author)")
//                        .font(.subheadline)
//                        .foregroundColor(.secondary)
//                        .lineLimit(1)
//                } else {
//                    Text("Book details unavailable")
//                        .font(.headline)
//                        .foregroundColor(.red)
//                }
//            }
//            .frame(maxWidth: .infinity, alignment: .leading)
//        }
//    }
//    
//    private var bookCoverView: some View {
//        ZStack {
//            Rectangle()
//                .fill(Color.accentColor.opacity(0.1))
//                .frame(width: 50, height: 65)
//                .clipShape(RoundedRectangle(cornerRadius: 6))
//            
//            Image(systemName: "book")
//                .font(.system(size: 24))
//                .foregroundColor(.accentColor)
//        }
//    }
//    
//    private var requestDetailsView: some View {
//        VStack(alignment: .leading, spacing: 6) {
//            Text("Request Information")
//                .font(.subheadline)
//                .fontWeight(.semibold)
//                .foregroundColor(.secondary)
//                .padding(.bottom, 2)
//            
//            VStack(alignment: .leading, spacing: 8) {
//                detailRow(label: "Requested On", value: formattedDate(request.requestDate))
//                
//                if let user = userDetails {
//                    detailRow(label: "Requested By", value: user.name)
//                    detailRow(label: "User Email", value: user.email)
//                } else {
//                    detailRow(label: "User ID", value: request.userId)
//                }
//                
//                statusView
//            }
//        }
//    }
//    
//    private var statusView: some View {
//        HStack {
//            Text("Status")
//                .font(.subheadline)
//                .fontWeight(.medium)
//                .foregroundColor(.secondary)
//            
//            Spacer()
//            
//            Text(request.status.capitalized)
//                .font(.subheadline)
//                .fontWeight(.semibold)
//                .foregroundColor(.white)
//                .padding(.horizontal, 10)
//                .padding(.vertical, 4)
//                .background(Color.orange)
//                .clipShape(Capsule())
//        }
//    }
//    
//    private var actionButtonsView: some View {
//        HStack(spacing: 12) {
//            Button(action: {
//                processRequest(approve: false)
//            }) {
//                HStack {
//                    Image(systemName: "xmark.circle.fill")
//                    Text("Decline")
//                }
//                .frame(maxWidth: .infinity)
//                .padding(.vertical, 12)
//                .background(Color(.systemGray5))
//                .foregroundColor(.red)
//                .clipShape(RoundedRectangle(cornerRadius: 10))
//            }
//            .buttonStyle(.borderless)
//            
//            Button(action: {
//                processRequest(approve: true)
//            }) {
//                HStack {
//                    Image(systemName: "checkmark.circle.fill")
//                    Text("Approve")
//                }
//                .frame(maxWidth: .infinity)
//                .padding(.vertical, 12)
//                .background(Color.green)
//                .foregroundColor(.white)
//                .clipShape(RoundedRectangle(cornerRadius: 10))
//            }
//            .buttonStyle(.borderless)
//        }
//        .disabled(isProcessing)
//        .opacity(isProcessing ? 0.6 : 1)
//        .overlay(
//            Group {
//                if isProcessing {
//                    HStack {
//                        ProgressView()
//                            .tint(.white)
//                        Text("Processing...")
//                            .foregroundColor(.secondary)
//                    }
//                }
//            }
//        )
//    }
//    
//    private func processRequest(approve: Bool) {
//        isProcessing = true
//        Task {
//            do {
//                if approve {
//                    try await viewModel.approveBookRequest(request)
//                    completionHandler(true, "Request approved successfully!")
//                } else {
//                    try await viewModel.rejectBookRequest(request)
//                    completionHandler(true, "Request rejected.")
//                }
//                isProcessing = false
//            } catch {
//                isProcessing = false
//                completionHandler(false, "Error: \(error.localizedDescription)")
//            }
//        }
//    }
//    
//    private func loadRelatedData() async {
//        isLoadingDetails = true
//        
//        do {
//            // Get book details
//            if let bookID = request.bookId.split(separator: "-").first {
//                let bookSnapshot = try await Firestore.firestore().collection("books")
//                    .document(String(bookID)).getDocument()
//                
//                if bookSnapshot.exists {
//                    bookDetails = try bookSnapshot.data(as: Book.self)
//                }
//            }
//            
//            // Get user details
//            let userSnapshot = try await Firestore.firestore().collection("users")
//                .document(request.userId).getDocument()
//            
//            if userSnapshot.exists {
//                userDetails = try userSnapshot.data(as: UserProfile.self)
//            }
//        } catch {
//            print("Error loading related data: \(error)")
//        }
//        
//        isLoadingDetails = false
//    }
//    
//    private func detailRow(label: String, value: String) -> some View {
//        HStack(alignment: .top) {
//            Text(label)
//                .font(.subheadline)
//                .foregroundColor(.secondary)
//                .frame(width: 100, alignment: .leading)
//            
//            Text(value)
//                .font(.subheadline)
//                .foregroundColor(.primary)
//                .multilineTextAlignment(.leading)
//        }
//    }
//    
//    private func formattedDate(_ date: Date) -> String {
//        let formatter = DateFormatter()
//        formatter.dateStyle = .medium
//        formatter.timeStyle = .short
//        return formatter.string(from: date)
//    }
//}
//
//// Supporting struct - same as original
//struct UserProfile: Identifiable, Codable {
//    @DocumentID var id: String?
//    let name: String
//    let email: String
//    
//    enum CodingKeys: String, CodingKey {
//        case id
//        case name
//        case email
//    }
//}
