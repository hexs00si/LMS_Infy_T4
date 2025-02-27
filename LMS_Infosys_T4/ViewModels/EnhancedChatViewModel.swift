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
    var relatedBooks: [Book]? // New property to store related books
}

class EnhancedChatViewModel: ObservableObject {
    @Published var messages: [ChatMessage] = []
    @Published var newMessage: String = ""
    @Published var isTyping: Bool = false
    @Published var selectedLanguage: String = "English"
    @Published var isSpeechEnabled: Bool = false
    
    private let huggingFaceService: EnhancedHuggingFaceService
    private let libraryChatService = LibraryChatService() // New service
    private let speechSynthesizer = AVSpeechSynthesizer()
    
    let availableLanguages = ["English", "Spanish", "French", "German", "Chinese", "Japanese", "Hindi", "Arabic"]
    
    init(apiToken: String) {
        self.huggingFaceService = EnhancedHuggingFaceService(apiToken: apiToken)
        
        // Add a welcome message
        let welcomeMessage = "Hi! I'm your library assistant. Ask me about books or for recommendations. I can tell you what books are available in our library!"
        messages.append(ChatMessage(content: welcomeMessage, isUser: false, relatedBooks: nil))
        
        // Speak the welcome message if speech is enabled
        if isSpeechEnabled {
            speakText(welcomeMessage)
        }
    }
    
    func sendMessage() {
        guard !newMessage.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        
        // Add user message to the chat
        let userMessageText = newMessage
        messages.append(ChatMessage(content: userMessageText, isUser: true, relatedBooks: nil))
        newMessage = ""
        
        // Show the typing indicator
        isTyping = true
        
        // Check if the message contains keywords related to book recommendations
        if containsRecommendationRequest(userMessageText) {
            handleRecommendationRequest(userMessageText)
            return
        }
        
        // Check if the message is asking about book availability
        if containsAvailabilityRequest(userMessageText) {
            handleAvailabilityRequest(userMessageText)
            return
        }
        
        // For general questions, send to Hugging Face API
        huggingFaceService.sendMessage(userMessageText) { [weak self] result in
            DispatchQueue.main.async {
                guard let self = self else { return }
                
                // Hide typing indicator
                self.isTyping = false
                
                switch result {
                case .success(let responseText):
                    // Check if we should enhance the response with library data
                    self.enhanceResponseWithLibraryData(responseText, userQuery: userMessageText)
                    
                case .failure(let error):
                    // Handle error - add an error message to chat
                    print("Hugging Face API Error: \(error.localizedDescription)")
                    self.messages.append(ChatMessage(
                        content: "Sorry, I couldn't process your request. Please try again later.",
                        isUser: false,
                        relatedBooks: nil
                    ))
                    
                    // Speak the error message if speech is enabled
                    if self.isSpeechEnabled {
                        self.speakText("Sorry, I couldn't process your request. Please try again later.")
                    }
                }
            }
        }
    }
    
    // MARK: - Library Integration Methods
    
    private func containsRecommendationRequest(_ message: String) -> Bool {
        let message = message.lowercased()
        let recommendationKeywords = ["recommend", "suggestion", "suggest", "what should i read", "good books", "best books"]
        return recommendationKeywords.contains { message.contains($0) }
    }
    
    private func containsAvailabilityRequest(_ message: String) -> Bool {
        let message = message.lowercased()
        let availabilityKeywords = ["available", "have you got", "do you have", "in stock", "can i borrow", "can i check out"]
        return availabilityKeywords.contains { message.contains($0) }
    }
    
