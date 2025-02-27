//
//  EnhancedChatButton.swift
//  LMS_Infosys_T4
//
//  Created by Shravan Rajput on 27/02/25.
//

import SwiftUI

import SwiftUI

struct EnhancedChatButton: View {
    @Binding var isShowingChat: Bool
    
    var body: some View {
        Button(action: {
            isShowingChat = true
        }) {
            ZStack {
                Circle()
                    .fill(Color.blue)
                    .frame(width: 60, height: 60)
                    .shadow(color: Color.black.opacity(0.3), radius: 3)
                
                VStack(spacing: 2) {
                    Image(systemName: "bubble.left.fill")
                        .font(.system(size: 22))
                        .foregroundColor(.white)
                    
                    // Add a small accessibility icon
                    Image(systemName: "accessibility")
                        .font(.system(size: 10))
                        .foregroundColor(.white.opacity(0.8))
                }
            }
        }
        .padding(.trailing, 20)
        .padding(.bottom, 30)
        .accessibilityLabel("Open Library Assistant")
        .accessibilityHint("Chat with the AI library assistant that supports multiple languages and text-to-speech")
    }
}

#Preview {
    ZStack {
        Color.gray.opacity(0.2).ignoresSafeArea()
        
        VStack {
            Spacer()
            HStack {
                Spacer()
                EnhancedChatButton(isShowingChat: .constant(false))
            }
        }
    }
}
