import SwiftUI

struct ContentView: View {
    @EnvironmentObject var recordingsViewModel: RecordingsViewModel
    
    var body: some View {
        TabView {
            RecordingsView()
                .tabItem {
                    Label("Nagrania", systemImage: "waveform")
                }
            
            SettingsView()
                .tabItem {
                    Label("Ustawienia", systemImage: "gear")
                }
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
            .environmentObject(RecordingsViewModel())
            .environmentObject(SettingsViewModel())
    }
}
