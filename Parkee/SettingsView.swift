import SwiftUI

struct SettingsView: View {
    @ObservedObject var viewModel: ParkingViewModel
    @Environment(\.colorScheme) var colorScheme
    
    var backgroundColor: Color {
        colorScheme == .dark ? Color.raisinBlack : Color(UIColor.systemGray6)
    }
    
    var cardBackgroundColor: Color {
        colorScheme == .dark ? Color.darkCard : Color.white
    }
    
    var textColor: Color {
        colorScheme == .dark ? Color.white : Color.black
    }
    
    var secondaryTextColor: Color {
        colorScheme == .dark ? Color.white.opacity(0.7) : Color.black.opacity(0.6)
    }

    var body: some View {
        ZStack {
            // Clean solid background
            backgroundColor
                .ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 24) {
                    // Map Section
                    SettingsSection(title: "Map", colorScheme: colorScheme) {
                        VStack(spacing: 0) {
                            SettingsRow(showDivider: true, colorScheme: colorScheme) {
                                Toggle(isOn: $viewModel.useDarkMap) {
                                    Text("Use Dark Mode")
                                        .foregroundColor(textColor)
                                        .font(.system(size: 17))
                                }
                                .tint(Color.yellowGreen)
                            }
                            
                            SettingsRow(showDivider: true, colorScheme: colorScheme) {
                                HStack {
                                    Text("Default Map Style")
                                        .foregroundColor(textColor)
                                        .font(.system(size: 17))
                                    
                                    Spacer()
                                    
                                    Menu {
                                        Button("Standard") {
                                            viewModel.preferredMapStyle = "standard"
                                        }
                                        Button("Satellite") {
                                            viewModel.preferredMapStyle = "imagery"
                                        }
                                        Button("Hybrid") {
                                            viewModel.preferredMapStyle = "hybrid"
                                        }
                                    } label: {
                                        HStack(spacing: 4) {
                                            Text(viewModel.preferredMapStyle == "standard" ? "Standard" : 
                                                 viewModel.preferredMapStyle == "imagery" ? "Satellite" : "Hybrid")
                                                .foregroundColor(secondaryTextColor)
                                                .font(.system(size: 17))
                                            Image(systemName: "chevron.up.chevron.down")
                                                .foregroundColor(secondaryTextColor)
                                                .font(.system(size: 12, weight: .medium))
                                        }
                                    }
                                }
                            }
                            
                            SettingsRow(showDivider: true, colorScheme: colorScheme) {
                                Toggle("Show Compass", isOn: $viewModel.showCompass)
                                    .foregroundColor(textColor)
                                    .font(.system(size: 17))
                                    .tint(Color.yellowGreen)
                            }
                            
                            SettingsRow(showDivider: true, colorScheme: colorScheme) {
                                Toggle("Show Scale", isOn: $viewModel.showScale)
                                    .foregroundColor(textColor)
                                    .font(.system(size: 17))
                                    .tint(Color.yellowGreen)
                            }
                            
                            SettingsRow(showDivider: false, colorScheme: colorScheme) {
                                Toggle("Follow on Launch", isOn: $viewModel.followOnLaunch)
                                    .foregroundColor(textColor)
                                    .font(.system(size: 17))
                                    .tint(Color.yellowGreen)
                            }
                        }
                    }
                    
                    // Display Section
                    SettingsSection(title: "Display", colorScheme: colorScheme) {
                        VStack(spacing: 0) {
                            SettingsRow(showDivider: true, colorScheme: colorScheme) {
                                Toggle("Prefer Address Over Coordinates", isOn: $viewModel.showAddress)
                                    .foregroundColor(textColor)
                                    .font(.system(size: 17))
                                    .tint(Color.yellowGreen)
                            }
                            
                            SettingsRow(showDivider: false, colorScheme: colorScheme) {
                                HStack {
                                    Text("Units")
                                        .foregroundColor(textColor)
                                        .font(.system(size: 17))
                                    
                                    Spacer()
                                    
                                    Menu {
                                        Button("Miles") {
                                            viewModel.units = "miles"
                                        }
                                        Button("Kilometers") {
                                            viewModel.units = "km"
                                        }
                                    } label: {
                                        HStack(spacing: 4) {
                                            Text(viewModel.units == "miles" ? "Miles" : "Kilometers")
                                                .foregroundColor(secondaryTextColor)
                                                .font(.system(size: 17))
                                            Image(systemName: "chevron.up.chevron.down")
                                                .foregroundColor(secondaryTextColor)
                                                .font(.system(size: 12, weight: .medium))
                                        }
                                    }
                                }
                            }
                        }
                    }
                    
                    // Directions Section
                    SettingsSection(title: "Directions", colorScheme: colorScheme) {
                        VStack(spacing: 0) {
                            SettingsRow(showDivider: false, colorScheme: colorScheme) {
                                HStack {
                                    Text("Open in Maps Mode")
                                        .foregroundColor(textColor)
                                        .font(.system(size: 17))
                                    
                                    Spacer()
                                    
                                    Menu {
                                        Button("Driving") {
                                            viewModel.mapsDirectionsMode = "driving"
                                        }
                                        Button("Walking") {
                                            viewModel.mapsDirectionsMode = "walking"
                                        }
                                    } label: {
                                        HStack(spacing: 4) {
                                            Text(viewModel.mapsDirectionsMode == "driving" ? "Driving" : "Walking")
                                                .foregroundColor(secondaryTextColor)
                                                .font(.system(size: 17))
                                            Image(systemName: "chevron.up.chevron.down")
                                                .foregroundColor(secondaryTextColor)
                                                .font(.system(size: 12, weight: .medium))
                                        }
                                    }
                                }
                            }
                        }
                    }
                    
                    // Parking Section
                    SettingsSection(title: "Parking", colorScheme: colorScheme) {
                        VStack(spacing: 0) {
                            SettingsRow(showDivider: true, colorScheme: colorScheme) {
                                Toggle("Haptics on Save/Clear", isOn: $viewModel.isHapticsEnabled)
                                    .foregroundColor(textColor)
                                    .font(.system(size: 17))
                                    .tint(Color.yellowGreen)
                            }
                            
                            SettingsRow(showDivider: true, colorScheme: colorScheme) {
                                Toggle("Confirm Before Clear", isOn: $viewModel.confirmClearLocation)
                                    .foregroundColor(textColor)
                                    .font(.system(size: 17))
                                    .tint(Color.yellowGreen)
                            }
                            
                            SettingsRow(showDivider: false, colorScheme: colorScheme) {
                                Toggle("Auto-Start Timer After Save", isOn: $viewModel.autoStartTimer)
                                    .foregroundColor(textColor)
                                    .font(.system(size: 17))
                                    .tint(Color.yellowGreen)
                            }
                        }
                    }
                    
                    // Developer Section (Temporary)
                    SettingsSection(title: "Developer", colorScheme: colorScheme) {
                        SettingsRow(showDivider: false, colorScheme: colorScheme) {
                            Button(action: {
                                viewModel.hasSeenOnboarding = false
                            }) {
                                HStack {
                                    Text("Reset Onboarding")
                                        .foregroundColor(Color.yellowGreen)
                                        .font(.system(size: 17, weight: .medium))
                                    Spacer()
                                    Image(systemName: "arrow.clockwise")
                                        .foregroundColor(Color.yellowGreen)
                                        .font(.system(size: 16, weight: .medium))
                                }
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    
                    // About Section
                    SettingsSection(title: "About", colorScheme: colorScheme) {
                        SettingsRow(showDivider: false, colorScheme: colorScheme) {
                            HStack {
                                Text("Version")
                                    .foregroundColor(textColor)
                                    .font(.system(size: 17))
                                Spacer()
                                Text("1.0")
                                    .foregroundColor(secondaryTextColor)
                                    .font(.system(size: 17))
                            }
                        }
                    }
                }
                .padding(.horizontal, 16)
                .padding(.top, 20)
                .padding(.bottom, 20)
            }
        }
        .navigationTitle("")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(backgroundColor, for: .navigationBar)
        .toolbarColorScheme(colorScheme == .dark ? .dark : .light, for: .navigationBar)
    }
}

// MARK: - Supporting Views
struct SettingsSection<Content: View>: View {
    let title: String
    let content: Content
    let colorScheme: ColorScheme
    
