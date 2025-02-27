//
//  EnhancedChatViewModel.swift
//  LMS_Infosys_T4
//
//  Created by Shravan Rajput on 27/02/25.
//

import Foundation
import SwiftUI
import AVFoundation

struct ChatMessage: Identifiable {
    let id = UUID()
    let content: String
    let isUser: Bool
    let timestamp = Date()
    var relatedBooks: [Book]?
}

class EnhancedChatViewModel: ObservableObject {
    @Published var messages: [ChatMessage] = []
    @Published var newMessage: String = ""
    @Published var isTyping: Bool = false
    @Published var selectedLanguage: String = "English"
    @Published var isSpeechEnabled: Bool = false
    
    private let huggingFaceService: EnhancedHuggingFaceService
    private let libraryChatService = LibraryChatService()
    private let speechSynthesizer = AVSpeechSynthesizer()
    private var lastMentionedBook: String?
    
    let availableLanguages = ["English", "Spanish", "French", "German", "Chinese", "Japanese", "Hindi", "Arabic"]
    
    init(apiToken: String) {
        self.huggingFaceService = EnhancedHuggingFaceService(apiToken: apiToken)
        let welcomeMessage = "Hi! I'm your library assistant. Ask me about books or for recommendations. I can tell you what books are available in our library!"
        messages.append(ChatMessage(content: welcomeMessage, isUser: false, relatedBooks: nil))
        if isSpeechEnabled { speakText(welcomeMessage) }
    }
    
    func sendMessage() {
        guard !newMessage.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        
        let userMessageText = newMessage
        messages.append(ChatMessage(content: userMessageText, isUser: true, relatedBooks: nil))
        newMessage = ""
        isTyping = true
        
        let lowerMessage = userMessageText.lowercased()
        
        if containsPopularityRequest(lowerMessage) {
            handlePopularityRequest()
        } else if containsRecommendationRequest(lowerMessage) {
            handleRecommendationRequest(userMessageText)
        } else if containsAvailabilityRequest(lowerMessage) {
            handleAvailabilityRequest(userMessageText)
        } else if lastMentionedBook != nil && lowerMessage.contains("available") {
            handleAvailabilityRequest("Is \(lastMentionedBook!) available?")
        } else {
            huggingFaceService.sendMessage(userMessageText) { [weak self] result in
                DispatchQueue.main.async {
                    guard let self = self else { return }
                    self.isTyping = false
                    switch result {
                    case .success(let responseText):
                        self.enhanceResponseWithLibraryData(responseText, userQuery: userMessageText)
                    case .failure(let error):
                        print("Hugging Face API Error: \(error.localizedDescription)")
                        let errorMessage = "Sorry, I couldn't process your request. Please try again."
                        self.messages.append(ChatMessage(content: errorMessage, isUser: false, relatedBooks: nil))
                        if self.isSpeechEnabled { self.speakText(errorMessage) }
                    }
                }
            }
        }
    }
    
    // MARK: - Intent Detection
    
    private func containsPopularityRequest(_ message: String) -> Bool {
        let popularityKeywords = ["popular", "most popular", "top book", "most issued", "best selling"]
        return popularityKeywords.contains { message.contains($0) }
    }
    
    private func containsRecommendationRequest(_ message: String) -> Bool {
        let recommendationKeywords = ["recommend", "suggestion", "suggest", "what should i read", "good books", "best books"]
        return recommendationKeywords.contains { message.contains($0) }
    }
    
    private func isExternalRecommendationRequest(_ message: String) -> Bool {
        let externalKeywords = ["other than the library", "outside the library", "not from the library", "general"]
        return externalKeywords.contains { message.contains($0) }
    }
    
    private func containsAvailabilityRequest(_ message: String) -> Bool {
        let availabilityKeywords = ["available", "have you got", "do you have", "in stock", "can i borrow", "can i check out"]
        return availabilityKeywords.contains { message.contains($0) }
    }
    
    private func detectGenre(_ message: String) -> String? {
        let genreKeywords = ["fiction", "non-fiction", "science", "history", "biography", "mystery", "fantasy", "romance", "thriller", "horror", "sci-fi", "science fiction", "self-help", "comedy", "adventure"]
        let lowerMessage = message.lowercased()
        return genreKeywords.first { lowerMessage.contains($0) }
    }
    
    // MARK: - Request Handlers
    
    private func handlePopularityRequest() {
        libraryChatService.getPopularBooks { [weak self] books in
            guard let self = self else { return }
            DispatchQueue.main.async {
                self.isTyping = false
                if books.isEmpty {
                    let response = "I couldn't find any popular books in our library right now."
                    self.messages.append(ChatMessage(content: response, isUser: false, relatedBooks: nil))
                    if self.isSpeechEnabled { self.speakText(response) }
                } else {
                    let topBook = books[0]
                    let response = "The most popular book in our library is '\(topBook.title)' by \(topBook.author) (ISBN: \(topBook.isbn)) with \(topBook.bookIssueCount) issues."
                    self.messages.append(ChatMessage(content: response, isUser: false, relatedBooks: [topBook]))
                    self.lastMentionedBook = topBook.title
                    if self.isSpeechEnabled { self.speakText(response) }
                }
            }
        }
    }
    
