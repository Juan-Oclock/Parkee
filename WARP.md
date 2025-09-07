# WARP.md

This file provides guidance to WARP (warp.dev) when working with code in this repository.

## Project Overview

Parkee is a minimal iOS app for saving parking locations. Built with Swift and SwiftUI, it follows a strict one-button-save, one-button-view philosophy with no accounts, onboarding, or unnecessary features. The app targets iOS 17+ and uses MVVM architecture.

## Development Commands

### Building and Running
```bash
# Open project in Xcode
open Parkee.xcodeproj

# Build from command line (requires Xcode Command Line Tools)
xcodebuild -project Parkee.xcodeproj -scheme Parkee -destination 'platform=iOS Simulator,name=iPhone 15' build

# Run tests
xcodebuild test -project Parkee.xcodeproj -scheme Parkee -destination 'platform=iOS Simulator,name=iPhone 15'
```

### Testing
```bash
# Run unit tests
xcodebuild test -project Parkee.xcodeproj -scheme ParkeeTests -destination 'platform=iOS Simulator,name=iPhone 15'

# Run UI tests
xcodebuild test -project Parkee.xcodeproj -scheme ParkeeUITests -destination 'platform=iOS Simulator,name=iPhone 15'

# Run single test class
xcodebuild test -project Parkee.xcodeproj -scheme Parkee -destination 'platform=iOS Simulator,name=iPhone 15' -only-testing:ParkeeTests/SpecificTestClass
```

### Common Development Tasks
```bash
# Clean build folder
xcodebuild clean -project Parkee.xcodeproj -scheme Parkee

# Archive for distribution
xcodebuild archive -project Parkee.xcodeproj -scheme Parkee -archivePath ./Parkee.xcarchive

# Simulator management
xcrun simctl list devices  # List available simulators
xcrun simctl boot "iPhone 15"  # Boot specific simulator
```

## Architecture Overview

### MVVM Pattern
The app uses a single ViewModel (`ParkingViewModel`) that manages all state and business logic:

- **ParkingViewModel**: Central state manager handling location services, persistence, timer, notes, photos, and settings
- **Views**: SwiftUI views that observe the ViewModel via `@ObservedObject` or `@StateObject`
- **Models**: Simple data structures (`ParkingLocation`, `ParkingRecord`) with no business logic

### Key Components

#### Core Files
- `ParkeeApp.swift`: Main app entry point
- `ContentView.swift`: Primary interface with fullscreen map and action buttons
- `ParkingViewModel.swift`: Central business logic and state management
- `ParkingDetailsView.swift`: Detailed view when parking location is saved

#### Data Models
- `ParkingLocation.swift`: Simple coordinate model
- `ParkingHistory.swift`: Codable parking record with timestamp and address

#### Supporting Views
- `SettingsView.swift`: User preferences (map style, units, haptics, etc.)
- `HistoryView.swift`: List of previously saved parking locations
- `Triangle.swift`: Custom shape for map annotation bubbles

### State Management
The ViewModel uses `@Published` properties for UI binding and UserDefaults for persistence. Key state includes:

- Location permissions and GPS coordinates
- Saved parking location with reverse-geocoded address
- Parking timer (start/stop/accumulate)
- User notes about parking spot  
- Optional photo of parking location
- App settings and preferences
- Parking history

### Location Services
- Uses CoreLocation for GPS and permissions
- Implements CLLocationManagerDelegate
- Requests location on-demand (not continuous tracking)
- Integrates with Apple Maps for navigation

## Design System

### Colors
- Primary Green: `#2EEA7B` (main action button)
- Primary Black: `#0A0A0A` (secondary actions with white text)
- Gray Card: `#F2F3F5` (card backgrounds)
- Divider Gray: `#E3E5E8`
- Background: White only (no dark mode)

### Typography
- Titles: 28pt bold
- Sections: 22pt bold  
- Body: 17pt regular
- Caption: 13pt

### Layout
- Screen padding: 16pt
- Section spacing: 16pt
- Card inner padding: 14pt
- Card radius: 18pt
- Button radius: 28pt
- Small control radius: 14pt

## Project Rules

### Core Principles
- Minimal, clean, modern design using system fonts and SF Symbols
- One-tap save, one-tap view - user journey under 2 seconds
- No signup, login, accounts, or onboarding flows
- iOS 17+ compatibility required
- MVVM architecture with clear separation of concerns

### Code Standards
- Use Swift with SwiftUI for all UI
- Keep functions small and reusable
- Comment code clearly, especially complex location/permission logic
- Store data locally using UserDefaults and file system
- Follow existing patterns for new features

### Feature Constraints
- Core features only: save location, view on map, clear location
- Optional enhancements: timer, notes, photo, settings, history
- No cloud sync, user accounts, or social features
- All data stored locally on device

### UI Guidelines
- Full-width cards with 16pt margins
- Use Apple Maps for navigation (not custom implementation)
- Maintain consistent spacing and typography scale
- Green primary button for main actions
- Black secondary buttons with white text
- System gray backgrounds for cards and inputs

## Testing Strategy

- Unit tests in `ParkeeTests/` cover ViewModel business logic
- UI tests in `ParkeeUITests/` cover critical user flows
- Focus testing on location permissions, saving/clearing locations, and data persistence
- Test map integration and Apple Maps opening
- Verify timer functionality and UserDefaults persistence

## Common Patterns

### Adding New Settings
1. Add `@Published` property to `ParkingViewModel`
2. Add UserDefaults key constant
3. Initialize from UserDefaults in `init()`
4. Add didSet observer to persist changes
5. Add UI control in `SettingsView.swift`

### Adding New Detail Sections
1. Follow pattern from Notes/Timer/Photo sections
2. Add visibility toggle property (`show___`)
3. Add corresponding chip in `ParkingDetailsView`
4. Implement collapsible section with `.transition()` animations
5. Persist visibility state in UserDefaults
