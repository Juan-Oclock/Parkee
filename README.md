# Parkee 🚗

A minimal iOS app for saving parking locations. Built with Swift and SwiftUI, Parkee follows a strict one-button-save, one-button-view philosophy with no accounts, onboarding, or unnecessary features.

## Overview

Parkee is designed to solve one simple problem: remembering where you parked your car. With just one tap, save your current location. With another tap, get directions back to your car. That's it.

### Key Principles
- **One-tap save**: Save current GPS location with a single button press
- **One-tap view**: Get directions to your parked car instantly
- **No accounts**: All data stored locally on your device
- **No onboarding**: Jump straight into the app experience
- **Minimal design**: Clean, modern interface using system fonts and SF Symbols

## Features

### Core Functionality
- 📍 **Save Parking Location**: One-tap GPS location saving
- 🗺️ **In-App Navigation**: Built-in MapKit directions with route display
- 🧭 **Directions to Car**: Get walking or driving directions via Apple Maps
- 📱 **Location Permissions**: Smart permission handling with clear messaging

### Enhanced Features
- 📝 **Parking Notes**: Add notes about your parking spot (floor, zone, etc.)
- ⏱️ **Parking Timer**: Track how long you've been parked
- 📷 **Parking Photo**: Take a photo to remember your spot
- 📋 **Parking History**: View previously saved parking locations
- ⚙️ **Customizable Settings**: Map style, units, haptics, and more

### Technical Features
- 🌍 **Reverse Geocoding**: Human-friendly addresses for saved locations
- 🗂️ **Local Storage**: All data persisted locally using UserDefaults
- 🎨 **Dark Mode Support**: Elegant appearance in both light and dark themes
- 📱 **iOS 17+ Compatible**: Built for modern iOS devices

## Screenshots

*Screenshots will be added here showing the main interface, parking details, settings, and navigation features*

## Requirements

- iOS 17.0+
- Xcode 15.0+
- Swift 5.9+
- Location Services enabled

## Installation

### Clone the Repository

```bash
git clone https://github.com/Juan-Oclock/Parkee.git
cd Parkee
```

### Open in Xcode

```bash
open Parkee.xcodeproj
```

### Build and Run

1. Select your target device or simulator
2. Press `Cmd + R` to build and run
3. Allow location permissions when prompted

### Command Line Build (Optional)

```bash
# Build for simulator
xcodebuild -project Parkee.xcodeproj -scheme Parkee -destination 'platform=iOS Simulator,name=iPhone 15' build

# Run tests
xcodebuild test -project Parkee.xcodeproj -scheme Parkee -destination 'platform=iOS Simulator,name=iPhone 15'
```

## Usage

### Basic Workflow

1. **Park Your Car**: Tap "Park My Car" to save your current location
2. **Add Details** (Optional): Add notes, start timer, or take a photo
3. **Return to Car**: Tap "Return to Car" to end your parking session
4. **Get Directions**: Use "Directions to Car" for navigation

### Advanced Features

#### Parking Notes
- Add contextual information about your parking spot
- Examples: "Level 3, Section B", "Next to red car", "Meter expires at 3 PM"

#### Parking Timer
- Automatically tracks parking duration
- Manual start/stop controls available
- Displays elapsed time in human-readable format

#### Parking Photo
- Take a photo of your car or surrounding area
- Helps visually identify your parking spot
- Stored locally and included in parking history

#### Settings Customization
- **Map Style**: Choose between Standard, Satellite, or Hybrid
- **Directions Mode**: Walking or driving directions preference  
- **Units**: Miles or kilometers for distance display
- **Haptic Feedback**: Enable/disable haptic responses
- **Auto Features**: Auto-start timer, confirm actions, etc.

## Architecture

### MVVM Pattern
The app uses Model-View-ViewModel architecture for clean separation of concerns:

- **Models**: Simple data structures (`ParkingLocation`, `ParkingRecord`)
- **Views**: SwiftUI views that observe the ViewModel
- **ViewModel**: `ParkingViewModel` manages all state and business logic

### Key Components

#### Core Files
- `ParkeeApp.swift`: Main app entry point
- `ContentView.swift`: Primary interface with map and action buttons
- `ParkingViewModel.swift`: Central state management and business logic
- `ParkingDetailsView.swift`: Detailed view for saved parking location

#### Supporting Files
- `DirectionsMapView.swift`: In-app navigation with MapKit
- `SettingsView.swift`: User preferences and customization
- `HistoryView.swift`: List of previously saved parking locations
- `ParkingHistory.swift`: Data models for parking records

### State Management
- Uses `@Published` properties for UI binding
- UserDefaults for local data persistence
- CoreLocation for GPS and location services
- MapKit for maps and navigation

## Development

### Project Structure

```
Parkee/
├── Parkee/                    # Main app source
│   ├── ContentView.swift      # Primary interface
│   ├── ParkingViewModel.swift # Business logic
│   ├── ParkingDetailsView.swift # Detail view
│   ├── DirectionsMapView.swift # Navigation modal
│   ├── SettingsView.swift     # User preferences
│   ├── HistoryView.swift      # Parking history
│   └── Models/                # Data structures
├── ParkeeTests/               # Unit tests
├── ParkeeUITests/             # UI tests
└── Parkee.xcodeproj/          # Xcode project
```

### Design System

#### Colors
- Primary Green: `#2EEA7B` (main action button)
- Primary Black: `#0A0A0A` (secondary actions)
- Gray Card: `#F2F3F5` (card backgrounds)
- Dynamic colors for dark mode support

#### Typography
- Titles: 28pt bold
- Sections: 22pt bold
- Body: 17pt regular
- Caption: 13pt

#### Layout
- Screen padding: 16pt
- Card radius: 18pt
- Button radius: 28pt
- Consistent spacing throughout

### Testing

Run the test suite using Xcode or command line:

```bash
# Run all tests
xcodebuild test -project Parkee.xcodeproj -scheme Parkee -destination 'platform=iOS Simulator,name=iPhone 15'

# Run specific test class
xcodebuild test -project Parkee.xcodeproj -scheme Parkee -destination 'platform=iOS Simulator,name=iPhone 15' -only-testing:ParkeeTests/ParkingViewModelTests
```

### Adding New Features

#### Settings
1. Add `@Published` property to `ParkingViewModel`
2. Add UserDefaults key and initialization
3. Add UI control in `SettingsView.swift`

#### Detail Sections
1. Follow existing patterns (Notes/Timer/Photo)
2. Add visibility toggle and persistence
3. Implement collapsible UI with animations

## Privacy

Parkee respects your privacy:
- **No Data Collection**: No analytics, tracking, or data collection
- **Local Storage Only**: All data stays on your device
- **Location Privacy**: Location used only for parking functionality
- **No Network Requests**: App works completely offline

## Contributing

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/AmazingFeature`)
3. Commit your changes (`git commit -m 'Add some AmazingFeature'`)
4. Push to the branch (`git push origin feature/AmazingFeature`)
5. Open a Pull Request

### Contribution Guidelines
- Follow existing code style and patterns
- Add tests for new functionality
- Update documentation as needed
- Keep features minimal and focused

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## Support

If you encounter any issues or have questions:
1. Check the [Issues](https://github.com/Juan-Oclock/Parkee/issues) page
2. Create a new issue with detailed description
3. Include iOS version and device information

## Roadmap

Future enhancements being considered:
- Apple Watch companion app
- Shortcuts app integration
- CarPlay support
- Multiple parking spot support
- Location sharing via Messages

---

**Parkee** - Simple parking made simple. 🚗✨
