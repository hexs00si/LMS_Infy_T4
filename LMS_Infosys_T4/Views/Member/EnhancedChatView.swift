//
//  EnhancedChatView.swift
//  LMS_Infosys_T4
//
//  Created by Shravan Rajput on 27/02/25.
//

import SwiftUI

import SwiftUI

struct EnhancedChatView: View {
    @StateObject private var viewModel: EnhancedChatViewModel
    @Binding var isShowing: Bool
    @FocusState private var isInputFocused: Bool
    @State private var showingLanguageSettings = false
    
    init(apiToken: String, isShowing: Binding<Bool>) {
        _viewModel = StateObject(wrappedValue: EnhancedChatViewModel(apiToken: apiToken))
        self._isShowing = isShowing
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Button(action: {
                    isShowing = false
                }) {
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
                
                // Menu for accessibility options
                Menu {
                    // Language submenu
                    Menu("Language (\(viewModel.selectedLanguage))") {
                        ForEach(viewModel.availableLanguages, id: \.self) { language in
                            Button(action: {
                                viewModel.changeLanguage(language)
                            }) {
                                HStack {
                                    Text(language)
                                    if viewModel.selectedLanguage == language {
                                        Image(systemName: "checkmark")
                                    }
                                }
                            }
                        }
                    }
                    
                    // Text-to-speech toggle
                    Button(action: {
                        viewModel.toggleSpeech()
                    }) {
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
            .background(Color(.systemBackground))
            .shadow(color: Color.black.opacity(0.05), radius: 2)
            
            // Language and Speech indicators
            HStack(spacing: 12) {
                // Language indicator
                HStack(spacing: 4) {
                    Image(systemName: "globe")
                        .font(.caption)
                    Text(viewModel.selectedLanguage)
                        .font(.caption)
                }
                .padding(.vertical, 4)
                .padding(.horizontal, 8)
                .background(Color.blue.opacity(0.1))
                .foregroundColor(.blue)
                .cornerRadius(12)
                
                // Speech indicator
                HStack(spacing: 4) {
                    Image(systemName: viewModel.isSpeechEnabled ? "speaker.wave.2.fill" : "speaker.slash.fill")
                        .font(.caption)
                    Text(viewModel.isSpeechEnabled ? "Speech On" : "Speech Off")
                        .font(.caption)
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
            .background(Color(.systemBackground))
            
            // Messages
            ScrollViewReader { scrollView in
                ScrollView {
                    LazyVStack(spacing: 12) {
                        ForEach(viewModel.messages) { message in
                            ChatBubble(message: message, viewModel: viewModel)
                                .id(message.id)
                        }
                    }
                    .padding(.horizontal)
                    .padding(.vertical, 8)
                }
                .onChange(of: viewModel.messages.count) { _ in
                    if let lastMessage = viewModel.messages.last {
                        withAnimation {
                            scrollView.scrollTo(lastMessage.id, anchor: .bottom)
                        }
                    }
                }
            }
            .background(Color(.systemGray6))
            
            // Typing indicator
            if viewModel.isTyping {
                HStack {
                    Text("Typing")
                        .font(.caption)
                        .foregroundColor(.gray)
                    
                    // Animated dots
                    TypingIndicator()
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal)
                .padding(.vertical, 8)
                .background(Color.white)
            }
            
            // Input area
            HStack {
                TextField("Type a message...", text: $viewModel.newMessage)
                    .padding(10)
                    .background(Color(.systemGray5))
                    .cornerRadius(20)
                    .focused($isInputFocused)
                    .submitLabel(.send)
                    .onSubmit {
                        viewModel.sendMessage()
                    }
                
                Button(action: {
                    viewModel.sendMessage()
                }) {
                    Image(systemName: "arrow.up.circle.fill")
                        .font(.system(size: 30))
                        .foregroundColor(.blue)
                }
                .disabled(viewModel.newMessage.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || viewModel.isTyping)
            }
            .padding(.horizontal)
            .padding(.vertical, 10)
            .background(Color(.systemBackground))
        }
        .onAppear {
            // Focus the input when the view appears
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                isInputFocused = true
            }
        }
        .onDisappear {
            // Stop any ongoing speech when view disappears
            viewModel.stopSpeaking()
        }
    }
}

struct ChatBubble: View {
    let message: ChatMessage
    let viewModel: EnhancedChatViewModel
    
    var body: some View {
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
                            
                            // Add speech button for AI messages
                            if !message.isUser {
                                Button(action: {
                                    viewModel.speakText(message.content)
                                }) {
                                    Image(systemName: "speaker.wave.2.circle.fill")
                                        .font(.system(size: 14))
                                        .foregroundColor(.blue)
                                }
                                .padding(.top, 2)
                            }
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
    }
}

struct TypingIndicator: View {
    @State private var showFirstDot = false
    @State private var showSecondDot = false
    @State private var showThirdDot = false
    
    var body: some View {
        HStack(spacing: 2) {
            Circle()
                .frame(width: 4, height: 4)
                .scaleEffect(showFirstDot ? 1 : 0.5)
                .opacity(showFirstDot ? 1 : 0.5)
            
            Circle()
                .frame(width: 4, height: 4)
                .scaleEffect(showSecondDot ? 1 : 0.5)
                .opacity(showSecondDot ? 1 : 0.5)
            
            Circle()
                .frame(width: 4, height: 4)
                .scaleEffect(showThirdDot ? 1 : 0.5)
                .opacity(showThirdDot ? 1 : 0.5)
        }
        .foregroundColor(.gray)
        .onAppear {
            startAnimation()
        }
    }
    
    func startAnimation() {
        withAnimation(Animation.easeInOut(duration: 0.3).repeatForever(autoreverses: true)) {
            showFirstDot = true
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            withAnimation(Animation.easeInOut(duration: 0.3).repeatForever(autoreverses: true)) {
                showSecondDot = true
            }
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
            withAnimation(Animation.easeInOut(duration: 0.3).repeatForever(autoreverses: true)) {
                showThirdDot = true
            }
        }
    }
}