    private func handleRecommendationRequest(_ message: String) {
        // Extract genre from the message if possible
        let genreKeywords = ["fiction", "non-fiction", "science", "history", "biography", "mystery", "fantasy", "romance", "thriller", "horror", "sci-fi", "science fiction", "self-help", "comedy", "adventure"]
        
        var detectedGenre: String? = nil
        for genre in genreKeywords {
            if message.lowercased().contains(genre) {
                detectedGenre = genre
                break
            }
        }
        
        if let genre = detectedGenre {
            // If a genre is detected, get recommendations for that genre
            libraryChatService.getBooksByGenre(genre: genre) { [weak self] books in
                guard let self = self else { return }
                
                DispatchQueue.main.async {
                    self.isTyping = false
                    
                    if books.isEmpty {
                        // No books found for the genre
                        let response = "I don't have any \(genre) books to recommend from our library at the moment. Would you like recommendations for a different genre?"
                        self.messages.append(ChatMessage(content: response, isUser: false, relatedBooks: nil))
                        
                        if self.isSpeechEnabled {
                            self.speakText(response)
                        }
                    } else {
                        // Books found for the genre
                        var response = "Here are some \(genre) books I'd recommend from our library:\n\n"
                        
                        for (index, book) in books.prefix(5).enumerated() {
                            response += "\(index + 1). \(book.title) by \(book.author)"
                            
                            // Add availability info
                            if book.availableCopies > 0 {
                                response += " (Available: \(book.availableCopies) copies)"
                            } else {
                                response += " (Currently unavailable)"
                            }
                            
                            // Add library info
                            self.libraryChatService.getLibraryName(libraryID: book.libraryID) { libraryName in
                                if libraryName != "Unknown Library" {
                                    response += " at \(libraryName)"
                                }
                                
                                // If this is the last book, add the response and speak it
                                if index == min(books.count, 5) - 1 {
                                    response += "\n\nWould you like more details about any of these books?"
                                    
                                    // Add the message with related books
                                    self.messages.append(ChatMessage(content: response, isUser: false, relatedBooks: Array(books.prefix(5))))
                                    
                                    if self.isSpeechEnabled {
                                        self.speakText(response)
                                    }
                                }
                            }
                        }
                    }
                }
            }
        } else {
            // If no specific genre is detected, recommend popular books
            libraryChatService.getPopularBooks { [weak self] books in
                guard let self = self else { return }
                
                DispatchQueue.main.async {
                    self.isTyping = false
                    
                    if books.isEmpty {
                        // No popular books found
                        let response = "I don't have any books to recommend from our library at the moment. Could you try asking for a specific genre?"
                        self.messages.append(ChatMessage(content: response, isUser: false, relatedBooks: nil))
                        
                        if self.isSpeechEnabled {
                            self.speakText(response)
                        }
                    } else {
                        // Popular books found
                        var response = "Here are some popular books from our library:\n\n"
                        
                        for (index, book) in books.prefix(5).enumerated() {
                            response += "\(index + 1). \(book.title) by \(book.author)"
                            
                            // Add availability info
                            if book.availableCopies > 0 {
                                response += " (Available: \(book.availableCopies) copies)"
                            } else {
                                response += " (Currently unavailable)"
                            }
                            
                            response += "\n"
                        }
                        
                        response += "\nWould you like more details about any of these books?"
                        
                        // Add the message with related books
                        self.messages.append(ChatMessage(content: response, isUser: false, relatedBooks: Array(books.prefix(5))))
                        
                        if self.isSpeechEnabled {
                            self.speakText(response)
                        }
                    }
                }
            }
        }
    }
    
