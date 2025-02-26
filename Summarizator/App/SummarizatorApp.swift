import SwiftUI

@main
struct SummarizatorApp: App {
    @StateObject private var recordingsViewModel = RecordingsViewModel()
    @StateObject private var settingsViewModel = SettingsViewModel()
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(recordingsViewModel)
                .environmentObject(settingsViewModel)
        }
    }
}
