import Foundation
import Combine

class SettingsViewModel: ObservableObject {
    @Published var selectedLLMProvider: LLMProvider = .openAI
    @Published var selectedModel: String = ""
    @Published var apiKey: String = ""
    @Published var customPrompt: String = "Stwórz szczegółowe podsumowanie poniższego wykładu. Uwzględnij kluczowe zagadnienia, pojęcia i istotne szczegóły. Sformatuj podsumowanie z nagłówkami, punktami i sekcjami dla łatwiejszej czytelności."
    
    private var cancellables = Set<AnyCancellable>()
    private let keychain = APIKeyManager()
    private let defaults = UserDefaults.standard
    
    private let providerKey = "selectedLLMProvider"
    private let modelKey = "selectedModel"
    private let promptKey = "customPrompt"
    
    init() {
        loadSettings()
        
        // Update selected model when provider changes
        $selectedLLMProvider
            .sink { [weak self] provider in
                self?.selectedModel = provider.defaultModel
                self?.saveSettings()
            }
            .store(in: &cancellables)
        
        // Save settings when model changes
        $selectedModel
            .dropFirst()
            .sink { [weak self] _ in
                self?.saveSettings()
            }
            .store(in: &cancellables)
        
        // Save settings when custom prompt changes
        $customPrompt
            .dropFirst()
            .debounce(for: .seconds(0.5), scheduler: RunLoop.main)
            .sink { [weak self] _ in
                self?.saveSettings()
            }
            .store(in: &cancellables)
    }
    
    func loadSettings() {
        // Load provider
        if let providerString = defaults.string(forKey: providerKey),
           let provider = LLMProvider(rawValue: providerString) {
            selectedLLMProvider = provider
        }
        
        // Load model
        if let model = defaults.string(forKey: modelKey),
           selectedLLMProvider.availableModels.contains(model) {
            selectedModel = model
        } else {
            selectedModel = selectedLLMProvider.defaultModel
        }
        
        // Load API key
        if let key = try? keychain.getAPIKey(for: selectedLLMProvider.rawValue) {
            apiKey = key
        }
        
        // Load custom prompt
        if let prompt = defaults.string(forKey: promptKey) {
            customPrompt = prompt
        }
    }
    
    func saveSettings() {
        // Save provider and model
        defaults.set(selectedLLMProvider.rawValue, forKey: providerKey)
        defaults.set(selectedModel, forKey: modelKey)
        defaults.set(customPrompt, forKey: promptKey)
        
        // Save API key securely
        if !apiKey.isEmpty {
            try? keychain.saveAPIKey(apiKey, for: selectedLLMProvider.rawValue)
        }
    }
    
    func resetAPIKey() {
        apiKey = ""
        try? keychain.deleteAPIKey(for: selectedLLMProvider.rawValue)
    }
}
