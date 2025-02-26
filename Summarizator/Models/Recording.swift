import Foundation

struct Recording: Identifiable, Codable {
    var id: UUID
    var title: String
    var date: Date
    var duration: TimeInterval
    var fileURL: URL
    var transcriptID: UUID?
    var summaryID: UUID?
    
    init(id: UUID = UUID(), title: String, date: Date = Date(), duration: TimeInterval = 0, fileURL: URL, transcriptID: UUID? = nil, summaryID: UUID? = nil) {
        self.id = id
        self.title = title
        self.date = date
        self.duration = duration
        self.fileURL = fileURL
        self.transcriptID = transcriptID
        self.summaryID = summaryID
    }
}

enum RecordingState {
    case idle
    case recording
    case paused
    case finished
}
