swift
import Foundation

/// Service responsible for interacting with Copilot API
public class CopilotService {
    
    /// Errors that can occur during Copilot API interaction
    public enum CopilotError: Error {
        case invalidAPIKey
        case invalidRequest
        case requestFailed(Error)
        case invalidResponse(String)
        case rateLimitExceeded
        case parsingError(String)
        case networkError(Int)
        case unknownError(String)
        case connectionError(Int?)
        
        var localizedDescription: String {
            switch self {
            case .invalidAPIKey:
                return "Invalid or missing API key. Please check your Anthropic API key in the settings."
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
            case .networkError(let code):
                return "Network error: \(code)"
            case .unknownError(let details):
                return "Unknown error: \(details)"
            case .connectionError(let code):
                return "Connection error: \(code)"
              }
        }
    }
    
    /// Response from Copilot API
    public struct CopilotResponse: Decodable {
        public let choices: [Choice]
    }

    public struct Choice: Decodable {
        public let text: String
        public let index: Int
        public let logprobs: String?
        public let finish_reason: String?
    }
    
    /// Copilot API configuration
    private let endpoint: String
    private let apiKey: String
    private let model: String
    
    /// Initialize with configuration
    /// - Parameters:
    ///   - apiKey: Copilot API key
    ///   - endpoint: API endpoint URL
    public init(apiKey: String, endpoint: String = "https://api.github.com/copilot_internal/v2/completions", model: String = "copilot-codex") {
        self.apiKey = apiKey
        self.endpoint = endpoint
        self.model = model // Using the model parameter
    }
    
    /// Generate code using Copilot API
      /// - Parameters:
      ///   - prompt: The prompt to send to Copilot
      ///   - completion: Completion handler with result
    public func generateCode(prompt: String, completion: @escaping (Result<String, CopilotError>) -> Void) {
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
        request.setValue("GitHubCopilot/0.0.0", forHTTPHeaderField: "User-Agent")
        request.setValue("vscode.github-copilot/1.17.2639", forHTTPHeaderField: "X-Request-Source")
        request.setValue("2023-07-01", forHTTPHeaderField: "OpenAI-Intent")
        
        // Prepare JSON payload
        let payload: [String: Any] = [
            "model": model,
            "prompt": prompt,
            "max_tokens": 2000,
            "n": 1 // Request a single completion
        ]
        
        request.httpBody = try? JSONSerialization.data(withJSONObject: payload)
        guard let httpBody = request.httpBody else {
            completion(.failure(.invalidRequest))
            return
        }
        
        // Create and start task
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            // Check for network errors
            if let error = error {
                if let urlError = error as? URLError {
                    if let errorCode = (urlError as NSError).code as Int? {
                        completion(.failure(.networkError(errorCode)))
                    } else {
                        completion(.failure(.requestFailed(error)))
                    }
                } else if let nsError = error as NSError? {
                    completion(.failure(.networkError(nsError.code)))
                } else {
                        completion(.failure(.requestFailed(error)))
                    }
                } else {
                    completion(.failure(.requestFailed(error)))
                }
                return
            }
            
            // Check HTTP status code
            if let httpResponse = response as? HTTPURLResponse {
                switch httpResponse.statusCode {
                case 401:
                    completion(.failure(.invalidAPIKey))
                    return
                case 429:
                    completion(.failure(.rateLimitExceeded))
                    return
                case 400..<500:
                    completion(.failure(.invalidRequest))
                    return
                case 500..<600:
                    completion(.failure(.invalidResponse("Server error \(httpResponse.statusCode)")))
                    return
                default:
                    break // Continue processing for status 200

                }
            }
            
                guard let data = data else {
                    completion(.failure(.invalidResponse("No data received")))
                    return
                }

                do {
                    let decoder = JSONDecoder()
                    let response = try decoder.decode(CopilotResponse.self, from: data)
                    let generatedCode = extractCodeFromResponse(response.choices.first?.text ?? "")
                    completion(.success(generatedCode))
                } catch {
                    if let stringResponse = String(data: data, encoding: .utf8) {
                        completion(.failure(.invalidResponse("JSON parsing error: \(error.localizedDescription). Raw response: \(stringResponse)")))
                    } else {
                        completion(.failure(.parsingError("JSON parsing error: \(error.localizedDescription). Failed to decode raw response.")))
                    }
                }
            }
        }
        
        task.resume()
    }
    
    /// Check connection to the Copilot API
    /// - Parameter completion: Completion handler with result (true if connection is successful)
    public func checkConnection(completion: @escaping (Result<Bool, CopilotError>) -> Void) {
        guard !apiKey.isEmpty else {
            completion(.failure(.invalidAPIKey))
            return
        }
        
        guard let url = URL(string: endpoint) else {
            completion(.failure(.invalidRequest))
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        
        let task = URLSession.shared.dataTask(with: request) { _, response, error in
            if let error = error {
                if let urlError = error as? URLError {
                    completion(.failure(.connectionError((urlError as NSError).code)))
                } else {
                    completion(.failure(.requestFailed(error)))
                }
                return
            }
            
            if let httpResponse = response as? HTTPURLResponse {
                switch httpResponse.statusCode {
                case 200..<300:
                     completion(.success(true))
                case 401:
                    completion(.failure(.invalidAPIKey))
                case 429:
                    completion(.failure(.rateLimitExceeded))
                case let code:
                    completion(.failure(.connectionError(code)))
                }
            } else {
                completion(.failure(.invalidResponse("No HTTP response")))
            }
        }
        
        task.resume()
    }


    /// Extract code from Copilot's response text
    /// - Parameter responseText: The full text response from Copilot
    /// - Returns: Extracted code, or the original text if no code block found
    public func extractCodeFromResponse(_ responseText: String) -> String {
        // Look for Swift code blocks
        if let codeStartIndex = responseText.range(of: "
```
swift")?.upperBound,
           let codeEndIndex = responseText.range(of: "
```
", range: codeStartIndex..<responseText.endIndex)?.lowerBound {
            
            return String(responseText[codeStartIndex..<codeEndIndex]).trimmingCharacters(in: .whitespacesAndNewlines)
        }
        
        // Look for generic code blocks if no Swift blocks found
        if let codeStartIndex = responseText.range(of: "
```
")?.upperBound,
           let codeEndIndex = responseText.range(of: "
```
", range: codeStartIndex..<responseText.endIndex)?.lowerBound {
            
            return String(responseText[codeStartIndex..<codeEndIndex]).trimmingCharacters(in: .whitespacesAndNewlines)
        }
        
        // If no code blocks found, return the entire text
        return responseText
    }
}