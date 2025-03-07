import SwiftUI

struct EnhancedChatView: View {
    @StateObject private var viewModel: EnhancedChatViewModel
    @Binding var isShowing: Bool
    @FocusState private var isInputFocused: Bool
    @State private var showingBookDetail = false
    @State private var selectedBook: Book?
    
    init(apiToken: String, isShowing: Binding<Bool>) {
        _viewModel = StateObject(wrappedValue: EnhancedChatViewModel(apiToken: apiToken))
        self._isShowing = isShowing
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Button(action: { isShowing = false }) {
                    Image(systemName: "xmark")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.gray)
                        .padding(8)
                        .background(Color.gray.opacity(0.1))
                        .clipShape(Circle())
                }
                Spacer()
                Text("Book Assistant")
                    .font(.headline)
                Spacer()
                Menu {
                    Menu("Language (\(viewModel.selectedLanguage))") {
                        ForEach(viewModel.availableLanguages, id: \.self) { language in
                            Button(action: { viewModel.changeLanguage(language) }) {
                                HStack {
                                    Text(language)
                                    if viewModel.selectedLanguage == language { Image(systemName: "checkmark") }
                                }
                            }
                        }
                    }
                    Button(action: { viewModel.toggleSpeech() }) {
                        HStack {
                            Text("Text-to-Speech")
                            Image(systemName: viewModel.isSpeechEnabled ? "speaker.wave.3.fill" : "speaker.slash.fill")
                        }
                    }
                } label: {
                    Image(systemName: "gear")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.gray)
                        .padding(8)
                        .background(Color.gray.opacity(0.1))
                        .clipShape(Circle())
                }
            }
            .padding(.horizontal)
            .padding(.vertical, 10)
            .background(Color.white)
            .shadow(color: Color.black.opacity(0.05), radius: 2)
            
            // Language and Speech Indicators
            HStack(spacing: 12) {
                HStack(spacing: 4) {
                    Image(systemName: "globe").font(.caption)
                    Text(viewModel.selectedLanguage).font(.caption)
                }
                .padding(.vertical, 4)
                .padding(.horizontal, 8)
                .background(Color.blue.opacity(0.1))
                .foregroundColor(.blue)
                .cornerRadius(12)
                
                HStack(spacing: 4) {
                    Image(systemName: viewModel.isSpeechEnabled ? "speaker.wave.2.fill" : "speaker.slash.fill").font(.caption)
                    Text(viewModel.isSpeechEnabled ? "Speech On" : "Speech Off").font(.caption)
                }
                .padding(.vertical, 4)
                .padding(.horizontal, 8)
                .background(viewModel.isSpeechEnabled ? Color.green.opacity(0.1) : Color.gray.opacity(0.1))
                .foregroundColor(viewModel.isSpeechEnabled ? .green : .gray)
                .cornerRadius(12)
                Spacer()
            }
            .padding(.horizontal)
            .padding(.vertical, 6)
            .background(Color.white)
            
            // Messages Area
            ScrollViewReader { scrollView in
                ScrollView {
                    LazyVStack(spacing: 12) {
                        ForEach(viewModel.messages) { message in
                            EnhancedChatBubble(message: message, viewModel: viewModel) { book in
                                selectedBook = book
                                showingBookDetail = true
                            }
                            .id(message.id)
                        }
                    }
                    .padding(.horizontal)
                    .padding(.vertical, 8)
                }
                .onChange(of: viewModel.messages.count) { _ in
                    if let lastMessage = viewModel.messages.last {
                        withAnimation { scrollView.scrollTo(lastMessage.id, anchor: .bottom) }
                    }
                }
                // Added tap gesture to dismiss keyboard when tapping the conversation area
                .onTapGesture {
                    isInputFocused = false
                }
            }
            .background(Color(.systemGray6))
            
            // Typing Indicator
            if viewModel.isTyping {
                HStack {
                    Text("Typing").font(.caption).foregroundColor(.gray)
                    TypingIndicator()
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal)
                .padding(.vertical, 8)
                .background(Color.white)
            }
            
            // Input Area
            HStack {
                TextField("Type a message...", text: $viewModel.newMessage)
                    .padding(10)
                    .background(Color(.systemGray5))
                    .cornerRadius(20)
                    .focused($isInputFocused)
                    .submitLabel(.send)
                    .onSubmit { viewModel.sendMessage() }
                    // Added toolbar with Done button to dismiss keyboard
                    .toolbar {
                        ToolbarItemGroup(placement: .keyboard) {
                            Spacer()
                            Button("Done") {
                                isInputFocused = false
                            }
                        }
                    }
                
                Button(action: { viewModel.sendMessage() }) {
                    Image(systemName: "arrow.up.circle.fill")
                        .font(.system(size: 30))
                        .foregroundColor(.blue)
                }
                .disabled(viewModel.newMessage.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || viewModel.isTyping)
            }
            .padding(.horizontal)
            .padding(.vertical, 10)
            .background(Color.white)
        }
        .sheet(isPresented: $showingBookDetail) {
            if let book = selectedBook {
                NavigationView { BookDetailView(book: book) }
            }
        }
        // Removed .onAppear auto-focus to prevent keyboard from opening automatically
        .onDisappear { viewModel.stopSpeaking() }
    }
}

