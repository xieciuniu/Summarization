import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var settingsViewModel: SettingsViewModel
    @State private var showingAPIKeyInfo = false
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Dostawca LLM")) {
                    Picker("Dostawca", selection: $settingsViewModel.selectedLLMProvider) {
                        ForEach(LLMProvider.allCases) { provider in
                            Text(provider.rawValue).tag(provider)
                        }
                    }
                    .pickerStyle(MenuPickerStyle())
                    
                    Picker("Model", selection: $settingsViewModel.selectedModel) {
                        ForEach(settingsViewModel.selectedLLMProvider.availableModels, id: \.self) { model in
                            Text(model).tag(model)
                        }
                    }
                    .pickerStyle(MenuPickerStyle())
                }
                
                Section(header: Text("Klucz API"), footer: Text("Twój klucz API jest przechowywany bezpiecznie w iOS Keychain i jest używany tylko do komunikacji z wybranym dostawcą LLM.")) {
                    HStack {
                        if settingsViewModel.apiKey.isEmpty {
                            SecureField("Wprowadź klucz API", text: $settingsViewModel.apiKey) {
                                settingsViewModel.saveSettings()
                            }
                        } else {
                            SecureField("Klucz API (zapisany)", text: $settingsViewModel.apiKey) {
                                settingsViewModel.saveSettings()
                            }
                        }
                        
                        Button(action: {
                            showingAPIKeyInfo = true
                        }) {
                            Image(systemName: "info.circle")
                        }
                    }
                    
                    if !settingsViewModel.apiKey.isEmpty {
                        Button("Wyczyść klucz API") {
                            settingsViewModel.resetAPIKey()
                        }
                        .foregroundColor(.red)
                    }
                }
                
                Section(header: Text("Ustawienia instrukcji"), footer: Text("Dostosuj instrukcję używaną do określenia, jak model językowy ma formatować i strukturyzować twoje podsumowania wykładów.")) {
                    TextEditor(text: $settingsViewModel.customPrompt)
                        .frame(minHeight: 100)
                    
                    Button("Przywróć domyślne") {
                        settingsViewModel.customPrompt = "Stwórz szczegółowe podsumowanie poniższego wykładu. Uwzględnij kluczowe zagadnienia, pojęcia i istotne szczegóły. Sformatuj podsumowanie z nagłówkami, punktami i sekcjami dla łatwiejszej czytelności."
                    }
                }
                
                Section(header: Text("O aplikacji")) {
                    HStack {
                        Text("Wersja aplikacji")
                        Spacer()
                        Text("1.0.0")
                            .foregroundColor(.secondary)
                    }
                    
                    Link("Polityka prywatności", destination: URL(string: "https://example.com/privacy")!)
                    Link("Warunki korzystania", destination: URL(string: "https://example.com/terms")!)
                }
            }
            .navigationTitle("Ustawienia")
            .alert(isPresented: $showingAPIKeyInfo) {
                getAPIKeyInfoAlert(for: settingsViewModel.selectedLLMProvider)
            }
        }
    }
    
    private func getAPIKeyInfoAlert(for provider: LLMProvider) -> Alert {
        switch provider {
        case .openAI:
            return Alert(
                title: Text("Klucz API OpenAI"),
                message: Text("Możesz uzyskać klucz API z platformy OpenAI. Odwiedź https://platform.openai.com/account/api-keys, aby utworzyć lub zarządzać swoimi kluczami."),
                dismissButton: .default(Text("OK"))
            )
            
        case .anthropic:
            return Alert(
                title: Text("Klucz API Anthropic"),
                message: Text("Możesz uzyskać klucz API z konsoli Anthropic. Odwiedź https://console.anthropic.com/keys, aby utworzyć lub zarządzać swoimi kluczami."),
                dismissButton: .default(Text("OK"))
            )
            
        case .gemini:
            return Alert(
                title: Text("Klucz API Google Gemini"),
                message: Text("Możesz uzyskać klucz API z Google AI Studio. Odwiedź https://aistudio.google.com/app/apikey, aby utworzyć lub zarządzać swoimi kluczami."),
                dismissButton: .default(Text("OK"))
            )
            
        case .mistral:
            return Alert(
                title: Text("Klucz API Mistral"),
                message: Text("Możesz uzyskać klucz API z platformy Mistral. Odwiedź https://console.mistral.ai/api-keys/, aby utworzyć lub zarządzać swoimi kluczami."),
                dismissButton: .default(Text("OK"))
            )
            
        case .ollama:
            return Alert(
                title: Text("Ollama"),
                message: Text("Ollama działa lokalnie na twoim komputerze. Upewnij się, że masz zainstalowany i uruchomiony Ollama pod adresem http://localhost:11434. Klucz API nie jest wymagany."),
                dismissButton: .default(Text("OK"))
            )
        }
    }
}

struct SettingsView_Previews: PreviewProvider {
    static var previews: some View {
        SettingsView()
            .environmentObject(SettingsViewModel())
    }
}
