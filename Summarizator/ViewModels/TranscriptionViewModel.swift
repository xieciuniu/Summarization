import Foundation
import Combine

class TranscriptionViewModel: ObservableObject {
    @Published var transcript: Transcript?
    @Published var isTranscribing: Bool = false
    @Published var progress: Double = 0
    @Published var error: String?
    
    private var cancellables = Set<AnyCancellable>()
    private var transcriptionService: TranscriptionService
    private var storageService: StorageService
    
    init(transcriptionService: TranscriptionService = TranscriptionService(),
         storageService: StorageService = StorageService()) {
        self.transcriptionService = transcriptionService
        self.storageService = storageService
    }
    
    func loadTranscript(for recordingID: UUID) {
        storageService.loadTranscript(for: recordingID) { [weak self] result in
            DispatchQueue.main.async {
                switch result {
                case .success(let transcript):
                    self?.transcript = transcript
                case .failure(let error):
                    self?.error = "Failed to load transcript: \(error.localizedDescription)"
                }
            }
        }
    }
    
    func transcribeRecording(_ recording: Recording) {
        isTranscribing = true
        progress = 0
        error = nil
        
        // Create initial transcript
        let newTranscript = Transcript(recordingID: recording.id, isProcessing: true)
        self.transcript = newTranscript
        
        // Save it to update the recording's reference
        saveTranscript(newTranscript) { [weak self] result in
            switch result {
            case .success(let savedTranscript):
                self?.transcript = savedTranscript
                
                // Update recording with transcript ID
                var updatedRecording = recording
                updatedRecording.transcriptID = savedTranscript.id
                self?.updateRecording(updatedRecording)
                
                // Start transcription
                self?.startTranscription(recording, transcript: savedTranscript)
                
            case .failure(let error):
                DispatchQueue.main.async {
                    self?.isTranscribing = false
                    self?.error = "Failed to save initial transcript: \(error.localizedDescription)"
                }
            }
        }
    }
    
    private func startTranscription(_ recording: Recording, transcript: Transcript) {
        transcriptionService.transcribeAudio(url: recording.fileURL) { [weak self] result in
            DispatchQueue.main.async {
                self?.isTranscribing = false
                
                switch result {
                case .success(let transcribedText):
                    var updatedTranscript = transcript
                    updatedTranscript.text = transcribedText
                    updatedTranscript.isProcessing = false
                    self?.transcript = updatedTranscript
                    
                    // Save the completed transcript
                    self?.saveTranscript(updatedTranscript) { _ in }
                    
                case .failure(let error):
                    self?.error = "Transcription failed: \(error.localizedDescription)"
                    
                    // Update transcript to show it's no longer processing
                    var updatedTranscript = transcript
                    updatedTranscript.isProcessing = false
                    self?.transcript = updatedTranscript
                    self?.saveTranscript(updatedTranscript) { _ in }
                }
            }
        }
        
        // Set up progress updates
        transcriptionService.$progress
            .receive(on: DispatchQueue.main)
            .sink { [weak self] newProgress in
                self?.progress = newProgress
            }
            .store(in: &cancellables)
    }
    
    private func saveTranscript(_ transcript: Transcript, completion: @escaping (Result<Transcript, Error>) -> Void) {
        storageService.saveTranscript(transcript) { result in
            completion(result)
        }
    }
    
    private func updateRecording(_ recording: Recording) {
        storageService.updateRecording(recording) { _ in }
    }
}
