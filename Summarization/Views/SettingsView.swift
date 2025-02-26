import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var settingsViewModel: SettingsViewModel
    @State private var showingAPIKeyInfo = false
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("LLM Provider")) {
                    Picker("Provider", selection: $settingsViewModel.selectedLLMProvider) {
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
                
                Section(header: Text("API Key"), footer: Text("Your API key is stored securely in the iOS Keychain and is only used for communicating with the selected LLM provider.")) {
                    HStack {
                        if settingsViewModel.apiKey.isEmpty {
                            SecureField("Enter API Key", text: $settingsViewModel.apiKey) {
                                settingsViewModel.saveSettings()
                            }
                        } else {
                            SecureField("API Key (saved)", text: $settingsViewModel.apiKey) {
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
                        Button("Clear API Key") {
                            settingsViewModel.resetAPIKey()
                        }
                        .foregroundColor(.red)
                    }
                }
                
                Section(header: Text("Prompt Settings"), footer: Text("Customize the prompt used to instruct the LLM how to format and structure your lecture summaries.")) {
                    TextEditor(text: $settingsViewModel.customPrompt)
                        .frame(minHeight: 100)
                    
                    Button("Reset to Default") {
                        settingsViewModel.customPrompt = "Create a comprehensive summary of the following lecture. Include key points, concepts, and important details. Format the summary with headings, bullet points, and sections for easy readability."
                    }
                }
                
                Section(header: Text("About")) {
                    HStack {
                        Text("App Version")
                        Spacer()
                        Text("1.0.0")
                            .foregroundColor(.secondary)
                    }
                    
                    Link("Privacy Policy", destination: URL(string: "https://example.com/privacy")!)
                    Link("Terms of Service", destination: URL(string: "https://example.com/terms")!)
                }
            }
            .navigationTitle("Settings")
            .alert(isPresented: $showingAPIKeyInfo) {
                getAPIKeyInfoAlert(for: settingsViewModel.selectedLLMProvider)
            }
        }
    }
    
    private func getAPIKeyInfoAlert(for provider: LLMProvider) -> Alert {
        switch provider {
        case .openAI:
            return Alert(
                title: Text("OpenAI API Key"),
                message: Text("You can get your API key from the OpenAI platform. Visit https://platform.openai.com/account/api-keys to create or manage your keys."),
                dismissButton: .default(Text("OK"))
            )
            
        case .anthropic:
            return Alert(
                title: Text("Anthropic API Key"),
                message: Text("You can get your API key from the Anthropic Console. Visit https://console.anthropic.com/keys to create or manage your keys."),
                dismissButton: .default(Text("OK"))
            )
            
        case .gemini:
            return Alert(
                title: Text("Google Gemini API Key"),
                message: Text("You can get your API key from the Google AI Studio. Visit https://aistudio.google.com/app/apikey to create or manage your keys."),
                dismissButton: .default(Text("OK"))
            )
            
        case .mistral:
            return Alert(
                title: Text("Mistral API Key"),
                message: Text("You can get your API key from the Mistral platform. Visit https://console.mistral.ai/api-keys/ to create or manage your keys."),
                dismissButton: .default(Text("OK"))
            )
            
        case .ollama:
            return Alert(
                title: Text("Ollama"),
                message: Text("Ollama runs locally on your machine. Make sure you have Ollama installed and running at http://localhost:11434. No API key is required."),
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
