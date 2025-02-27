import Foundation
import AVFoundation

class AudioRecorder: NSObject, ObservableObject {
    @Published var recordingState: RecordingState = .idle
    
    private var audioRecorder: AVAudioRecorder?
    private var recordingSession: AVAudioSession?
    private var recordingTitle: String = ""
    private var tempURL: URL?
    
    override init() {
        super.init()
        setupRecordingSession()
    }
    
    private func setupRecordingSession() {
        recordingSession = AVAudioSession.sharedInstance()
        
        do {
            try recordingSession?.setCategory(.playAndRecord, mode: .default)
            try recordingSession?.setActive(true)
        } catch {
            print("Failed to set up recording session: \(error)")
        }
    }
    
    // MARK: - Nagrywanie
    
    func startRecording(title: String, completion: @escaping (Result<URL, Error>) -> Void) {
        // Request permission if not already granted
        recordingSession?.requestRecordPermission() { [weak self] allowed in
            guard let self = self else { return }
            
            if allowed {
                self.recordingTitle = title
                
                let fileManager = FileManager.default
                let documentsDirectory = fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]
                let audioFilename = documentsDirectory.appendingPathComponent("\(title)_\(Date().timeIntervalSince1970).m4a")
                
                self.tempURL = audioFilename
                
                let settings = [
                    AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
                    AVSampleRateKey: 44100,
                    AVNumberOfChannelsKey: 2,
                    AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue
                ]
                
                do {
                    self.audioRecorder = try AVAudioRecorder(url: audioFilename, settings: settings)
                    self.audioRecorder?.delegate = self
                    self.audioRecorder?.record()
                    self.recordingState = .recording
                    completion(.success(audioFilename))
                } catch {
                    completion(.failure(error))
                }
            } else {
                completion(.failure(NSError(domain: "AudioRecorderError", code: 1, userInfo: [NSLocalizedDescriptionKey: "Recording permission not granted"])))
            }
        }
    }
    
    func pauseRecording() {
        guard recordingState == .recording, let recorder = audioRecorder else { return }
        
        recorder.pause()
        recordingState = .paused
    }
    
    func resumeRecording() {
        guard recordingState == .paused, let recorder = audioRecorder else { return }
        
        recorder.record()
        recordingState = .recording
    }
    
    func stopRecording(completion: @escaping (Result<Recording, Error>) -> Void) {
        guard let recorder = audioRecorder, let url = tempURL else {
            completion(.failure(NSError(domain: "AudioRecorderError", code: 2, userInfo: [NSLocalizedDescriptionKey: "No active recording"])))
            return
        }
        
        let duration = recorder.currentTime
        recorder.stop()
        self.audioRecorder = nil
        recordingState = .finished
        
        let recording = Recording(
            title: recordingTitle,
            duration: duration,
            fileURL: url
        )
        
        completion(.success(recording))
    }
    
    // MARK: - Import Audio
    
    enum AudioImportError: Error {
        case invalidURL
        case copyFailed
        case durationRetrievalFailed
        case unsupportedFormat
    }
    
    func importAudio(from sourceURL: URL, withTitle title: String, completion: @escaping (Result<Recording, Error>) -> Void) {
        // Sprawdź, czy format pliku jest obsługiwany
        guard isAudioFormatSupported(sourceURL) else {
            completion(.failure(AudioImportError.unsupportedFormat))
            return
        }
        
        // Utwórz docelowy URL w katalogu dokumentów aplikacji
        let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let destinationFilename = "\(title)_\(Date().timeIntervalSince1970).\(sourceURL.pathExtension)"
        let destinationURL = documentsDirectory.appendingPathComponent(destinationFilename)
        
        // Kopiuj plik
        do {
            // Jeśli plik już istnieje, usuń go
            if FileManager.default.fileExists(atPath: destinationURL.path) {
                try FileManager.default.removeItem(at: destinationURL)
            }
            
            // Kopiuj plik
            try FileManager.default.copyItem(at: sourceURL, to: destinationURL)
            
            // Pobierz czas trwania pliku audio
            getAudioDuration(url: destinationURL) { result in
                switch result {
                case .success(let duration):
                    // Utwórz obiekt Recording
                    let recording = Recording(
                        title: title,
                        date: Date(),
                        duration: duration,
                        fileURL: destinationURL
                    )
                    completion(.success(recording))
                case .failure(let error):
                    // W przypadku błędu pobierania czasu trwania, usuń skopiowany plik
                    try? FileManager.default.removeItem(at: destinationURL)
                    completion(.failure(error))
                }
            }
        } catch {
            completion(.failure(AudioImportError.copyFailed))
        }
    }
    
    // Sprawdź, czy format pliku audio jest obsługiwany
    private func isAudioFormatSupported(_ url: URL) -> Bool {
        let supportedExtensions = ["mp3", "m4a", "wav", "aac", "aif", "aiff"]
        return supportedExtensions.contains(url.pathExtension.lowercased())
    }
    
    // Pobierz czas trwania pliku audio
    private func getAudioDuration(url: URL, completion: @escaping (Result<TimeInterval, Error>) -> Void) {
        let asset = AVAsset(url: url)
        let durationKey = "duration"
        
        asset.loadValuesAsynchronously(forKeys: [durationKey]) {
            var error: NSError? = nil
            let status = asset.statusOfValue(forKey: durationKey, error: &error)
            
            DispatchQueue.main.async {
                if status == .loaded {
                    let duration = CMTimeGetSeconds(asset.duration)
                    completion(.success(duration))
                } else {
                    completion(.failure(error ?? AudioImportError.durationRetrievalFailed))
                }
            }
        }
    }
}

extension AudioRecorder: AVAudioRecorderDelegate {
    func audioRecorderDidFinishRecording(_ recorder: AVAudioRecorder, successfully flag: Bool) {
        if !flag {
            recordingState = .idle
            print("Recording failed")
        }
    }
    
    func audioRecorderEncodeErrorDidOccur(_ recorder: AVAudioRecorder, error: Error?) {
        recordingState = .idle
        if let error = error {
            print("Recording encode error: \(error)")
        }
    }
}
