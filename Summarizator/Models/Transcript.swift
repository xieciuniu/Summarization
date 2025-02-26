import Foundation

struct Transcript: Identifiable, Codable {
    var id: UUID
    var recordingID: UUID
    var text: String
    var createdAt: Date
    var isProcessing: Bool
    
    init(id: UUID = UUID(), recordingID: UUID, text: String = "", createdAt: Date = Date(), isProcessing: Bool = false) {
        self.id = id
        self.recordingID = recordingID
        self.text = text
        self.createdAt = createdAt
        self.isProcessing = isProcessing
    }
}
