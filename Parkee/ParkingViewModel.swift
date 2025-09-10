//
//  ParkingViewModel.swift
//  Parkee
//
//  ViewModel encapsulating location permissions, current GPS, persistence, and Maps opening.
//

import Foundation
import Combine
import CoreLocation
import MapKit
import SwiftUI

/// ViewModel for Parkee's single-screen app
final class ParkingViewModel: NSObject, ObservableObject {
    // MARK: - Published properties for UI binding
    @Published var savedLocation: ParkingLocation? = nil
    @Published var authorizationStatus: CLAuthorizationStatus = .notDetermined
    @Published var isSaving: Bool = false
    @Published var errorMessage: String? = nil
    /// Latest known user location for map display (not persisted)
    @Published var lastKnownCoordinate: CLLocationCoordinate2D? = nil
    /// When the parking location was saved
    @Published var savedAt: Date? = nil
    /// Human-friendly address for the saved location
    @Published var savedAddress: String? = nil
    /// Location name for the saved location (for history)
    @Published var savedLocationName: String? = nil
    /// User-entered notes about the parking spot
    @Published var parkingNotes: String = "" {
        didSet { defaults.set(parkingNotes, forKey: notesKey) }
    }
    /// Timer state
    @Published var isTimerRunning: Bool = false
    @Published var accumulatedSeconds: TimeInterval = 0
    @Published var elapsedTimeString: String = "00:00"
    private var timer: Timer?
    private var timerStartDate: Date? = nil
    
    /// Getter for timer start date (for isolated views)
    var timerStart: Date? {
        return timerStartDate
    }
    /// Optional saved photo URL
    @Published var photoURL: URL? = nil
    /// Map appearance preference
    @Published var useDarkMap: Bool = false { didSet { defaults.set(useDarkMap, forKey: darkMapKey) } }
    /// Map style preference label ("standard" | "imagery" | "hybrid")
    @Published var preferredMapStyle: String = "standard" { didSet { defaults.set(preferredMapStyle, forKey: preferredMapStyleKey) } }
    /// Show compass overlay
    @Published var showCompass: Bool = false { didSet { defaults.set(showCompass, forKey: showCompassKey) } }
    /// Show scale overlay
    @Published var showScale: Bool = false { didSet { defaults.set(showScale, forKey: showScaleKey) } }
    /// Follow user on launch
    @Published var followOnLaunch: Bool = true { didSet { defaults.set(followOnLaunch, forKey: followOnLaunchKey) } }
    /// Prefer address over coordinates in UI
    @Published var showAddress: Bool = true { didSet { defaults.set(showAddress, forKey: showAddressKey) } }
    /// Apple Maps directions mode ("driving" | "walking")
    @Published var mapsDirectionsMode: String = "driving" { didSet { defaults.set(mapsDirectionsMode, forKey: mapsModeKey) } }
    /// Units ("miles" | "km")
    @Published var units: String = "miles" { didSet { defaults.set(units, forKey: unitsKey) } }
    /// Haptics on key actions
    @Published var isHapticsEnabled: Bool = true { didSet { defaults.set(isHapticsEnabled, forKey: hapticsKey) } }
    /// Confirm before clear
    @Published var confirmClearLocation: Bool = true { didSet { defaults.set(confirmClearLocation, forKey: confirmClearKey) } }
    /// Auto start timer after save
    @Published var autoStartTimer: Bool = false { didSet { defaults.set(autoStartTimer, forKey: autoStartTimerKey) } }
    /// Which detail sections are visible
    @Published var showNotes: Bool = false { didSet { defaults.set(showNotes, forKey: showNotesKey) } }
    @Published var showTimer: Bool = false { didSet { defaults.set(showTimer, forKey: showTimerKey) } }
    @Published var showPhoto: Bool = false { didSet { defaults.set(showPhoto, forKey: showPhotoKey) } }
    /// Onboarding state
    @Published var hasSeenOnboarding: Bool = false { didSet { defaults.set(hasSeenOnboarding, forKey: onboardingKey) } }

