//
//  PasswordCriteria.swift
//  LMS_Infosys_T4
//
//  Created by Shravan Rajput on 18/02/25.
//

import Foundation

struct PasswordCriteria {
    var hasMinLength: Bool = false
    var hasUppercaseLetter: Bool = false
    var hasLowercaseLetter: Bool = false
    var hasNumber: Bool = false
    var hasSpecialCharacter: Bool = false
    
    mutating func evaluate(_ password: String) {
        hasMinLength = password.count >= 8
        hasUppercaseLetter = password.range(of: "[A-Z]", options: .regularExpression) != nil
        hasLowercaseLetter = password.range(of: "[a-z]", options: .regularExpression) != nil
        hasNumber = password.range(of: "[0-9]", options: .regularExpression) != nil
        hasSpecialCharacter = password.range(of: "[!@#$%^&*(),.?\":{}|<>]", options: .regularExpression) != nil
    }
    
    var isValid: Bool {
        hasMinLength && hasUppercaseLetter && hasLowercaseLetter && hasNumber && hasSpecialCharacter
    }
}