    init(title: String, colorScheme: ColorScheme, @ViewBuilder content: () -> Content) {
        self.title = title
        self.colorScheme = colorScheme
        self.content = content()
    }
    
    var textColor: Color {
        colorScheme == .dark ? Color.white : Color.black
    }
    
    var cardBackgroundColor: Color {
        colorScheme == .dark ? Color.darkCard : Color.white
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.system(size: 22, weight: .semibold))
                .foregroundColor(textColor)
                .padding(.horizontal, 4)
            
            VStack(spacing: 0) {
                content
            }
            .background(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(cardBackgroundColor)
                    .shadow(color: Color.black.opacity(colorScheme == .dark ? 0.3 : 0.08), 
                            radius: colorScheme == .dark ? 12 : 6, 
                            x: 0, 
                            y: colorScheme == .dark ? 4 : 2)
            )
        }
    }
}

struct SettingsRow<Content: View>: View {
    let content: Content
    let showDivider: Bool
    let colorScheme: ColorScheme
    
    init(showDivider: Bool, colorScheme: ColorScheme, @ViewBuilder content: () -> Content) {
        self.showDivider = showDivider
        self.colorScheme = colorScheme
        self.content = content()
    }
    
    var dividerColor: Color {
        colorScheme == .dark ? Color.white.opacity(0.1) : Color.black.opacity(0.08)
    }
    
    var body: some View {
        VStack(spacing: 0) {
            content
                .padding(.horizontal, 20)
                .padding(.vertical, 16)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            if showDivider {
                Divider()
                    .background(dividerColor)
                    .padding(.leading, 20)
            }
        }
    }
}