    private func handleAvailabilityRequest(_ message: String) {
        // Try to extract book title from the message
        let lowerMessage = message.lowercased()
        var potentialTitle = ""
        
        // Check for common phrases that might precede a title
        let availabilityPhrases = ["do you have", "is there", "available", "copy of", "looking for"]
        for phrase in availabilityPhrases {
            if lowerMessage.contains(phrase) {
                let components = lowerMessage.components(separatedBy: phrase)
                if components.count > 1 {
                    potentialTitle = components[1].trimmingCharacters(in: .whitespacesAndNewlines)
                    // Remove common endings
                    potentialTitle = potentialTitle.replacingOccurrences(of: "?", with: "")
                    potentialTitle = potentialTitle.replacingOccurrences(of: ".", with: "")
                    
                    if !potentialTitle.isEmpty {
                        break
                    }
                }
            }
        }
        
        if !potentialTitle.isEmpty {
            // Search for the book in our library
            libraryChatService.checkBookAvailability(title: potentialTitle) { [weak self] book in
                guard let self = self else { return }
                
                DispatchQueue.main.async {
                    self.isTyping = false
                    
                    if let book = book {
                        // Book found
                        var response = ""
                        
                        if book.availableCopies > 0 {
                            response = "Yes, we have '\(book.title)' by \(book.author) in our library! There are currently \(book.availableCopies) copies available for borrowing."
                        } else {
                            response = "We have '\(book.title)' by \(book.author) in our catalog, but all copies are currently checked out."
                        }
                        
                        // Add library information
                        self.libraryChatService.getLibraryName(libraryID: book.libraryID) { libraryName in
                            if libraryName != "Unknown Library" {
                                response += " You can find this book at \(libraryName)."
                            }
                            
                            // Add the message with the book
                            self.messages.append(ChatMessage(content: response, isUser: false, relatedBooks: [book]))
                            
                            if self.isSpeechEnabled {
                                self.speakText(response)
                            }
                        }
                    } else {
                        // Book not found, try to perform a broader search
                        self.libraryChatService.searchBooks(query: potentialTitle) { books in
                            if books.isEmpty {
                                // No similar books found
                                let response = "I couldn't find '\(potentialTitle)' in our library. Would you like to check for other books?"
                                self.messages.append(ChatMessage(content: response, isUser: false, relatedBooks: nil))
                                
                                if self.isSpeechEnabled {
                                    self.speakText(response)
                                }
                            } else {
                                // Similar books found
                                var response = "I couldn't find exactly '\(potentialTitle)', but here are some books that might be similar:\n\n"
                                
                                for (index, book) in books.prefix(3).enumerated() {
                                    response += "\(index + 1). \(book.title) by \(book.author)"
                                    
                                    // Add availability info
                                    if book.availableCopies > 0 {
                                        response += " (Available: \(book.availableCopies) copies)"
                                    } else {
                                        response += " (Currently unavailable)"
                                    }
                                    
                                    response += "\n"
                                }
                                
                                // Add the message with related books
                                self.messages.append(ChatMessage(content: response, isUser: false, relatedBooks: Array(books.prefix(3))))
                                
                                if self.isSpeechEnabled {
                                    self.speakText(response)
                                }
                            }
                        }
                    }
                }
            }
        } else {
            // Couldn't extract a title, send to general AI response
            huggingFaceService.sendMessage(message) { [weak self] result in
                DispatchQueue.main.async {
                    guard let self = self else { return }
                    
                    self.isTyping = false
                    
                    switch result {
                    case .success(let responseText):
                        self.messages.append(ChatMessage(content: responseText, isUser: false, relatedBooks: nil))
                        
                        if self.isSpeechEnabled {
                            self.speakText(responseText)
                        }
                        
                    case .failure(let error):
                        print("Hugging Face API Error: \(error.localizedDescription)")
                        let errorMessage = "Sorry, I couldn't process your request. Please try asking in a different way."
                        self.messages.append(ChatMessage(content: errorMessage, isUser: false, relatedBooks: nil))
                        
                        if self.isSpeechEnabled {
                            self.speakText(errorMessage)
                        }
                    }
                }
            }
        }
    }
    
    private func enhanceResponseWithLibraryData(_ responseText: String, userQuery: String) {
        // Extract potential book titles from the AI response
        let potentialTitles = extractBookTitles(from: responseText)
        
        if potentialTitles.isEmpty {
            // If no book titles found, just return the original response
            self.messages.append(ChatMessage(content: responseText, isUser: false, relatedBooks: nil))
            
            if self.isSpeechEnabled {
                self.speakText(responseText)
            }
            return
        }
        
        // Check if any of the mentioned books are in our library
        var foundBooks: [Book] = []
        let group = DispatchGroup()
        
        for title in potentialTitles {
            group.enter()
            libraryChatService.checkBookAvailability(title: title) { book in
                if let book = book {
                    foundBooks.append(book)
                }
                group.leave()
            }
        }
        
        group.notify(queue: .main) {
            if foundBooks.isEmpty {
                // No books found in our library, return original response
                self.messages.append(ChatMessage(content: responseText, isUser: false, relatedBooks: nil))
                
                if self.isSpeechEnabled {
                    self.speakText(responseText)
                }
            } else {
                // Found books in our library, enhance the response
                var enhancedResponse = responseText + "\n\nI noticed some books I mentioned are available in our library:\n\n"
                
                for (index, book) in foundBooks.prefix(3).enumerated() {
                    enhancedResponse += "\(index + 1). \(book.title) by \(book.author)"
                    
                    // Add availability info
                    if book.availableCopies > 0 {
                        enhancedResponse += " (Available: \(book.availableCopies) copies)"
                    } else {
                        enhancedResponse += " (Currently unavailable)"
                    }
                    
                    enhancedResponse += "\n"
                }
                
                // Add the enhanced message with related books
                self.messages.append(ChatMessage(content: enhancedResponse, isUser: false, relatedBooks: foundBooks))
                
                if self.isSpeechEnabled {
                    self.speakText(enhancedResponse)
                }
            }
        }
    }
    
