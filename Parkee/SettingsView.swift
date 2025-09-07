import SwiftUI

struct SettingsView: View {
    @ObservedObject var viewModel: ParkingViewModel

    var body: some View {
        Form {
            Section {
                Toggle(isOn: $viewModel.useDarkMap) {
                    Text("Use Dark Mode")
                }
                Picker("Default Style", selection: $viewModel.preferredMapStyle) {
                    Text("Standard").tag("standard")
                    Text("Satellite").tag("imagery")
                    Text("Hybrid").tag("hybrid")
                }
                Toggle("Show Compass", isOn: $viewModel.showCompass)
                Toggle("Show Scale", isOn: $viewModel.showScale)
                Toggle("Follow on Launch", isOn: $viewModel.followOnLaunch)
            } header: { Text("Map") }
            
            Section {
                Toggle("Prefer Address Over Coordinates", isOn: $viewModel.showAddress)
                Picker("Units", selection: $viewModel.units) {
                    Text("Miles").tag("miles")
                    Text("Kilometers").tag("km")
                }
            } header: { Text("Display") }
            
            Section {
                Picker("Open in Maps Mode", selection: $viewModel.mapsDirectionsMode) {
                    Text("Driving").tag("driving")
                    Text("Walking").tag("walking")
                }
            } header: { Text("Directions") }
            
            Section {
                Toggle("Haptics on Save/Clear", isOn: $viewModel.isHapticsEnabled)
                Toggle("Confirm Before Clear", isOn: $viewModel.confirmClearLocation)
                Toggle("Auto-Start Timer After Save", isOn: $viewModel.autoStartTimer)
            } header: { Text("Parking") }
            
            Section {
                Text("Version 1.0")
            } header: { Text("About") }
        }
        .navigationTitle("Settings")
        .navigationBarTitleDisplayMode(.inline)
    }
}


