//
//  PasswordCriteriaView.swift
//  LMS_Infosys_T4
//
//  Created by Shravan Rajput on 18/02/25.
//

import SwiftUI
struct PasswordCriteriaView: View {
    let criteria: PasswordCriteria
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            criteriaRow(isValid: criteria.hasMinLength,
                       text: "At least 8 characters")
            criteriaRow(isValid: criteria.hasUppercaseLetter,
                       text: "Include uppercase letters")
            criteriaRow(isValid: criteria.hasLowercaseLetter,
                       text: "Include lowercase letters")
            criteriaRow(isValid: criteria.hasNumber,
                       text: "Include at least one number")
            criteriaRow(isValid: criteria.hasSpecialCharacter,
                       text: "Include at least one special character")
        }
    }
    
    private func criteriaRow(isValid: Bool, text: String) -> some View {
        HStack {
            Image(systemName: isValid ? "checkmark.circle.fill" : "circle")
                .foregroundColor(isValid ? .green : .gray)
            Text(text)
                .foregroundColor(isValid ? .primary : .gray)
        }
    }
}