    // MARK: - Private properties
    private let locationManager: CLLocationManager
    private var cancellables = Set<AnyCancellable>()

    // UserDefaults keys
    private let defaults = UserDefaults.standard
    private let latKey = "parkee.saved.latitude"
    private let lonKey = "parkee.saved.longitude"
    private let notesKey = "parkee.notes"
    private let timerStartKey = "parkee.timer.start"
    private let timerAccumKey = "parkee.timer.accum"
    private let photoFileKey = "parkee.photo.filename"
    private let savedAtKey = "parkee.savedAt"
    private let savedAddressKey = "parkee.savedAddress"
    private let savedLocationNameKey = "parkee.savedLocationName"
    private let showNotesKey = "parkee.details.notes"
    private let showTimerKey = "parkee.details.timer"
    private let showPhotoKey = "parkee.details.photo"
    private let historyKey = "parkee.history"
    private let darkMapKey = "parkee.map.dark"
    private let preferredMapStyleKey = "parkee.map.style"
    private let showCompassKey = "parkee.map.compass"
    private let showScaleKey = "parkee.map.scale"
    private let followOnLaunchKey = "parkee.map.follow"
    private let showAddressKey = "parkee.display.address"
    private let mapsModeKey = "parkee.maps.mode"
    private let unitsKey = "parkee.units"
    private let hapticsKey = "parkee.haptics"
    private let confirmClearKey = "parkee.confirm.clear"
    private let autoStartTimerKey = "parkee.autostart.timer"
    private let onboardingKey = "parkee.onboarding.completed"

    @Published var history: [ParkingRecord] = []

    override init() {
        self.locationManager = CLLocationManager()
        super.init()
        self.locationManager.delegate = self
        self.locationManager.desiredAccuracy = kCLLocationAccuracyBest
        loadPersistedLocation()
        loadNotesAndTimer()
        loadPhoto()
        loadDetailsVisibility()
        loadHistory()
        useDarkMap = defaults.bool(forKey: darkMapKey)
        preferredMapStyle = defaults.string(forKey: preferredMapStyleKey) ?? "standard"
        showCompass = defaults.bool(forKey: showCompassKey)
        showScale = defaults.bool(forKey: showScaleKey)
        followOnLaunch = defaults.object(forKey: followOnLaunchKey) as? Bool ?? true
        showAddress = defaults.object(forKey: showAddressKey) as? Bool ?? true
        mapsDirectionsMode = defaults.string(forKey: mapsModeKey) ?? "driving"
        units = defaults.string(forKey: unitsKey) ?? "miles"
        isHapticsEnabled = defaults.object(forKey: hapticsKey) as? Bool ?? true
        confirmClearLocation = defaults.object(forKey: confirmClearKey) as? Bool ?? true
        autoStartTimer = defaults.bool(forKey: autoStartTimerKey)
        hasSeenOnboarding = defaults.bool(forKey: onboardingKey)
        authorizationStatus = locationManager.authorizationStatus
    }

    // MARK: - Permissions
    func requestPermissionIfNeeded() {
        let status = locationManager.authorizationStatus
        switch status {
        case .notDetermined:
            locationManager.requestWhenInUseAuthorization()
        case .denied, .restricted:
            // Surface an error; user can enable in Settings
            errorMessage = "Location access denied. Enable in Settings to save parking."
        default:
            break
        }
    }

    // MARK: - Debug/Reset Functions
    /// Resets map style to default (for testing)
    func resetMapStyleToDefault() {
        preferredMapStyle = "standard"
        useDarkMap = false
        defaults.removeObject(forKey: preferredMapStyleKey)
        defaults.removeObject(forKey: darkMapKey)
    }
    
