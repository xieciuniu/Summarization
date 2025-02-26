import SwiftUI

struct RecordingsView: View {
    @EnvironmentObject var recordingsViewModel: RecordingsViewModel
    @State private var isRecording = false
    @State private var showRecordingSheet = false
    @State private var recordingTitle = ""
    @State private var selectedRecording: Recording? = nil
    
    var body: some View {
        NavigationView {
            Group {
                if recordingsViewModel.isLoading {
                    ProgressView("Ładowanie nagrań...")
                } else if recordingsViewModel.recordings.isEmpty {
                    emptyStateView
                } else {
                    recordingsList
                }
            }
            .navigationTitle("Nagrania")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        showRecordingSheet = true
                    }) {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showRecordingSheet) {
                RecordingSheetView(isPresented: $showRecordingSheet)
            }
            .sheet(item: $selectedRecording) { recording in
                RecordingDetailView(recording: recording)
            }
        }
    }
    
    private var emptyStateView: some View {
        VStack(spacing: 20) {
            Image(systemName: "waveform")
                .font(.system(size: 72))
                .foregroundColor(.gray)
            
            Text("Brak nagrań")
                .font(.title2)
                .fontWeight(.bold)
            
            Text("Dotknij przycisku + aby rozpocząć nagrywanie wykładu")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            
            Button(action: {
                showRecordingSheet = true
            }) {
                Text("Rozpocznij nagrywanie")
                    .fontWeight(.semibold)
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(10)
            }
            .padding(.top, 10)
        }
    }
    
    private var recordingsList: some View {
        List {
            ForEach(recordingsViewModel.recordings) { recording in
                RecordingRow(recording: recording)
                    .onTapGesture {
                        selectedRecording = recording
                    }
            }
            .onDelete { indexSet in
                for index in indexSet {
                    recordingsViewModel.deleteRecording(recordingsViewModel.recordings[index])
                }
            }
        }
        .listStyle(InsetGroupedListStyle())
        .refreshable {
            recordingsViewModel.loadRecordings()
        }
    }
}

struct RecordingRow: View {
    let recording: Recording
    @EnvironmentObject var recordingsViewModel: RecordingsViewModel
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(recording.title)
                    .font(.headline)
                
                Text(formattedDate(recording.date))
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                HStack {
                    Text(recordingsViewModel.formattedTime(recording.duration))
                        .font(.caption2)
                        .foregroundColor(.secondary)
                    
                    if recording.transcriptID != nil {
                        Label("Transkrypcja", systemImage: "text.bubble")
                            .font(.caption2)
                            .foregroundColor(.green)
                    }
                    
                    if recording.summaryID != nil {
                        Label("Podsumowanie", systemImage: "doc.text")
                            .font(.caption2)
                            .foregroundColor(.blue)
                    }
                }
            }
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .foregroundColor(.secondary)
                .font(.caption)
        }
        .padding(.vertical, 4)
    }
    
    private func formattedDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

struct RecordingSheetView: View {
    @EnvironmentObject var recordingsViewModel: RecordingsViewModel
    @Binding var isPresented: Bool
    @State private var recordingTitle = ""
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                if recordingsViewModel.recordingState == .idle {
                    preRecordingView
                } else {
                    recordingInProgressView
                }
            }
            .padding()
            .navigationTitle("Nowe nagranie")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    if recordingsViewModel.recordingState == .idle {
                        Button("Anuluj") {
                            isPresented = false
                        }
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    if recordingsViewModel.recordingState == .finished {
                        Button("Gotowe") {
                            isPresented = false
                        }
                    }
                }
            }
        }
    }
    
    private var preRecordingView: some View {
        VStack(spacing: 20) {
            TextField("Tytuł nagrania", text: $recordingTitle)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding(.horizontal)
            
            Button(action: {
                if !recordingTitle.isEmpty {
                    recordingsViewModel.startRecording(title: recordingTitle)
                }
            }) {
                HStack {
                    Image(systemName: "record.circle")
                    Text("Rozpocznij nagrywanie")
                }
                .padding()
                .frame(maxWidth: .infinity)
                .background(recordingTitle.isEmpty ? Color.gray : Color.red)
                .foregroundColor(.white)
                .cornerRadius(10)
            }
            .disabled(recordingTitle.isEmpty)
            
            Text("Twoje nagranie zostanie zapisane na urządzeniu")
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
        }
    }
    
    private var recordingInProgressView: some View {
        VStack(spacing: 30) {
            Text(recordingTitle)
                .font(.title2)
                .fontWeight(.bold)
            
            HStack(spacing: 20) {
                Circle()
                    .fill(Color.red)
                    .frame(width: 15, height: 15)
                    .opacity(recordingsViewModel.recordingState == .recording ? 1 : 0)
                
                Text(recordingsViewModel.formattedTime(recordingsViewModel.recordingTime))
                    .font(.system(size: 54, weight: .semibold, design: .monospaced))
            }
            
            HStack(spacing: 40) {
                if recordingsViewModel.recordingState == .recording {
                    Button(action: {
                        recordingsViewModel.pauseRecording()
                    }) {
                        VStack {
                            Image(systemName: "pause.circle.fill")
                                .font(.system(size: 64))
                                .foregroundColor(.yellow)
                            Text("Pauza")
                                .foregroundColor(.primary)
                        }
                    }
                } else if recordingsViewModel.recordingState == .paused {
                    Button(action: {
                        recordingsViewModel.resumeRecording()
                    }) {
                        VStack {
                            Image(systemName: "play.circle.fill")
                                .font(.system(size: 64))
                                .foregroundColor(.green)
                            Text("Wznów")
                                .foregroundColor(.primary)
                        }
                    }
                }
                
                Button(action: {
                    recordingsViewModel.stopRecording()
                }) {
                    VStack {
                        Image(systemName: "stop.circle.fill")
                            .font(.system(size: 64))
                            .foregroundColor(.red)
                        Text("Zatrzymaj")
                            .foregroundColor(.primary)
                    }
                }
            }
        }
    }
}

struct RecordingsView_Previews: PreviewProvider {
    static var previews: some View {
        RecordingsView()
            .environmentObject(RecordingsViewModel())
    }
}