    private func handleRecommendationRequest(_ message: String) {
        let lowerMessage = message.lowercased()
        if isExternalRecommendationRequest(lowerMessage) {
            let genre = detectGenre(message) ?? "good"
            huggingFaceService.sendMessage("Recommend me some \(genre) books not from any specific library.") { [weak self] result in
                guard let self = self else { return }
                DispatchQueue.main.async {
                    self.isTyping = false
                    switch result {
                    case .success(let responseText):
                        self.messages.append(ChatMessage(content: responseText, isUser: false, relatedBooks: nil))
                        if self.isSpeechEnabled { self.speakText(responseText) }
                    case .failure(let error):
                        print("Error: \(error)")
                        let response = "Sorry, I couldn’t fetch external recommendations right now."
                        self.messages.append(ChatMessage(content: response, isUser: false, relatedBooks: nil))
                        if self.isSpeechEnabled { self.speakText(response) }
                    }
                }
            }
        } else {
            if let genre = detectGenre(message) {
                libraryChatService.getBooksByGenre(genre: genre) { [weak self] books in
                    guard let self = self else { return }
                    DispatchQueue.main.async {
                        self.isTyping = false
                        if books.isEmpty {
                            let response = "I don't have any \(genre) books to recommend from our library at the moment."
                            self.messages.append(ChatMessage(content: response, isUser: false, relatedBooks: nil))
                            if self.isSpeechEnabled { self.speakText(response) }
                        } else {
                            var response = "Here are some \(genre) books from our library:\n\n"
                            for (index, book) in books.prefix(5).enumerated() {
                                response += "\(index + 1). \(book.title) by \(book.author) (ISBN: \(book.isbn))"
                                response += book.availableCopies > 0 ? " (Available: \(book.availableCopies) copies)" : " (Currently unavailable)"
                                response += "\n"
                            }
                            response += "\nWould you like more details?"
                            self.messages.append(ChatMessage(content: response, isUser: false, relatedBooks: Array(books.prefix(5))))
                            self.lastMentionedBook = books.first?.title
                            if self.isSpeechEnabled { self.speakText(response) }
                        }
                    }
                }
            } else {
                libraryChatService.getPopularBooks { [weak self] books in
                    guard let self = self else { return }
                    DispatchQueue.main.async {
                        self.isTyping = false
                        if books.isEmpty {
                            let response = "I don't have any books to recommend from our library right now."
                            self.messages.append(ChatMessage(content: response, isUser: false, relatedBooks: nil))
                            if self.isSpeechEnabled { self.speakText(response) }
                        } else {
                            var response = "Here are some popular books from our library:\n\n"
                            for (index, book) in books.prefix(5).enumerated() {
                                response += "\(index + 1). \(book.title) by \(book.author) (ISBN: \(book.isbn))"
                                response += book.availableCopies > 0 ? " (Available: \(book.availableCopies) copies)" : " (Currently unavailable)"
                                response += "\n"
                            }
                            response += "\nWould you like more details?"
                            self.messages.append(ChatMessage(content: response, isUser: false, relatedBooks: Array(books.prefix(5))))
                            self.lastMentionedBook = books.first?.title
                            if self.isSpeechEnabled { self.speakText(response) }
                        }
                    }
                }
            }
        }
    }
    
    private func handleAvailabilityRequest(_ message: String) {
        let lowerMessage = message.lowercased()
        var potentialTitle = ""
        
        let availabilityPhrases = ["do you have", "is there", "available", "copy of", "looking for", "have you got", "in stock"]
        for phrase in availabilityPhrases {
            if lowerMessage.contains(phrase) {
                if let range = lowerMessage.range(of: phrase) {
                    let afterPhrase = lowerMessage[range.upperBound...].trimmingCharacters(in: .whitespaces)
                    potentialTitle = afterPhrase.components(separatedBy: " by ")[0]
                    potentialTitle = potentialTitle.replacingOccurrences(of: "?", with: "").trimmingCharacters(in: .whitespaces)
                    if !potentialTitle.isEmpty { break }
                }
            }
        }
        
        if potentialTitle.isEmpty {
            potentialTitle = lowerMessage.trimmingCharacters(in: .whitespaces)
        }
        
        if !potentialTitle.isEmpty {
            libraryChatService.checkBookAvailability(title: potentialTitle.capitalized) { [weak self] book in
                guard let self = self else { return }
                DispatchQueue.main.async {
                    self.isTyping = false
                    if let book = book {
                        let response = book.availableCopies > 0
                            ? "Yes, '\(book.title)' by \(book.author) (ISBN: \(book.isbn)) is available with \(book.availableCopies) copies."
                            : "We have '\(book.title)' by \(book.author) (ISBN: \(book.isbn)), but it’s currently unavailable."
                        self.messages.append(ChatMessage(content: response, isUser: false, relatedBooks: [book]))
                        self.lastMentionedBook = book.title
                        if self.isSpeechEnabled { self.speakText(response) }
                    } else {
                        let response = "I couldn’t find '\(potentialTitle)' in our library. Would you like me to search for something similar?"
                        self.messages.append(ChatMessage(content: response, isUser: false, relatedBooks: nil))
                        self.lastMentionedBook = potentialTitle
                        if self.isSpeechEnabled { self.speakText(response) }
                    }
                }
            }
        } else {
            let response = "I’m not sure which book you’re asking about. Could you please specify the title?"
            messages.append(ChatMessage(content: response, isUser: false, relatedBooks: nil))
            if isSpeechEnabled { speakText(response) }
            isTyping = false
        }
    }
    
