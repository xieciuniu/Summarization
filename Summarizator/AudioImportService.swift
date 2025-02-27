import Foundation
import AVFoundation

class AudioImportService {
    enum AudioImportError: Error {
        case invalidURL
        case copyFailed
        case durationRetrievalFailed
        case unsupportedFormat
    }
    
    // Importuj plik audio z zewnętrznego URL do katalogu dokumentów aplikacji
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
