import Foundation

enum StorageError: Error {
    case saveFailed
    case loadFailed
    case notFound
    case invalidData
}

class StorageService {
    private let fileManager = FileManager.default
    private let recordingsKey = "recordings"
    
    // MARK: - Directory Paths
    
    private var documentsDirectory: URL {
        fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]
    }
    
    private var transcriptsDirectory: URL {
        let path = documentsDirectory.appendingPathComponent("Transcripts")
        if !fileManager.fileExists(atPath: path.path) {
            try? fileManager.createDirectory(at: path, withIntermediateDirectories: true)
        }
        return path
    }
    
    private var summariesDirectory: URL {
        let path = documentsDirectory.appendingPathComponent("Summaries")
        if !fileManager.fileExists(atPath: path.path) {
            try? fileManager.createDirectory(at: path, withIntermediateDirectories: true)
        }
        return path
    }
    
    // MARK: - Recordings Management
    
    func saveRecordings(_ recordings: [Recording], completion: @escaping (Result<Void, Error>) -> Void) {
        do {
            let data = try JSONEncoder().encode(recordings)
            UserDefaults.standard.set(data, forKey: recordingsKey)
            completion(.success(()))
        } catch {
            completion(.failure(StorageError.saveFailed))
        }
    }
    
    func loadRecordings(completion: @escaping (Result<[Recording], Error>) -> Void) {
        if let data = UserDefaults.standard.data(forKey: recordingsKey) {
            do {
                let recordings = try JSONDecoder().decode([Recording].self, from: data)
                completion(.success(recordings))
            } catch {
                completion(.failure(StorageError.invalidData))
            }
        } else {
            completion(.success([]))
        }
    }
    
    func updateRecording(_ recording: Recording, completion: @escaping (Result<Void, Error>) -> Void) {
        loadRecordings { [weak self] result in
            guard let self = self else { return }
            
            switch result {
            case .success(var recordings):
                if let index = recordings.firstIndex(where: { $0.id == recording.id }) {
                    recordings[index] = recording
                    self.saveRecordings(recordings, completion: completion)
                } else {
                    completion(.failure(StorageError.notFound))
                }
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
    
    // MARK: - Transcript Management
    
    func saveTranscript(_ transcript: Transcript, completion: @escaping (Result<Transcript, Error>) -> Void) {
        do {
            let filePath = transcriptsDirectory.appendingPathComponent("\(transcript.id).json")
            let data = try JSONEncoder().encode(transcript)
            try data.write(to: filePath)
            completion(.success(transcript))
        } catch {
            completion(.failure(StorageError.saveFailed))
        }
    }
    
    func loadTranscript(for recordingID: UUID, completion: @escaping (Result<Transcript, Error>) -> Void) {
        loadRecordings { [weak self] result in
            guard let self = self else { return }
            
            switch result {
            case .success(let recordings):
                if let recording = recordings.first(where: { $0.id == recordingID }),
                   let transcriptID = recording.transcriptID {
                    self.loadTranscriptByID(transcriptID, completion: completion)
                } else {
                    completion(.failure(StorageError.notFound))
                }
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
    
    private func loadTranscriptByID(_ id: UUID, completion: @escaping (Result<Transcript, Error>) -> Void) {
        let filePath = transcriptsDirectory.appendingPathComponent("\(id).json")
        
        if fileManager.fileExists(atPath: filePath.path) {
            do {
                let data = try Data(contentsOf: filePath)
                let transcript = try JSONDecoder().decode(Transcript.self, from: data)
                completion(.success(transcript))
            } catch {
                completion(.failure(StorageError.invalidData))
            }
        } else {
            completion(.failure(StorageError.notFound))
        }
    }
    
    // MARK: - Summary Management
    
    func saveSummary(_ summary: Summary, completion: @escaping (Result<Summary, Error>) -> Void) {
        do {
            let filePath = summariesDirectory.appendingPathComponent("\(summary.id).json")
            let data = try JSONEncoder().encode(summary)
            try data.write(to: filePath)
            completion(.success(summary))
        } catch {
            completion(.failure(StorageError.saveFailed))
        }
    }
    
    func loadSummary(for recordingID: UUID, completion: @escaping (Result<Summary, Error>) -> Void) {
        loadRecordings { [weak self] result in
            guard let self = self else { return }
            
            switch result {
            case .success(let recordings):
                if let recording = recordings.first(where: { $0.id == recordingID }),
                   let summaryID = recording.summaryID {
                    self.loadSummaryByID(summaryID, completion: completion)
                } else {
                    completion(.failure(StorageError.notFound))
                }
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
    
    private func loadSummaryByID(_ id: UUID, completion: @escaping (Result<Summary, Error>) -> Void) {
        let filePath = summariesDirectory.appendingPathComponent("\(id).json")
        
        if fileManager.fileExists(atPath: filePath.path) {
            do {
                let data = try Data(contentsOf: filePath)
                let summary = try JSONDecoder().decode(Summary.self, from: data)
                completion(.success(summary))
            } catch {
                completion(.failure(StorageError.invalidData))
            }
        } else {
            completion(.failure(StorageError.notFound))
        }
    }
}
