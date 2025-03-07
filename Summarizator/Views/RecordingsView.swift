import SwiftUI
import UniformTypeIdentifiers

struct RecordingsView: View {
    @EnvironmentObject var recordingsViewModel: RecordingsViewModel
    @State private var isRecording = false
    @State private var showRecordingSheet = false
    @State private var showImportSheet = false
    @State private var showFilePicker = false
    @State private var importTitle = ""
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
                    Menu {
                        Button(action: {
                            showRecordingSheet = true
                        }) {
                            Label("Nowe nagranie", systemImage: "mic")
                        }
                        
                        Button(action: {
                            // Najpierw pokaż picker plików bezpośrednio
                            showFilePicker = true
                        }) {
                            Label("Importuj plik", systemImage: "square.and.arrow.down")
                        }
                    } label: {
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
            .alert(item: Binding<AlertItem?>(
                get: { 
                    recordingsViewModel.importError != nil ? AlertItem(message: recordingsViewModel.importError!) : nil 
                },
                set: { _ in recordingsViewModel.importError = nil }
            )) { alert in
                Alert(title: Text("Błąd importu"), message: Text(alert.message), dismissButton: .default(Text("OK")))
            }
        }
        // Przeniesiony fileImporter poza NavigationView
        .fileImporter(
            isPresented: $showFilePicker,
            allowedContentTypes: [.audio, .mp3, .wav, .m4a],
            allowsMultipleSelection: false
        ) { result in
            // Użyj promptu przed importem
            switch result {
            case .success(let urls):
                guard let url = urls.first else { return }
                showPromptForImport(url: url)
            case .failure(let error):
                print("File selection error: \(error)")
                recordingsViewModel.importError = "Błąd wyboru pliku: \(error.localizedDescription)"
            }
        }
        .sheet(isPresented: $showImportSheet) {
            ImportSheetView(
                isPresented: $showImportSheet,
                importTitle: $importTitle,
                onImport: { title in
                    // Tutaj pobieramy zachowany URL i importujemy
                    if let url = UserDefaults.standard.url(forKey: "tempImportURL") {
                        importFile(url: url, title: title)
                    }
                }
            )
        }
    }
    
    // Funkcja pokazująca prompt po wybraniu pliku
    private func showPromptForImport(url: URL) {
        // Zapisz URL tymczasowo
        UserDefaults.standard.set(url, forKey: "tempImportURL")
        importTitle = url.deletingPathExtension().lastPathComponent
        showImportSheet = true
    }
    
    // Funkcja importująca plik
    private func importFile(url: URL, title: String) {
        // Uzyskaj dostęp do pliku
        if url.startAccessingSecurityScopedResource() {
            // Zaimportuj plik
            recordingsViewModel.importAudio(from: url, withTitle: title.isEmpty ? nil : title)
            
            // Zakończ dostęp do pliku
            url.stopAccessingSecurityScopedResource()
        }
        
        // Wyczyść tymczasowe dane
        UserDefaults.standard.removeObject(forKey: "tempImportURL")
    }
    
    private var emptyStateView: some View {
        VStack(spacing: 20) {
            Image(systemName: "waveform")
                .font(.system(size: 72))
                .foregroundColor(.gray)
            
            Text("Brak nagrań")
                .font(.title2)
                .fontWeight(.bold)
            
            Text("Dotknij przycisku + aby rozpocząć nagrywanie wykładu lub zaimportować nagranie")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            
            HStack(spacing: 16) {
                Button(action: {
                    showRecordingSheet = true
                }) {
                    VStack {
                        Image(systemName: "mic.circle.fill")
                            .font(.system(size: 36))
                        Text("Nagraj")
                            .font(.caption)
                    }
                    .padding()
                    .frame(minWidth: 100)
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(10)
                }
                
                Button(action: {
                    showFilePicker = true
                }) {
                    VStack {
                        Image(systemName: "square.and.arrow.down.fill")
                            .font(.system(size: 36))
                        Text("Importuj")
                            .font(.caption)
                    }
                    .padding()
                    .frame(minWidth: 100)
                    .background(Color.green)
                    .foregroundColor(.white)
                    .cornerRadius(10)
                }
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
    @FocusState private var isTitleFocused: Bool
    
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
                
                ToolbarItem(placement: .keyboard) {
                    Button("Gotowe") {
                        isTitleFocused = false
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
                .focused($isTitleFocused)
                .submitLabel(.done)
            
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

struct ImportSheetView: View {
    @Binding var isPresented: Bool
    @Binding var importTitle: String
    @FocusState private var isTitleFocused: Bool
    var onImport: (String) -> Void
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                Text("Zaimportuj plik audio")
                    .font(.headline)
                    .padding(.top)
                
                Image(systemName: "square.and.arrow.down")
                    .font(.system(size: 64))
                    .foregroundColor(.blue)
                    .padding()
                
                TextField("Tytuł nagrania", text: $importTitle)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .padding(.horizontal)
                    .focused($isTitleFocused)
                    .submitLabel(.done)
                
                Text("Jeśli nie podasz tytułu, zostanie użyta nazwa pliku.")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
                
                Button(action: {
                    onImport(importTitle)
                    isPresented = false
                }) {
                    HStack {
                        Image(systemName: "arrow.right.doc.on.clipboard")
                        Text("Importuj plik")
                    }
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(10)
                }
                .padding(.top)
                
                Text("Obsługiwane formaty: MP3, M4A, WAV")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Spacer()
            }
            .padding()
            .navigationTitle("Import pliku")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Anuluj") {
                        isPresented = false
                    }
                }
                
                ToolbarItem(placement: .keyboard) {
                    Button("Gotowe") {
                        isTitleFocused = false
                    }
                }
            }
            .onTapGesture {
                // Ukryj klawiaturę po tapnięciu poza polem tekstowym
                isTitleFocused = false
            }
        }
    }
}

// Rozszerzenie UTType dla iOS 15
extension UTType {
    static let audio = UTType(tag: "public.audio", tagClass: .filenameExtension, conformingTo: nil) ?? .data
    static let mp3 = UTType(tag: "mp3", tagClass: .filenameExtension, conformingTo: .audio) ?? .audio
    static let wav = UTType(tag: "wav", tagClass: .filenameExtension, conformingTo: .audio) ?? .audio
    static let m4a = UTType(tag: "m4a", tagClass: .filenameExtension, conformingTo: .audio) ?? .audio
}

// Pomocniczy typ do wyświetlania alertu błędu
struct AlertItem: Identifiable {
    var id = UUID()
    var message: String
}

struct RecordingsView_Previews: PreviewProvider {
    static var previews: some View {
        RecordingsView()
            .environmentObject(RecordingsViewModel())
    }
}
