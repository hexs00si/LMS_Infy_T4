//
//  EnhancedHugginFaceSerivce.swift
//  LMS_Infosys_T4
//
//  Created by Shravan Rajput on 27/02/25.
//

import Foundation

class EnhancedHuggingFaceService {
    private let apiToken: String
    private let urlSession = URLSession.shared
    private var currentLanguage: String = "English"
    
    init(apiToken: String) {
        self.apiToken = apiToken
    }
    
    func setLanguage(_ language: String) {
        self.currentLanguage = language
    }
    
    func sendMessage(_ message: String, completion: @escaping (Result<String, Error>) -> Void) {
        let url = URL(string: "https://api-inference.huggingface.co/models/mistralai/Mistral-7B-Instruct-v0.2")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("Bearer \(apiToken)", forHTTPHeaderField: "Authorization")
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        
        // Updated prompt to clarify library-specific vs. general responses
        let prompt = """
        <s>[INST] You are a helpful library assistant who knows about books and gives good recommendations. Keep responses concise, friendly, and focused on books. Only provide general book information unless specifically asked about our library’s collection. For library-specific questions, say 'Checking our library...' and keep your response minimal. Respond in \(currentLanguage). The user's question is: \(message) [/INST]
        """
        
        let requestBody: [String: Any] = [
            "inputs": prompt,
            "parameters": [
                "max_length": 1000,
                "top_p": 0.9,
                "temperature": 0.7,
                "return_full_text": false
            ]
        ]
        
        do {
            let jsonData = try JSONSerialization.data(withJSONObject: requestBody)
            request.httpBody = jsonData
        } catch {
            completion(.failure(error))
            return
        }
        
        let task = urlSession.dataTask(with: request) { data, response, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            
            guard let data = data else {
                completion(.failure(NSError(domain: "HuggingFaceService", code: 0, userInfo: [NSLocalizedDescriptionKey: "No data received"])))
                return
            }
            
            do {
                if let responseString = String(data: data, encoding: .utf8) {
                    if let responseJSON = try? JSONSerialization.jsonObject(with: data) as? [[String: Any]],
                       let firstResult = responseJSON.first,
                       let generatedText = firstResult["generated_text"] as? String {
                        completion(.success(self.cleanResponse(generatedText)))
                    } else if let errorJSON = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                            let error = errorJSON["error"] as? String {
                        completion(.failure(NSError(domain: "HuggingFaceService", code: 3, userInfo: [NSLocalizedDescriptionKey: error])))
                    } else {
                        completion(.success(self.cleanResponse(responseString)))
                    }
                } else {
                    completion(.failure(NSError(domain: "HuggingFaceService", code: 2, userInfo: [NSLocalizedDescriptionKey: "Invalid response encoding"])))
                }
            } catch {
                completion(.failure(error))
            }
        }
        
        task.resume()
    }
    
    private func cleanResponse(_ response: String) -> String {
        if let range = response.range(of: "[/INST]") {
            let startIndex = response.index(range.upperBound, offsetBy: 0)
            return String(response[startIndex...]).trimmingCharacters(in: .whitespacesAndNewlines)
        }
        
        var cleanedResponse = response
            .replacingOccurrences(of: "<s>", with: "")
            .replacingOccurrences(of: "</s>", with: "")
        
        if cleanedResponse.contains("[INST]") {
            if let endRange = cleanedResponse.range(of: "[/INST]") {
                let responseStart = cleanedResponse.index(endRange.upperBound, offsetBy: 0)
                cleanedResponse = String(cleanedResponse[responseStart...])
            }
        }
        
        return cleanedResponse.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
