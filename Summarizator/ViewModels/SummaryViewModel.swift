import Foundation
import Combine

class SummaryViewModel: ObservableObject {
    @Published var summary: Summary?
    @Published var isGenerating: Bool = false
    @Published var progress: Double = 0
    @Published var error: String?
    
    private var cancellables = Set<AnyCancellable>()
    private var llmService: LLMService
    private var storageService: StorageService
    
    init(llmService: LLMService = LLMService(),
         storageService: StorageService = StorageService()) {
        self.llmService = llmService
        self.storageService = storageService
    }
    
    func loadSummary(for recordingID: UUID) {
        storageService.loadSummary(for: recordingID) { [weak self] result in
            DispatchQueue.main.async {
                switch result {
                case .success(let summary):
                    self?.summary = summary
                case .failure(let error):
                    self?.error = "Failed to load summary: \(error.localizedDescription)"
                }
            }
        }
    }
    
    func generateSummary(for transcript: Transcript, recording: Recording, selectedProvider: LLMProvider, selectedModel: String) {
        isGenerating = true
        progress = 0
        error = nil
        
        // Create initial summary
        let newSummary = Summary(
            transcriptID: transcript.id,
            recordingID: recording.id,
            isProcessing: true,
            llmType: "\(selectedProvider.rawValue) - \(selectedModel)"
        )
        self.summary = newSummary
        
        // Save it to update the recording's reference
        saveSummary(newSummary) { [weak self] result in
            switch result {
            case .success(let savedSummary):
                self?.summary = savedSummary
                
                // Update recording with summary ID
                var updatedRecording = recording
                updatedRecording.summaryID = savedSummary.id
                self?.updateRecording(updatedRecording)
                
                // Start summary generation
                self?.startSummaryGeneration(transcript, summary: savedSummary, provider: selectedProvider, model: selectedModel)
                
            case .failure(let error):
                DispatchQueue.main.async {
                    self?.isGenerating = false
                    self?.error = "Failed to save initial summary: \(error.localizedDescription)"
                }
            }
        }
    }
    
    private func startSummaryGeneration(_ transcript: Transcript, summary: Summary, provider: LLMProvider, model: String) {
        llmService.generateSummary(from: transcript.text, provider: provider, model: model) { [weak self] result in
            DispatchQueue.main.async {
                self?.isGenerating = false
                
                switch result {
                case .success(let summaryText):
                    var updatedSummary = summary
                    updatedSummary.text = summaryText
                    updatedSummary.isProcessing = false
                    self?.summary = updatedSummary
                    
                    // Save the completed summary
                    self?.saveSummary(updatedSummary) { _ in }
                    
                case .failure(let error):
                    self?.error = "Summary generation failed: \(error.localizedDescription)"
                    
                    // Update summary to show it's no longer processing
                    var updatedSummary = summary
                    updatedSummary.isProcessing = false
                    self?.summary = updatedSummary
                    self?.saveSummary(updatedSummary) { _ in }
                }
            }
        }
        
        // Set up progress updates
        llmService.$progress
            .receive(on: DispatchQueue.main)
            .sink { [weak self] newProgress in
                self?.progress = newProgress
            }
            .store(in: &cancellables)
    }
    
    private func saveSummary(_ summary: Summary, completion: @escaping (Result<Summary, Error>) -> Void) {
        storageService.saveSummary(summary) { result in
            completion(result)
        }
    }
    
    private func updateRecording(_ recording: Recording) {
        storageService.updateRecording(recording) { _ in }
    }
}
