import Foundation
import Speech
import AVFoundation

class TranscriptionService: NSObject, ObservableObject {
    @Published var progress: Double = 0
    
    private let speechRecognizer = SFSpeechRecognizer(locale: Locale(identifier: "pl-PL"))
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    private var audioEngine: AVAudioEngine?
    
    func transcribeAudio(url: URL, completion: @escaping (Result<String, Error>) -> Void) {
        SFSpeechRecognizer.requestAuthorization { [weak self] status in
            guard let self = self else { return }
            
            DispatchQueue.main.async {
                switch status {
                case .authorized:
                    self.startTranscription(url: url, completion: completion)
                case .denied:
                    completion(.failure(NSError(domain: "TranscriptionError", code: 1, userInfo: [NSLocalizedDescriptionKey: "Odmówiono dostępu do rozpoznawania mowy"])))
                case .restricted, .notDetermined:
                    completion(.failure(NSError(domain: "TranscriptionError", code: 2, userInfo: [NSLocalizedDescriptionKey: "Rozpoznawanie mowy niedostępne"])))
                @unknown default:
                    completion(.failure(NSError(domain: "TranscriptionError", code: 3, userInfo: [NSLocalizedDescriptionKey: "Nieznany status autoryzacji"])))
                }
            }
        }
    }
    
    private func startTranscription(url: URL, completion: @escaping (Result<String, Error>) -> Void) {
        // Clean up any existing task
        recognitionTask?.cancel()
        recognitionTask = nil
        
        // Set up audio session
        let audioSession = AVAudioSession.sharedInstance()
        do {
            try audioSession.setCategory(.playback, mode: .default)
            try audioSession.setActive(true, options: .notifyOthersOnDeactivation)
        } catch {
            completion(.failure(error))
            return
        }
        
        // Create recognition request
        let recognitionRequest = SFSpeechURLRecognitionRequest(url: url)
        recognitionRequest.shouldReportPartialResults = true
        recognitionRequest.taskHint = .dictation
        
        // Keep track of transcript
        var transcript = ""
        
        // Start recognition
        recognitionTask = speechRecognizer?.recognitionTask(with: recognitionRequest) { [weak self] result, error in
            guard let self = self else { return }
            
            var isFinal = false
            
            if let result = result {
                transcript = result.bestTranscription.formattedString
                isFinal = result.isFinal
                
                // Update progress based on audio processing
                if let audioFile = try? AVAudioFile(forReading: url) {
                    let duration = Double(audioFile.length) / audioFile.processingFormat.sampleRate
                    let currentTime = result.bestTranscription.segments.last?.timestamp ?? 0
                    let newProgress = min(currentTime / duration, 1.0)
                    DispatchQueue.main.async {
                        self.progress = newProgress
                    }
                }
            }
            
            if error != nil || isFinal {
                // Clean up
                self.recognitionTask = nil
                
                if let error = error {
                    completion(.failure(error))
                } else {
                    completion(.success(transcript))
                }
            }
        }
    }
}