    /// Debug function to clear all app data for testing new features
    func resetAllAppData() {
        // Clear all parking data
        clearAllParkingData()
        
        // Clear history
        clearHistory()
        
        // Reset map settings
        resetMapStyleToDefault()
        
        // Reset all settings to defaults
        showCompass = false
        showScale = false
        followOnLaunch = true
        showAddress = true
        mapsDirectionsMode = "driving"
        units = "miles"
        isHapticsEnabled = true
        confirmClearLocation = true
        autoStartTimer = false
        hasSeenOnboarding = false
        
        // Clear all UserDefaults keys
        let keys = [showCompassKey, showScaleKey, followOnLaunchKey, showAddressKey, mapsModeKey, unitsKey, hapticsKey, confirmClearKey, autoStartTimerKey, onboardingKey]
        keys.forEach { defaults.removeObject(forKey: $0) }
        
        print("🔄 All app data reset for testing new features")
    }
    
    // MARK: - Onboarding
    /// Marks onboarding as completed and transitions to main app
    func completeOnboarding() {
        hasSeenOnboarding = true
        print("✅ Onboarding completed")
    }
    
    // MARK: - Actions
    /// Saves the user's current GPS as parking location
    func saveCurrentLocation() {
        isSaving = true
        errorMessage = nil

        // Ensure permission
        let status = locationManager.authorizationStatus
        guard status == .authorizedWhenInUse || status == .authorizedAlways else {
            isSaving = false
            requestPermissionIfNeeded()
            return
        }

        // Request one location update
        locationManager.requestLocation()
    }

    /// Refreshes current GPS once to update the map display, without saving
    func refreshCurrentLocationForDisplay() {
        // If permission is not granted, trigger prompt; otherwise request one location
        let status = locationManager.authorizationStatus
        if status == .notDetermined { locationManager.requestWhenInUseAuthorization(); return }
        guard status == .authorizedAlways || status == .authorizedWhenInUse else { return }
        locationManager.requestLocation()
    }

    /// Clears any saved parking location
    func clearLocation() {
        savedLocation = nil
        defaults.removeObject(forKey: latKey)
        defaults.removeObject(forKey: lonKey)
    }

    /// Opens Apple Maps with the saved coordinate
    func openInMaps() {
        guard let location = savedLocation else { return }
        let placemark = MKPlacemark(coordinate: location.coordinate)
        let mapItem = MKMapItem(placemark: placemark)
        mapItem.name = "Parked Car"
        mapItem.openInMaps()
    }

    // MARK: - Persistence
    private func persist(location: ParkingLocation) {
        defaults.set(location.latitude, forKey: latKey)
        defaults.set(location.longitude, forKey: lonKey)
        let now = Date()
        savedAt = now
        defaults.set(now.timeIntervalSince1970, forKey: savedAtKey)
    }

    private func loadPersistedLocation() {
        let lat = defaults.double(forKey: latKey)
        let hasLat = defaults.object(forKey: latKey) != nil
        let lon = defaults.double(forKey: lonKey)
        let hasLon = defaults.object(forKey: lonKey) != nil
        if hasLat && hasLon {
            savedLocation = ParkingLocation(latitude: lat, longitude: lon)
        }
        if let ts = defaults.object(forKey: savedAtKey) as? Double {
            savedAt = Date(timeIntervalSince1970: ts)
        }
        if let addr = defaults.string(forKey: savedAddressKey) {
            savedAddress = addr
        }
        if let locationName = defaults.string(forKey: savedLocationNameKey) {
            savedLocationName = locationName
        }
    }

    /// Returns the best-known coordinate immediately (published or CoreLocation cache)
    func immediateCoordinate() -> CLLocationCoordinate2D? {
        if let coord = lastKnownCoordinate { return coord }
        return locationManager.location?.coordinate
    }

    // MARK: - Notes & Timer persistence
    private func loadNotesAndTimer() {
        // Only load notes if there's an active parking session (saved location exists)
        // This prevents notes from previous sessions from appearing in new sessions
        let hasActiveSession = defaults.object(forKey: latKey) != nil && defaults.object(forKey: lonKey) != nil
        
        if hasActiveSession, let notes = defaults.string(forKey: notesKey) {
            parkingNotes = notes
        } else {
            // Clear notes if no active session
            parkingNotes = ""
            defaults.removeObject(forKey: notesKey)
        }
        
        let accum = defaults.double(forKey: timerAccumKey)
        let hasAccum = defaults.object(forKey: timerAccumKey) != nil
        if hasAccum { accumulatedSeconds = accum }
        if let startEpoch = defaults.object(forKey: timerStartKey) as? Double {
            timerStartDate = Date(timeIntervalSince1970: startEpoch)
            isTimerRunning = true
        }
    }

