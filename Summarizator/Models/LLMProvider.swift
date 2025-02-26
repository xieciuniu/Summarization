import Foundation

enum LLMProvider: String, CaseIterable, Identifiable, Codable {
    case openAI = "OpenAI"
    case anthropic = "Anthropic"
    case gemini = "Google Gemini"
    case mistral = "Mistral AI"
    case ollama = "Ollama"
    
    var id: String { self.rawValue }
    
    var baseURL: String {
        switch self {
        case .openAI:
            return "https://api.openai.com/v1"
        case .anthropic:
            return "https://api.anthropic.com/v1"
        case .gemini:
            return "https://generativelanguage.googleapis.com/v1"
        case .mistral:
            return "https://api.mistral.ai/v1"
        case .ollama:
            return "http://localhost:11434/api"
        }
    }
    
    var defaultModel: String {
        switch self {
        case .openAI:
            return "gpt-4o"
        case .anthropic:
            return "claude-3-opus-20240229"
        case .gemini:
            return "gemini-1.5-pro"
        case .mistral:
            return "mistral-large-latest"
        case .ollama:
            return "llama3"
        }
    }
    
    var availableModels: [String] {
        switch self {
        case .openAI:
            return ["gpt-4o", "gpt-4-turbo", "gpt-3.5-turbo"]
        case .anthropic:
            return ["claude-3-opus-20240229", "claude-3-sonnet-20240229", "claude-3-haiku-20240307"]
        case .gemini:
            return ["gemini-1.5-pro", "gemini-1.5-flash", "gemini-pro"]
        case .mistral:
            return ["mistral-large-latest", "mistral-medium-latest", "mistral-small-latest"]
        case .ollama:
            return ["llama3", "mistral", "gemma"]
        }
    }
}