struct EnhancedChatBubble: View {
    let message: ChatMessage
    let viewModel: EnhancedChatViewModel
    let onBookTap: (Book) -> Void
    
    var body: some View {
        VStack(alignment: message.isUser ? .trailing : .leading, spacing: 8) {
            HStack {
                if message.isUser {
                    Spacer()
                    Text(message.content)
                        .padding(12)
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(16)
                } else {
                    VStack(alignment: .leading, spacing: 4) {
                        HStack(alignment: .top, spacing: 8) {
                            VStack(alignment: .center) {
                                Image(systemName: "book.circle.fill")
                                    .font(.title2)
                                    .foregroundColor(.blue)
                                Button(action: { viewModel.speakText(message.content) }) {
                                    Image(systemName: "speaker.wave.2.circle.fill")
                                        .font(.system(size: 14))
                                        .foregroundColor(.blue)
                                }
                                .padding(.top, 2)
                            }
                            Text(message.content)
                                .padding(12)
                                .background(Color(.systemGray5))
                                .foregroundColor(.black)
                                .cornerRadius(16)
                        }
                    }
                    Spacer()
                }
            }
            if !message.isUser, let relatedBooks = message.relatedBooks, !relatedBooks.isEmpty {
                VStack(alignment: .leading, spacing: 10) {
                    Text("Related Books:")
                        .font(.caption)
                        .foregroundColor(.gray)
                        .padding(.leading, 36)
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 12) {
                            ForEach(relatedBooks) { book in
                                RelatedBookCard(book: book)
                                    .onTapGesture { onBookTap(book) }
                            }
                        }
                        .padding(.leading, 36)
                    }
                }
            }
        }
    }
}

struct RelatedBookCard: View {
    let book: Book
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            if let coverImage = book.getCoverImage() {
                Image(uiImage: coverImage)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 80, height: 120)
                    .clipped()
                    .cornerRadius(6)
            } else {
                Image(systemName: "book")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 80, height: 120)
                    .padding()
                    .foregroundColor(.gray)
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(6)
            }
            Text(book.title)
                .font(.caption)
                .fontWeight(.medium)
                .lineLimit(2)
                .frame(width: 80)
            Text(book.author)
                .font(.caption2)
                .foregroundColor(.gray)
                .lineLimit(1)
                .frame(width: 80)
            Text(book.availableCopies > 0 ? "Available" : "Unavailable")
                .font(.system(size: 8))
                .fontWeight(.semibold)
                .padding(.horizontal, 6)
                .padding(.vertical, 2)
                .background(book.availableCopies > 0 ? Color.green.opacity(0.2) : Color.red.opacity(0.2))
                .foregroundColor(book.availableCopies > 0 ? .green : .red)
                .cornerRadius(4)
        }
        .frame(width: 80)
        .padding(8)
        .background(Color.white)
        .cornerRadius(10)
        .shadow(color: Color.black.opacity(0.1), radius: 3, x: 0, y: 1)
    }
}

struct TypingIndicator: View {
    @State private var showFirstDot = false
    @State private var showSecondDot = false
    @State private var showThirdDot = false
    
    var body: some View {
        HStack(spacing: 2) {
            Circle().frame(width: 4, height: 4).scaleEffect(showFirstDot ? 1 : 0.5).opacity(showFirstDot ? 1 : 0.5)
            Circle().frame(width: 4, height: 4).scaleEffect(showSecondDot ? 1 : 0.5).opacity(showSecondDot ? 1 : 0.5)
            Circle().frame(width: 4, height: 4).scaleEffect(showThirdDot ? 1 : 0.5).opacity(showThirdDot ? 1 : 0.5)
        }
        .foregroundColor(.gray)
        .onAppear { startAnimation() }
    }
    
    func startAnimation() {
        withAnimation(Animation.easeInOut(duration: 0.3).repeatForever(autoreverses: true)) { showFirstDot = true }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            withAnimation(Animation.easeInOut(duration: 0.3).repeatForever(autoreverses: true)) { showSecondDot = true }
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
            withAnimation(Animation.easeInOut(duration: 0.3).repeatForever(autoreverses: true)) { showThirdDot = true }
        }
    }
}
