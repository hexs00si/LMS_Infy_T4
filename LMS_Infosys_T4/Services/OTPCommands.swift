//
//  OTPCommands.swift
//  LMS_Infosys_T4
//
//  Created by Dakshdeep Singh on 20/02/25.
//

import Foundation

class OTPCommands: ObservableObject {
    @Published var isOTPVerified: Bool = false
    @Published var emailForSignup: String = ""
    @Published var nameForSignup: String = ""
    public static let shared = OTPCommands()
    
    private init() {}
    
    func sendOTP(email: String, name: String, completion: @escaping (Bool, String?) -> Void) {
        guard let url = URL(string: "http://localhost:3000/send-otp") else { return }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let body: [String: String] = ["email": email]
        request.httpBody = try? JSONSerialization.data(withJSONObject: body)
        
        URLSession.shared.dataTask(with: request) { [weak self] data, response, error in
            if let error = error {
                completion(false, error.localizedDescription)
                return
            }
            guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
                completion(false, "Failed to send OTP")
                return
            }
            
            self?.emailForSignup = email
            self?.nameForSignup = name
            completion(true, nil)
        }.resume()
    }
    
    func verifyOTP(otp: String, completion: @escaping (Bool, String?) -> Void) {
        guard let url = URL(string: "http://localhost:3000/verify-otp") else { return }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let body: [String: String] = ["email": emailForSignup, "otp": otp]
        request.httpBody = try? JSONSerialization.data(withJSONObject: body)
        
        URLSession.shared.dataTask(with: request) { [weak self] data, response, error in
            if let error = error {
                print("Network Error: \(error.localizedDescription)")
                completion(false, error.localizedDescription)
                return
            }
            
            guard let httpResponse = response as? HTTPURLResponse else {
                print("No HTTP response")
                completion(false, "No response from server")
                return
            }
            
            if httpResponse.statusCode == 200 {
                self?.isOTPVerified = true
                completion(true, nil)
            } else {
                if let data = data, let responseMessage = String(data: data, encoding: .utf8) {
                    print("Server Response: \(responseMessage)")
                    completion(false, responseMessage)
                } else {
                    print("Invalid OTP")
                    completion(false, "Invalid OTP")
                }
            }
        }.resume()
    }
}
