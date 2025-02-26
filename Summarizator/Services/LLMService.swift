import Foundation
import Combine

enum LLMServiceError: Error {
    case missingAPIKey
    case invalidURL
    case requestFailed(Error)
    case invalidResponse
    case rateLimited
    case authenticationFailed
    case missingProvider
    case parseError(Error)
}

class LLMService: ObservableObject {
    @Published var progress: Double = 0
    
    private let apiKeyManager = APIKeyManager()
    private let defaults = UserDefaults.standard
    
    func generateSummary(from text: String, provider: LLMProvider, model: String, completion: @escaping (Result<String, Error>) -> Void) {
        // Check for API key
        guard let apiKey = try? apiKeyManager.getAPIKey(for: provider.rawValue) else {
            completion(.failure(LLMServiceError.missingAPIKey))
            return
        }
        
        // Get custom prompt if available
        let customPrompt = defaults.string(forKey: "customPrompt") ?? "Stwórz szczegółowe podsumowanie poniższego wykładu. Uwzględnij kluczowe zagadnienia, pojęcia i istotne szczegóły. Sformatuj podsumowanie z nagłówkami, punktami i sekcjami dla łatwiejszej czytelności."
        
        // Update progress - started
        DispatchQueue.main.async {
            self.progress = 0.1
        }
        
        // Dispatch to another thread
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self = self else { return }
            
            // Choose the appropriate provider/model API implementation
            switch provider {
            case .openAI:
                self.generateOpenAISummary(text: text, apiKey: apiKey, model: model, prompt: customPrompt, completion: completion)
            case .anthropic:
                self.generateAnthropicSummary(text: text, apiKey: apiKey, model: model, prompt: customPrompt, completion: completion)
            case .gemini:
                self.generateGeminiSummary(text: text, apiKey: apiKey, model: model, prompt: customPrompt, completion: completion)
            case .mistral:
                self.generateMistralSummary(text: text, apiKey: apiKey, model: model, prompt: customPrompt, completion: completion)
            case .ollama:
                self.generateOllamaSummary(text: text, model: model, prompt: customPrompt, completion: completion)
            }
        }
    }
    
    // OpenAI API Implementation
    private func generateOpenAISummary(text: String, apiKey: String, model: String, prompt: String, completion: @escaping (Result<String, Error>) -> Void) {
        let endpoint = "https://api.openai.com/v1/chat/completions"
        
        guard let url = URL(string: endpoint) else {
            completion(.failure(LLMServiceError.invalidURL))
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.addValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        
        // Prepare the request payload
        let requestBody: [String: Any] = [
            "model": model,
            "messages": [
                ["role": "system", "content": prompt],
                ["role": "user", "content": text]
            ],
            "temperature": 0.3
        ]
        
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)
        } catch {
            completion(.failure(LLMServiceError.parseError(error)))
            return
        }
        
        // Update progress - sending request
        DispatchQueue.main.async {
            self.progress = 0.3
        }
        
        // Send the request
        URLSession.shared.dataTask(with: request) { [weak self] data, response, error in
            guard let self = self else { return }
            
            // Update progress - received response
            DispatchQueue.main.async {
                self.progress = 0.7
            }
            
            if let error = error {
                completion(.failure(LLMServiceError.requestFailed(error)))
                return
            }
            
            guard let httpResponse = response as? HTTPURLResponse else {
                completion(.failure(LLMServiceError.invalidResponse))
                return
            }
            
            // Handle HTTP status codes
            switch httpResponse.statusCode {
            case 200...299:
                // Success
                guard let data = data else {
                    completion(.failure(LLMServiceError.invalidResponse))
                    return
                }
                
                do {
                    if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
                       let choices = json["choices"] as? [[String: Any]],
                       let firstChoice = choices.first,
                       let message = firstChoice["message"] as? [String: Any],
                       let content = message["content"] as? String {
                        
                        // Update progress - completed
                        DispatchQueue.main.async {
                            self.progress = 1.0
                        }
                        
                        completion(.success(content))
                    } else {
                        completion(.failure(LLMServiceError.invalidResponse))
                    }
                } catch {
                    completion(.failure(LLMServiceError.parseError(error)))
                }
                
            case 401:
                completion(.failure(LLMServiceError.authenticationFailed))
            case 429:
                completion(.failure(LLMServiceError.rateLimited))
            default:
                completion(.failure(LLMServiceError.invalidResponse))
            }
        }.resume()
    }
    
    // Anthropic API Implementation
    private func generateAnthropicSummary(text: String, apiKey: String, model: String, prompt: String, completion: @escaping (Result<String, Error>) -> Void) {
        let endpoint = "https://api.anthropic.com/v1/messages"
        
        guard let url = URL(string: endpoint) else {
            completion(.failure(LLMServiceError.invalidURL))
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.addValue(apiKey, forHTTPHeaderField: "x-api-key")
        request.addValue("anthropic-swift-client/0.1", forHTTPHeaderField: "anthropic-version")
        
        // Prepare the request payload
        let requestBody: [String: Any] = [
            "model": model,
            "messages": [
                ["role": "user", "content": "\(prompt)\n\n\(text)"]
            ],
            "max_tokens": 4000,
            "temperature": 0.3
        ]
        
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)
        } catch {
            completion(.failure(LLMServiceError.parseError(error)))
            return
        }
        
        // Update progress - sending request
        DispatchQueue.main.async {
            self.progress = 0.3
        }
        
        // Send the request
        URLSession.shared.dataTask(with: request) { [weak self] data, response, error in
            guard let self = self else { return }
            
            // Update progress - received response
            DispatchQueue.main.async {
                self.progress = 0.7
            }
            
            if let error = error {
                completion(.failure(LLMServiceError.requestFailed(error)))
                return
            }
            
            guard let httpResponse = response as? HTTPURLResponse else {
                completion(.failure(LLMServiceError.invalidResponse))
                return
            }
            
            // Handle HTTP status codes
            switch httpResponse.statusCode {
            case 200...299:
                // Success
                guard let data = data else {
                    completion(.failure(LLMServiceError.invalidResponse))
                    return
                }
                
                do {
                    if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
                       let content = json["content"] as? [[String: Any]],
                       let firstContent = content.first,
                       let text = firstContent["text"] as? String {
                        
                        // Update progress - completed
                        DispatchQueue.main.async {
                            self.progress = 1.0
                        }
                        
                        completion(.success(text))
                    } else {
                        completion(.failure(LLMServiceError.invalidResponse))
                    }
                } catch {
                    completion(.failure(LLMServiceError.parseError(error)))
                }
                
            case 401:
                completion(.failure(LLMServiceError.authenticationFailed))
            case 429:
                completion(.failure(LLMServiceError.rateLimited))
            default:
                completion(.failure(LLMServiceError.invalidResponse))
            }
        }.resume()
    }
    
    // Google Gemini API Implementation
    private func generateGeminiSummary(text: String, apiKey: String, model: String, prompt: String, completion: @escaping (Result<String, Error>) -> Void) {
        let endpoint = "https://generativelanguage.googleapis.com/v1/models/\(model):generateContent?key=\(apiKey)"
        
        guard let url = URL(string: endpoint) else {
            completion(.failure(LLMServiceError.invalidURL))
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        
        // Prepare the request payload
        let requestBody: [String: Any] = [
            "contents": [
                ["role": "user", "parts": [
                    ["text": "\(prompt)\n\n\(text)"]
                ]]
            ],
            "generationConfig": [
                "temperature": 0.3,
                "topK": 40,
                "topP": 0.95,
                "maxOutputTokens": 8192
            ]
        ]
        
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)
        } catch {
            completion(.failure(LLMServiceError.parseError(error)))
            return
        }
        
        // Update progress - sending request
        DispatchQueue.main.async {
            self.progress = 0.3
        }
        
        // Send the request
        URLSession.shared.dataTask(with: request) { [weak self] data, response, error in
            guard let self = self else { return }
            
            // Update progress - received response
            DispatchQueue.main.async {
                self.progress = 0.7
            }
            
            if let error = error {
                completion(.failure(LLMServiceError.requestFailed(error)))
                return
            }
            
            guard let httpResponse = response as? HTTPURLResponse else {
                completion(.failure(LLMServiceError.invalidResponse))
                return
            }
            
            // Handle HTTP status codes
            switch httpResponse.statusCode {
            case 200...299:
                // Success
                guard let data = data else {
                    completion(.failure(LLMServiceError.invalidResponse))
                    return
                }
                
                do {
                    if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
                       let candidates = json["candidates"] as? [[String: Any]],
                       let firstCandidate = candidates.first,
                       let content = firstCandidate["content"] as? [String: Any],
                       let parts = content["parts"] as? [[String: Any]],
                       let firstPart = parts.first,
                       let text = firstPart["text"] as? String {
                        
                        // Update progress - completed
                        DispatchQueue.main.async {
                            self.progress = 1.0
                        }
                        
                        completion(.success(text))
                    } else {
                        completion(.failure(LLMServiceError.invalidResponse))
                    }
                } catch {
                    completion(.failure(LLMServiceError.parseError(error)))
                }
                
            case 401:
                completion(.failure(LLMServiceError.authenticationFailed))
            case 429:
                completion(.failure(LLMServiceError.rateLimited))
            default:
                completion(.failure(LLMServiceError.invalidResponse))
            }
        }.resume()
    }
    
    // Mistral AI implementation
    private func generateMistralSummary(text: String, apiKey: String, model: String, prompt: String, completion: @escaping (Result<String, Error>) -> Void) {
        let endpoint = "https://api.mistral.ai/v1/chat/completions"
        
        guard let url = URL(string: endpoint) else {
            completion(.failure(LLMServiceError.invalidURL))
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.addValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        
        // Prepare the request payload
        let requestBody: [String: Any] = [
            "model": model,
            "messages": [
                ["role": "system", "content": prompt],
                ["role": "user", "content": text]
            ],
            "temperature": 0.3,
            "max_tokens": 4096
        ]
        
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)
        } catch {
            completion(.failure(LLMServiceError.parseError(error)))
            return
        }
        
        // Update progress - sending request
        DispatchQueue.main.async {
            self.progress = 0.3
        }
        
        // Send the request
        URLSession.shared.dataTask(with: request) { [weak self] data, response, error in
            guard let self = self else { return }
            
            // Update progress - received response
            DispatchQueue.main.async {
                self.progress = 0.7
            }
            
            if let error = error {
                completion(.failure(LLMServiceError.requestFailed(error)))
                return
            }
            
            guard let httpResponse = response as? HTTPURLResponse else {
                completion(.failure(LLMServiceError.invalidResponse))
                return
            }
            
            // Handle HTTP status codes
            switch httpResponse.statusCode {
            case 200...299:
                // Success
                guard let data = data else {
                    completion(.failure(LLMServiceError.invalidResponse))
                    return
                }
                
                do {
                    if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
                       let choices = json["choices"] as? [[String: Any]],
                       let firstChoice = choices.first,
                       let message = firstChoice["message"] as? [String: Any],
                       let content = message["content"] as? String {
                        
                        // Update progress - completed
                        DispatchQueue.main.async {
                            self.progress = 1.0
                        }
                        
                        completion(.success(content))
                    } else {
                        completion(.failure(LLMServiceError.invalidResponse))
                    }
                } catch {
                    completion(.failure(LLMServiceError.parseError(error)))
                }
                
            case 401:
                completion(.failure(LLMServiceError.authenticationFailed))
            case 429:
                completion(.failure(LLMServiceError.rateLimited))
            default:
                completion(.failure(LLMServiceError.invalidResponse))
            }
        }.resume()
    }
    
    // Ollama API implementation (local)
    private func generateOllamaSummary(text: String, model: String, prompt: String, completion: @escaping (Result<String, Error>) -> Void) {
        let endpoint = "http://localhost:11434/api/generate"
        
        guard let url = URL(string: endpoint) else {
            completion(.failure(LLMServiceError.invalidURL))
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        
        // Prepare the request payload
        let requestBody: [String: Any] = [
            "model": model,
            "prompt": "\(prompt)\n\n\(text)",
            "stream": false,
            "options": [
                "temperature": 0.3,
                "num_predict": 4096
            ]
        ]
        
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)
        } catch {
            completion(.failure(LLMServiceError.parseError(error)))
            return
        }
        
        // Update progress - sending request
        DispatchQueue.main.async {
            self.progress = 0.3
        }
        
        // Send the request
        URLSession.shared.dataTask(with: request) { [weak self] data, response, error in
            guard let self = self else { return }
            
            // Update progress - received response
            DispatchQueue.main.async {
                self.progress = 0.7
            }
            
            if let error = error {
                completion(.failure(LLMServiceError.requestFailed(error)))
                return
            }
            
            guard let httpResponse = response as? HTTPURLResponse else {
                completion(.failure(LLMServiceError.invalidResponse))
                return
            }
            
            // Handle HTTP status codes
            switch httpResponse.statusCode {
            case 200...299:
                // Success
                guard let data = data else {
                    completion(.failure(LLMServiceError.invalidResponse))
                    return
                }
                
                do {
                    if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
                       let response = json["response"] as? String {
                        
                        // Update progress - completed
                        DispatchQueue.main.async {
                            self.progress = 1.0
                        }
                        
                        completion(.success(response))
                    } else {
                        completion(.failure(LLMServiceError.invalidResponse))
                    }
                } catch {
                    completion(.failure(LLMServiceError.parseError(error)))
                }
                
            default:
                completion(.failure(LLMServiceError.invalidResponse))
            }
        }.resume()
    }
}
