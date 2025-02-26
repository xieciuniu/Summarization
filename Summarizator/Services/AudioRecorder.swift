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
