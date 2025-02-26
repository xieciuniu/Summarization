import Foundation

struct Summary: Identifiable, Codable {
    var id: UUID
    var transcriptID: UUID
    var recordingID: UUID
    var text: String
    var createdAt: Date
    var isProcessing: Bool
    var llmType: String
    
    init(id: UUID = UUID(), transcriptID: UUID, recordingID: UUID, text: String = "", createdAt: Date = Date(), isProcessing: Bool = false, llmType: String = "Default") {
        self.id = id
        self.transcriptID = transcriptID
        self.recordingID = recordingID
        self.text = text
        self.createdAt = createdAt
        self.isProcessing = isProcessing
        self.llmType = llmType
    }
}