    func startTimer() {
        guard !isTimerRunning else { return }
        timerStartDate = Date()
        defaults.set(timerStartDate!.timeIntervalSince1970, forKey: timerStartKey)
        isTimerRunning = true
    }

    func stopTimer() {
        guard isTimerRunning else { return }
        if let start = timerStartDate {
            accumulatedSeconds += Date().timeIntervalSince(start)
            defaults.set(accumulatedSeconds, forKey: timerAccumKey)
        }
        timerStartDate = nil
        defaults.removeObject(forKey: timerStartKey)
        isTimerRunning = false
    }

    func resetTimer() {
        timerStartDate = nil
        accumulatedSeconds = 0
        isTimerRunning = false
        defaults.removeObject(forKey: timerStartKey)
        defaults.set(0.0, forKey: timerAccumKey)
    }

    /// Computes current total elapsed seconds including running time
    func currentElapsedSeconds(reference: Date = Date()) -> TimeInterval {
        if isTimerRunning, let start = timerStartDate {
            return accumulatedSeconds + reference.timeIntervalSince(start)
        }
        return accumulatedSeconds
    }

    // MARK: - Photo persistence
    private func documentsDirectory() -> URL {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
    }

    private func loadPhoto() {
        if let fileName = defaults.string(forKey: photoFileKey) {
            photoURL = documentsDirectory().appendingPathComponent(fileName)
        }
    }

    private func loadDetailsVisibility() {
        // Show Notes by default (true) unless user has explicitly set it to false
        showNotes = defaults.object(forKey: showNotesKey) as? Bool ?? true
        if defaults.object(forKey: showTimerKey) != nil { showTimer = defaults.bool(forKey: showTimerKey) }
        if defaults.object(forKey: showPhotoKey) != nil { showPhoto = defaults.bool(forKey: showPhotoKey) }
    }

    func savePhoto(data: Data) {
        let fileName = "parking_photo.jpg"
        let url = documentsDirectory().appendingPathComponent(fileName)
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self = self else { return }
            do {
                try data.write(to: url, options: .atomic)
                DispatchQueue.main.async {
                    self.photoURL = url
                    self.defaults.set(fileName, forKey: self.photoFileKey)
                }
            } catch {
                DispatchQueue.main.async {
                    self.errorMessage = "Failed to save photo: \(error.localizedDescription)"
                }
            }
        }
    }

    func clearPhoto() {
        if let url = photoURL {
            try? FileManager.default.removeItem(at: url)
        }
        photoURL = nil
        defaults.removeObject(forKey: photoFileKey)
    }

    /// Clears all persisted parking-related data: location, timer, notes, photo, timestamps, and address
    func clearAllParkingData() {
        // Capture all current session data before clearing anything
        let currentLocation = savedLocation
        let currentSavedAt = savedAt
        let currentLocationName = savedLocationName
        let currentAddress = savedAddress
        let currentNotes = parkingNotes
        let currentTimer = currentElapsedSeconds()
        let hasPhoto = photoURL != nil
        
        // Save to history before clearing (end of parking session)
        if let location = currentLocation {
            // Create history record with captured data
            let record = ParkingRecord(
                latitude: location.latitude,
                longitude: location.longitude,
                savedAt: currentSavedAt ?? Date(),
                locationName: currentLocationName ?? currentAddress,
                notes: currentNotes.isEmpty ? nil : currentNotes,
                timerSeconds: currentTimer > 0 ? currentTimer : nil,
                hasPhoto: hasPhoto
            )
            
            history.insert(record, at: 0)
            saveHistory()
            
            // Force reload to ensure UI updates
            objectWillChange.send()
        }
        
        // Now clear everything
        // Location
        clearLocation()
        savedAt = nil
        savedAddress = nil
        savedLocationName = nil
        defaults.removeObject(forKey: savedAtKey)
        defaults.removeObject(forKey: savedAddressKey)
        defaults.removeObject(forKey: savedLocationNameKey)

        // Timer
        resetTimer()

        // Notes - Clear for next session
        parkingNotes = ""
        defaults.removeObject(forKey: notesKey)

        // Photo
        clearPhoto()

        // Collapse sections (persist visibility off)
        showNotes = false
        showTimer = false
        showPhoto = false
        
        // Reload history to ensure UI is in sync
        loadHistory()
        objectWillChange.send()
    }
}