    private func enhanceResponseWithLibraryData(_ responseText: String, userQuery: String) {
        let potentialTitles = extractBookTitles(from: responseText)
        if potentialTitles.isEmpty {
            messages.append(ChatMessage(content: responseText, isUser: false, relatedBooks: nil))
            if isSpeechEnabled { speakText(responseText) }
            return
        }
        
        var foundBooks: [Book] = []
        let group = DispatchGroup()
        
        for title in potentialTitles {
            group.enter()
            libraryChatService.checkBookAvailability(title: title.capitalized) { book in
                if let book = book { foundBooks.append(book) }
                group.leave()
            }
        }
        
        group.notify(queue: .main) {
            if foundBooks.isEmpty {
                self.messages.append(ChatMessage(content: responseText, isUser: false, relatedBooks: nil))
                if self.isSpeechEnabled { self.speakText(responseText) }
            } else {
                var enhancedResponse = responseText + "\n\nFrom our library:\n\n"
                for (index, book) in foundBooks.prefix(3).enumerated() {
                    enhancedResponse += "\(index + 1). \(book.title) by \(book.author) (ISBN: \(book.isbn))"
                    enhancedResponse += book.availableCopies > 0 ? " (Available: \(book.availableCopies) copies)" : " (Currently unavailable)"
                    enhancedResponse += "\n"
                }
                self.messages.append(ChatMessage(content: enhancedResponse, isUser: false, relatedBooks: foundBooks))
                self.lastMentionedBook = foundBooks.first?.title
                if self.isSpeechEnabled { self.speakText(enhancedResponse) }
            }
        }
    }
    
    private func extractBookTitles(from text: String) -> [String] {
        var potentialTitles: [String] = []
        let quotePattern = "\"([^\"]+)\""
        if let regex = try? NSRegularExpression(pattern: quotePattern) {
            let matches = regex.matches(in: text, range: NSRange(text.startIndex..., in: text))
            for match in matches {
                if let range = Range(match.range(at: 1), in: text) {
                    potentialTitles.append(String(text[range]))
                }
            }
        }
        return potentialTitles
    }
    
    // MARK: - Language and Speech
    
    func changeLanguage(_ language: String) {
        selectedLanguage = language
        huggingFaceService.setLanguage(language)
        let message = "Language changed to \(language)."
        messages.append(ChatMessage(content: message, isUser: false, relatedBooks: nil))
        if isSpeechEnabled { speakText(message) }
    }
    
    func toggleSpeech() {
        isSpeechEnabled.toggle()
        let message = isSpeechEnabled ? "Text-to-speech is now enabled." : "Text-to-speech is now disabled."
        messages.append(ChatMessage(content: message, isUser: false, relatedBooks: nil))
        if isSpeechEnabled { speakText(message) } else { stopSpeaking() }
    }
    
    func speakText(_ text: String) {
        stopSpeaking()
        let utterance = AVSpeechUtterance(string: text)
        switch selectedLanguage {
        case "English": utterance.voice = AVSpeechSynthesisVoice(language: "en-US")
        case "Spanish": utterance.voice = AVSpeechSynthesisVoice(language: "es-ES")
        case "French": utterance.voice = AVSpeechSynthesisVoice(language: "fr-FR")
        case "German": utterance.voice = AVSpeechSynthesisVoice(language: "de-DE")
        case "Chinese": utterance.voice = AVSpeechSynthesisVoice(language: "zh-CN")
        case "Japanese": utterance.voice = AVSpeechSynthesisVoice(language: "ja-JP")
        case "Hindi": utterance.voice = AVSpeechSynthesisVoice(language: "hi-IN")
        case "Arabic": utterance.voice = AVSpeechSynthesisVoice(language: "ar-SA")
        default: utterance.voice = AVSpeechSynthesisVoice(language: "en-US")
        }
        utterance.rate = 0.5
        utterance.pitchMultiplier = 1.0
        speechSynthesizer.speak(utterance)
    }
    
    func stopSpeaking() {
        if speechSynthesizer.isSpeaking {
            speechSynthesizer.stopSpeaking(at: .immediate)
        }
    }
}
