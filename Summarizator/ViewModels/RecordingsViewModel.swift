import Foundation
import Combine
import SwiftUI
import AVFoundation

class RecordingsViewModel: ObservableObject {
    @Published var recordings: [Recording] = []
    @Published var selectedRecording: Recording?
    @Published var recordingState: RecordingState = .idle
    @Published var recordingTime: TimeInterval = 0
    @Published var isLoading: Bool = false
    @Published var importError: String?
    
    private var audioRecorder: AudioRecorder
    private var audioImportService: AudioImportService
    private var storageService: StorageService
    private var cancellables = Set<AnyCancellable>()
    private var timer: Timer?
    
    init(audioRecorder: AudioRecorder = AudioRecorder(),
         audioImportService: AudioImportService = AudioImportService(),
         storageService: StorageService = StorageService()) {
        self.audioRecorder = audioRecorder
        self.audioImportService = audioImportService
        self.storageService = storageService
        
        loadRecordings()
        setupBindings()
    }
    
    private func setupBindings() {
        audioRecorder.$recordingState
            .sink { [weak self] state in
                self?.recordingState = state
                if state == .recording {
                    self?.startTimer()
                } else if state == .paused {
                    self?.stopTimer()
                } else if state == .finished {
                    self?.stopTimer()
                    self?.recordingTime = 0
                }
            }
            .store(in: &cancellables)
    }
    
    func loadRecordings() {
        isLoading = true
        storageService.loadRecordings { [weak self] result in
            DispatchQueue.main.async {
                self?.isLoading = false
                switch result {
                case .success(let recordings):
                    self?.recordings = recordings.sorted(by: { $0.date > $1.date })
                case .failure(let error):
                    print("Failed to load recordings: \(error)")
                }
            }
        }
    }
    
    // MARK: - Nagrywanie
    
    func startRecording(title: String) {
        audioRecorder.startRecording(title: title) { [weak self] result in
            DispatchQueue.main.async {
                switch result {
                case .success(let fileURL):
                    print("Recording started at \(fileURL)")
                case .failure(let error):
                    print("Failed to start recording: \(error)")
                }
            }
        }
    }
    
    func pauseRecording() {
        audioRecorder.pauseRecording()
    }
    
    func resumeRecording() {
        audioRecorder.resumeRecording()
    }
    
    func stopRecording() {
        audioRecorder.stopRecording { [weak self] result in
            DispatchQueue.main.async {
                switch result {
                case .success(let recording):
                    self?.addRecording(recording)
                case .failure(let error):
                    print("Failed to stop recording: \(error)")
                }
            }
        }
    }
    
    // MARK: - Importowanie plików
    
    func importAudio(from url: URL, withTitle title: String? = nil) {
        // Wyczyść poprzednie błędy
        importError = nil
        
        // Użyj tytułu podanego przez użytkownika lub nazwy pliku bez rozszerzenia
        let fileTitle = title ?? url.deletingPathExtension().lastPathComponent
        
        // Zaimportuj plik
        audioImportService.importAudio(from: url, withTitle: fileTitle) { [weak self] result in
            DispatchQueue.main.async {
                switch result {
                case .success(let recording):
                    self?.addRecording(recording)
                case .failure(let error):
                    self?.importError = "Błąd importowania pliku: \(error.localizedDescription)"
                    print("Import error: \(error)")
                }
            }
        }
    }
    
    // MARK: - Zarządzanie nagraniami
    
    func addRecording(_ recording: Recording) {
        recordings.insert(recording, at: 0)
        saveRecordings()
    }
    
    func updateRecording(_ recording: Recording) {
        if let index = recordings.firstIndex(where: { $0.id == recording.id }) {
            recordings[index] = recording
            saveRecordings()
        }
    }
    
    func deleteRecording(_ recording: Recording) {
        if let index = recordings.firstIndex(where: { $0.id == recording.id }) {
            do {
                try FileManager.default.removeItem(at: recording.fileURL)
                recordings.remove(at: index)
                saveRecordings()
            } catch {
                print("Failed to delete recording file: \(error)")
            }
        }
    }
    
    private func saveRecordings() {
        storageService.saveRecordings(recordings) { result in
            switch result {
            case .success:
                print("Recordings saved successfully")
            case .failure(let error):
                print("Failed to save recordings: \(error)")
            }
        }
    }
    
    // MARK: - Timer i formatowanie
    
    private func startTimer() {
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            self?.recordingTime += 1.0
        }
    }
    
    private func stopTimer() {
        timer?.invalidate()
        timer = nil
    }
    
    func formattedTime(_ timeInterval: TimeInterval) -> String {
        let hours = Int(timeInterval) / 3600
        let minutes = Int(timeInterval) / 60 % 60
        let seconds = Int(timeInterval) % 60
        
        if hours > 0 {
            return String(format: "%02d:%02d:%02d", hours, minutes, seconds)
        } else {
            return String(format: "%02d:%02d", minutes, seconds)
        }
    }
}