// MARK: - CLLocationManagerDelegate
extension ParkingViewModel: CLLocationManagerDelegate {
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        authorizationStatus = manager.authorizationStatus
        if authorizationStatus == .authorizedWhenInUse || authorizationStatus == .authorizedAlways {
            // Fetch a single location to center the map by default
            manager.requestLocation()
        }
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        let wasSaving = isSaving
        guard let location = locations.last else {
            errorMessage = "Unable to get location. Try again."
            return
        }
        // Always update last known coordinate for the map
        lastKnownCoordinate = location.coordinate

        // Persist only if this update came from a save request
        if wasSaving {
            let saved = ParkingLocation(latitude: location.coordinate.latitude, longitude: location.coordinate.longitude)
            savedLocation = saved
            persist(location: saved)
            reverseGeocode(coordinate: saved.coordinate)
            // Note: History will be saved when user ends the parking session
            
            // Clear notes for new parking session (don't carry over from previous session)
            if parkingNotes != "" {
                parkingNotes = ""
                defaults.removeObject(forKey: notesKey)
            }
            
            // Reset Notes section to be open by default for new parking session
            showNotes = true
        }
        isSaving = false
    }

    // MARK: - Reverse geocoding
    private func reverseGeocode(coordinate: CLLocationCoordinate2D) {
        let geocoder = CLGeocoder()
        geocoder.reverseGeocodeLocation(CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)) { [weak self] placemarks, error in
            guard let self = self else { return }
            if let p = placemarks?.first {
                // Full address for display
                let parts = [p.name, p.locality, p.administrativeArea]
                    .compactMap { $0 }
                    .joined(separator: ", ")
                self.savedAddress = parts
                self.defaults.set(parts, forKey: self.savedAddressKey)
                
                // Location name for history (just the name/business)
                self.savedLocationName = p.name ?? p.thoroughfare ?? p.locality
                if let locationName = self.savedLocationName {
                    self.defaults.set(locationName, forKey: self.savedLocationNameKey)
                }
            }
            
            // Note: History will be saved when user clears location (ends parking session)
        }
    }

    func formattedSavedAt() -> String? {
        guard let date = savedAt else { return nil }
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .medium
        return formatter.string(from: date)
    }

    // MARK: - History
    private func loadHistory() {
        guard let data = defaults.data(forKey: historyKey) else {
            history = []
            return
        }
        
        do {
            let decoded = try JSONDecoder().decode([ParkingRecord].self, from: data)
            history = decoded
        } catch {
            // Clear corrupted data and start fresh
            history = []
            defaults.removeObject(forKey: historyKey)
        }
    }

    private func saveHistory() {
        if let data = try? JSONEncoder().encode(history) {
            defaults.set(data, forKey: historyKey)
        }
    }

    // Note: appendToHistory function has been removed as history saving is now handled directly in clearAllParkingData()

    func clearHistory() {
        history.removeAll()
        defaults.removeObject(forKey: historyKey)
    }
    
    func deleteHistoryItem(withId id: UUID) {
        history.removeAll { $0.id == id }
        saveHistory()
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        isSaving = false
        errorMessage = "Location error: \(error.localizedDescription)"
    }
}