    private func extractBookTitles(from text: String) -> [String] {
        // This is a simplified extraction method
        // In a real implementation, you might want to use NLP techniques
        
        var potentialTitles: [String] = []
        
        // Look for text in quotes, which might be book titles
        let quotePattern = "\"([^\"]+)\""
        if let regex = try? NSRegularExpression(pattern: quotePattern) {
            let matches = regex.matches(in: text, range: NSRange(text.startIndex..., in: text))
            
            for match in matches {
                if let range = Range(match.range(at: 1), in: text) {
                    let title = String(text[range])
                    potentialTitles.append(title)
                }
            }
        }
        
        return potentialTitles
    }
    
    // MARK: - Language and Speech Methods
    
    func changeLanguage(_ language: String) {
        selectedLanguage = language
        huggingFaceService.setLanguage(language)
        
        // Add a message about the language change
        let message = "Language changed to \(language)."
        messages.append(ChatMessage(content: message, isUser: false, relatedBooks: nil))
        
        // Speak the language change message if speech is enabled
        if isSpeechEnabled {
            speakText(message)
        }
    }
    
    func toggleSpeech() {
        isSpeechEnabled.toggle()
        
        if isSpeechEnabled {
            let message = "Text-to-speech is now enabled."
            messages.append(ChatMessage(content: message, isUser: false, relatedBooks: nil))
            speakText(message)
        } else {
            stopSpeaking()
            messages.append(ChatMessage(content: "Text-to-speech is now disabled.", isUser: false, relatedBooks: nil))
        }
    }
    
    func speakText(_ text: String) {
        // Stop any ongoing speech
        stopSpeaking()
        
        // Create an utterance with the text
        let utterance = AVSpeechUtterance(string: text)
        
        // Set the language based on the selected language
        switch selectedLanguage {
        case "English":
            utterance.voice = AVSpeechSynthesisVoice(language: "en-US")
        case "Spanish":
            utterance.voice = AVSpeechSynthesisVoice(language: "es-ES")
        case "French":
            utterance.voice = AVSpeechSynthesisVoice(language: "fr-FR")
        case "German":
            utterance.voice = AVSpeechSynthesisVoice(language: "de-DE")
        case "Chinese":
            utterance.voice = AVSpeechSynthesisVoice(language: "zh-CN")
        case "Japanese":
            utterance.voice = AVSpeechSynthesisVoice(language: "ja-JP")
        case "Hindi":
            utterance.voice = AVSpeechSynthesisVoice(language: "hi-IN")
        case "Arabic":
            utterance.voice = AVSpeechSynthesisVoice(language: "ar-SA")
        default:
            utterance.voice = AVSpeechSynthesisVoice(language: "en-US")
        }
        
        // Adjust speech rate and pitch for better clarity
        utterance.rate = 0.5  // 0.0 (slowest) to 1.0 (fastest)
        utterance.pitchMultiplier = 1.0  // 0.5 (low pitch) to 2.0 (high pitch)
        
        // Speak the text
        speechSynthesizer.speak(utterance)
    }
    
    func stopSpeaking() {
        if speechSynthesizer.isSpeaking {
            speechSynthesizer.stopSpeaking(at: .immediate)
        }
    }
}
