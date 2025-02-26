import SwiftUI

struct RecordingDetailView: View {
    let recording: Recording
    @EnvironmentObject var recordingsViewModel: RecordingsViewModel
    @StateObject private var transcriptionViewModel = TranscriptionViewModel()
    @StateObject private var summaryViewModel = SummaryViewModel()
    @EnvironmentObject private var settingsViewModel: SettingsViewModel
    @State private var selectedTab = 0
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        NavigationView {
            VStack {
                recordingInfoHeader
                
                Picker("View", selection: $selectedTab) {
                    Text("Recording").tag(0)
                    Text("Transcript").tag(1)
                    Text("Summary").tag(2)
                }
                .pickerStyle(SegmentedPickerStyle())
                .padding(.horizontal)
                
                TabView(selection: $selectedTab) {
                    recordingView.tag(0)
                    transcriptView.tag(1)
                    summaryView.tag(2)
                }
                .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
            }
            .navigationTitle(recording.title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        presentationMode.wrappedValue.dismiss()
                    }
                }
            }
            .onAppear {
                if let transcriptID = recording.transcriptID {
                    transcriptionViewModel.loadTranscript(for: recording.id)
                }
                
                if let summaryID = recording.summaryID {
                    summaryViewModel.loadSummary(for: recording.id)
                }
            }
        }
    }
    
    private var recordingInfoHeader: some View {
        VStack(spacing: 4) {
            Text(formattedDate(recording.date))
                .font(.caption)
                .foregroundColor(.secondary)
            
            Text(recordingsViewModel.formattedTime(recording.duration))
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding(.vertical, 8)
    }
    
    private var recordingView: some View {
        VStack {
            // Simple audio player UI
            HStack(spacing: 20) {
                Button(action: {}) {
                    Image(systemName: "play.circle.fill")
                        .font(.system(size: 50))
                        .foregroundColor(.blue)
                }
                
                VStack(alignment: .leading) {
                    Text(recording.title)
                        .font(.headline)
                    
                    Text(recordingsViewModel.formattedTime(recording.duration))
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
            }
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(10)
            .padding()
            
            Spacer()
            
            if recording.transcriptID == nil {
                Button(action: {
                    transcriptionViewModel.transcribeRecording(recording)
                }) {
                    HStack {
                        Image(systemName: "text.bubble")
                        Text("Transcribe Recording")
                    }
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(10)
                }
                .padding()
            }
        }
    }
    
    private var transcriptView: some View {
        VStack {
            if transcriptionViewModel.isTranscribing {
                VStack {
                    ProgressView(value: transcriptionViewModel.progress)
                        .padding()
                    
                    Text("Transcribing... \(Int(transcriptionViewModel.progress * 100))%")
                        .foregroundColor(.secondary)
                }
                .padding()
            } else if let transcript = transcriptionViewModel.transcript {
                if transcript.isProcessing {
                    ProgressView("Preparing transcript...")
                        .padding()
                } else if !transcript.text.isEmpty {
                    ScrollView {
                        VStack(alignment: .leading, spacing: 16) {
                            Text(transcript.text)
                                .padding()
                        }
                    }
                    
                    if recording.summaryID == nil {
                        Button(action: {
                            summaryViewModel.generateSummary(
                                for: transcript,
                                recording: recording,
                                selectedProvider: settingsViewModel.selectedLLMProvider,
                                selectedModel: settingsViewModel.selectedModel
                            )
                        }) {
                            HStack {
                                Image(systemName: "doc.text")
                                Text("Generate Summary")
                            }
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(10)
                        }
                        .padding()
                    }
                } else {
                    Text("Transcript is empty")
                        .foregroundColor(.secondary)
                        .padding()
                }
            } else if let error = transcriptionViewModel.error {
                VStack {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.largeTitle)
                        .foregroundColor(.orange)
                        .padding()
                    
                    Text("Transcription Error")
                        .font(.headline)
                    
                    Text(error)
                        .font(.body)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding()
                    
                    Button(action: {
                        transcriptionViewModel.transcribeRecording(recording)
                    }) {
                        Text("Try Again")
                            .padding()
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(10)
                    }
                }
                .padding()
            } else {
                VStack {
                    Text("No Transcript Available")
                        .font(.headline)
                        .padding()
                    
                    Button(action: {
                        transcriptionViewModel.transcribeRecording(recording)
                    }) {
                        HStack {
                            Image(systemName: "text.bubble")
                            Text("Transcribe Recording")
                        }
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                    }
                    .padding(.horizontal)
                }
            }
        }
    }
    
    private var summaryView: some View {
        VStack {
            if summaryViewModel.isGenerating {
                VStack {
                    ProgressView(value: summaryViewModel.progress)
                        .padding()
                    
                    Text("Generating summary... \(Int(summaryViewModel.progress * 100))%")
                        .foregroundColor(.secondary)
                }
                .padding()
            } else if let summary = summaryViewModel.summary {
                if summary.isProcessing {
                    ProgressView("Preparing summary...")
                        .padding()
                } else if !summary.text.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("Generated using:")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            
                            Text(summary.llmType)
                                .font(.caption)
                                .fontWeight(.semibold)
                                .foregroundColor(.blue)
                        }
                        .padding(.horizontal)
                        
                        ScrollView {
                            Text(summary.text)
                                .padding()
                        }
                        
                        // Summary sharing button
                        Button(action: {
                            shareText(summary.text)
                        }) {
                            HStack {
                                Image(systemName: "square.and.arrow.up")
                                Text("Share Summary")
                            }
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(10)
                        }
                        .padding()
                    }
                } else {
                    Text("Summary is empty")
                        .foregroundColor(.secondary)
                        .padding()
                }
            } else if let error = summaryViewModel.error {
                VStack {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.largeTitle)
                        .foregroundColor(.orange)
                        .padding()
                    
                    Text("Summary Generation Error")
                        .font(.headline)
                    
                    Text(error)
                        .font(.body)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding()
                    
                    if let transcript = transcriptionViewModel.transcript, !transcript.isProcessing {
                        Button(action: {
                            summaryViewModel.generateSummary(
                                for: transcript,
                                recording: recording,
                                selectedProvider: settingsViewModel.selectedLLMProvider,
                                selectedModel: settingsViewModel.selectedModel
                            )
                        }) {
                            Text("Try Again")
                                .padding()
                                .background(Color.blue)
                                .foregroundColor(.white)
                                .cornerRadius(10)
                        }
                    }
                }
                .padding()
            } else {
                VStack {
                    if let transcript = transcriptionViewModel.transcript, !transcript.isProcessing, !transcript.text.isEmpty {
                        Text("No Summary Available")
                            .font(.headline)
                            .padding()
                        
                        Button(action: {
                            summaryViewModel.generateSummary(
                                for: transcript,
                                recording: recording,
                                selectedProvider: settingsViewModel.selectedLLMProvider,
                                selectedModel: settingsViewModel.selectedModel
                            )
                        }) {
                            HStack {
                                Image(systemName: "doc.text")
                                Text("Generate Summary")
                            }
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(10)
                        }
                        .padding(.horizontal)
                    } else {
                        Text("Transcript needed first")
                            .font(.headline)
                            .foregroundColor(.secondary)
                            .padding()
                        
                        // Step indicator
                        VStack(alignment: .leading, spacing: 16) {
                            HStack {
                                Circle()
                                    .fill(recording.transcriptID != nil ? Color.green : Color.gray)
                                    .frame(width: 24, height: 24)
                                    .overlay(Text("1").foregroundColor(.white).font(.caption))
                                
                                Text("Transcribe the recording")
                                    .foregroundColor(recording.transcriptID != nil ? .primary : .secondary)
                            }
                            
                            HStack {
                                Circle()
                                    .fill(Color.gray)
                                    .frame(width: 24, height: 24)
                                    .overlay(Text("2").foregroundColor(.white).font(.caption))
                                
                                Text("Generate summary from transcript")
                                    .foregroundColor(.secondary)
                            }
                        }
                        .padding()
                    }
                }
            }
        }
    }
    
    private func formattedDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
    
    private func shareText(_ text: String) {
        let av = UIActivityViewController(activityItems: [text], applicationActivities: nil)
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let rootViewController = windowScene.windows.first?.rootViewController {
            rootViewController.present(av, animated: true)
        }
    }
}
