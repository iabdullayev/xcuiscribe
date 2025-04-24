import Foundation

/// Service responsible for interacting with Copilot API
public class CopilotService {
    
    /// Errors that can occur during Copilot API interaction
    public enum CopilotError: Error, LocalizedError {
        case invalidAPIKey
        case invalidRequest
        case requestFailed(Error)
        case invalidResponse(String)
        case rateLimitExceeded
        case parsingError(String)
        case networkError(String)
        case unknownError(String)
        
        public var localizedDescription: String {
            switch self {
            case .invalidAPIKey:
                return "Invalid or missing API key. Please check your API key in the settings."
            case .invalidRequest:
                return "Invalid request to Copilot API."
            case .requestFailed(let error):
                return "Request to Copilot API failed: \(error.localizedDescription)"
            case .invalidResponse(let details):
                return "Invalid response from Copilot API: \(details)"
            case .rateLimitExceeded:
                return "Rate limit exceeded for Copilot API. Please try again later."
            case .parsingError(let details):
                return "Failed to parse Copilot API response: \(details)"
            case .networkError(let message):
                return "Network error: \(message)"
            case .unknownError(let details):
                return "Unknown error: \(details)"
            }
        }
    }
    
    /// Response from Copilot API
    public struct CopilotResponse: Decodable {
        public let choices: [Choice]
        
        public struct Choice: Decodable {
            public let text: String
            public let index: Int
            public let logprobs: LogProbs?
            public let finish_reason: String?
            
            public struct LogProbs: Decodable {
                // Define log probability structure based on API response
            }
        }
    }
    
    /// Copilot API configuration
    private let endpoint: String
    private let apiKey: String
    private let model: String
    
    /// Initialize with configuration
    /// - Parameters:
    ///   - apiKey: Copilot API key
    ///   - endpoint: API endpoint URL
    ///   - model: Model to use for generation
    public init(apiKey: String, endpoint: String = "https://api.github.com/copilot/v1/completions", model: String = "copilot-codex") {
        self.apiKey = apiKey
        self.endpoint = endpoint
        self.model = model
    }
    
    /// Generate code using Copilot API
    /// - Parameters:
    ///   - with: The prompt to send to Copilot
    ///   - completion: Completion handler with result
    public func generateCode(with prompt: String, completion: @escaping (Result<CopilotResponse, CopilotError>) -> Void) {
        // Validate API key
        guard !apiKey.isEmpty else {
            completion(.failure(.invalidAPIKey))
            return
        }
        
        // Create URL request
        guard let url = URL(string: endpoint) else {
            completion(.failure(.invalidRequest))
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        
        // Prepare JSON payload
        let payload: [String: Any] = [
            "model": model,
            "prompt": prompt,
            "max_tokens": 2000,
            "temperature": 0.7,
            "n": 1
        ]
        
        // Convert payload to JSON
        guard let httpBody = try? JSONSerialization.data(withJSONObject: payload) else {
            completion(.failure(.invalidRequest))
            return
        }
        
        request.httpBody = httpBody
        
        // Create and start task
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            // Handle network errors
            if let error = error {
                completion(.failure(.requestFailed(error)))
                return
            }
            
            // Validate HTTP response
            guard let httpResponse = response as? HTTPURLResponse else {
                completion(.failure(.invalidResponse("No HTTP response")))
                return
            }
            
            // Check HTTP status code
            switch httpResponse.statusCode {
            case 200..<300:
                // Success, continue to parse data
                break
            case 401:
                completion(.failure(.invalidAPIKey))
                return
            case 429:
                completion(.failure(.rateLimitExceeded))
                return
            default:
                completion(.failure(.networkError("HTTP status code: \(httpResponse.statusCode)")))
                return
            }
            
            // Parse response data
            guard let data = data else {
                completion(.failure(.invalidResponse("No data received")))
                return
            }
            
            do {
                let response = try JSONDecoder().decode(CopilotResponse.self, from: data)
                completion(.success(response))
            } catch {
                // Try to extract error message from JSON
                if let jsonObject = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                   let errorMessage = jsonObject["error"] as? String {
                    completion(.failure(.parsingError(errorMessage)))
                } else {
                    completion(.failure(.parsingError(error.localizedDescription)))
                }
            }
        }
        
        task.resume()
    }
    
    /// Extract code from Copilot's response text
    /// - Parameter responseText: The full text response from Copilot
    /// - Returns: Extracted code, or the original text if no code block found
    public func extractCodeFromResponse(_ responseText: String) -> String {
        // Look for code blocks marked with ```
        let codeBlockRegex = try? NSRegularExpression(pattern: "```(?:swift)?\\s*\\n([\\s\\S]*?)\\n```", options: [])
        
        if let match = codeBlockRegex?.firstMatch(in: responseText, range: NSRange(responseText.startIndex..., in: responseText)),
           let range = Range(match.range(at: 1), in: responseText) {
            return String(responseText[range]).trimmingCharacters(in: .whitespacesAndNewlines)
        }
        
        // If no code block found, return the original text
        return responseText
    }
}