swift
import Foundation

extension CopilotService {
    
    /// Test API key connection with a simple request
    /// - Parameter completion: Completion handler with result
    func testConnection(completion: @escaping (Result<Void, CopilotError>) -> Void) {
        // Create a simple prompt to test the API connection
        let testPrompt = "Say 'Connection successful'"
        
        // Use the existing generateCode method with the test prompt
        generateCode(with: testPrompt) { result in
            switch result {
            case .success(let response):
                if let firstChoice = response.choices.first, firstChoice.text.contains("Connection successful") {
                   completion(.success(()))
                } else {
                    completion(.failure(.invalidResponse("Unexpected response: \(response.choices.first?.text ?? "")")))
                }
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
    
    /// Parse Copilot response for specific errors
    /// - Parameters:
    ///   - data: Response data
    ///   - response: HTTP response
    /// - Returns: CopilotError if one is detected, nil otherwise
    func parseResponseForErrors(data: Data, response: HTTPURLResponse) -> CopilotError? {
        // Check for common HTTP status codes
        switch response.statusCode {
        case 200:
            return nil // No error
            
        case 401:
            return .invalidAPIKey
            
        case 429:
            return .rateLimitExceeded
            
        case 400..<500:
            // Attempt to parse the error message from the response
            if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],  // Adjusted for Copilot's error structure
               let error = json["error"] as? [String: Any],
               let message = error["message"] as? String {
                return .invalidResponse(message)
            }
            return .invalidRequest  // Fallback if specific error message can't be extracted
            
        case 500..<600:
            return .invalidResponse("Server error \(response.statusCode)")
            
        default:
            return .unknownError("Unexpected status code: \(response.statusCode)")
        }
    }
}