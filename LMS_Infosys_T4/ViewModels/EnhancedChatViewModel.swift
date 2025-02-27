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
}

class EnhancedChatViewModel: ObservableObject {
    @Published var messages: [ChatMessage] = []
    @Published var newMessage: String = ""
    @Published var isTyping: Bool = false
    @Published var selectedLanguage: String = "English"
    @Published var isSpeechEnabled: Bool = false
    
    private let huggingFaceService: EnhancedHuggingFaceService
    private let speechSynthesizer = AVSpeechSynthesizer()
    
    let availableLanguages = ["English", "Spanish", "French", "German", "Chinese", "Japanese", "Hindi", "Arabic"]
    
    init(apiToken: String) {
        self.huggingFaceService = EnhancedHuggingFaceService(apiToken: apiToken)
        
        // Add a welcome message
        let welcomeMessage = "Hi! I'm your book assistant. Ask me about books or for recommendations."
        messages.append(ChatMessage(content: welcomeMessage, isUser: false))
        
        // Speak the welcome message if speech is enabled
        if isSpeechEnabled {
            speakText(welcomeMessage)
        }
    }
    
    func sendMessage() {
        guard !newMessage.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        
        // Add user message to the chat
        let userMessageText = newMessage
        messages.append(ChatMessage(content: userMessageText, isUser: true))
        newMessage = ""
        
        // Show the typing indicator
        isTyping = true
        
        // Send the message to Hugging Face API
        huggingFaceService.sendMessage(userMessageText) { [weak self] result in
            DispatchQueue.main.async {
                guard let self = self else { return }
                
                // Hide typing indicator
                self.isTyping = false
                
                switch result {
                case .success(let responseText):
                    // Add the AI response to chat
                    self.messages.append(ChatMessage(content: responseText, isUser: false))
                    
                    // Speak the response if speech is enabled
                    if self.isSpeechEnabled {
                        self.speakText(responseText)
                    }
                    
                case .failure(let error):
                    // Handle error - add an error message to chat
                    print("Hugging Face API Error: \(error.localizedDescription)")
                    
                    let errorMessage = "Sorry, I couldn't process your request. Please try again later."
                    self.messages.append(ChatMessage(content: errorMessage, isUser: false))
                    
                    // Speak the error message if speech is enabled
                    if self.isSpeechEnabled {
                        self.speakText(errorMessage)
                    }
                }
            }
        }
    }
    
    func changeLanguage(_ language: String) {
        selectedLanguage = language
        huggingFaceService.setLanguage(language)
        
        // Add a message about the language change
        let message = "Language changed to \(language)."
        messages.append(ChatMessage(content: message, isUser: false))
        
        // Speak the language change message if speech is enabled
        if isSpeechEnabled {
            speakText(message)
        }
    }
    
    func toggleSpeech() {
        isSpeechEnabled.toggle()
        
        if isSpeechEnabled {
            let message = "Text-to-speech is now enabled."
            messages.append(ChatMessage(content: message, isUser: false))
            speakText(message)
        } else {
            stopSpeaking()
            messages.append(ChatMessage(content: "Text-to-speech is now disabled.", isUser: false))
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
