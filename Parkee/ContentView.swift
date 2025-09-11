//
//  ContentView.swift
//  Parkee
//
//  Created by Juan Oclock on 9/5/25.
//

import SwiftUI
import CoreLocation
import MapKit

struct ContentView: View {
    // ViewModel instance for binding
    @EnvironmentObject var viewModel: ParkingViewModel
    @Environment(\.colorScheme) var colorScheme
    @State private var cameraPosition: MapCameraPosition = .automatic
    @State private var showParkFirstAlert = false
    @State private var showDirectionsModal = false
    @State private var showParkingDetailsSheet = false
    @State private var showEndSessionConfirm = false
    @State private var parkingNotes: String = ""
    @State private var mapCameraOffset: CGFloat = 0
    @State private var showCustomEndAlert = false
    @State private var pulseAnimation: Bool = false
    @State private var hasInitializedCamera = false
    @State private var hasStartedZoomAnimation = false
    @State private var isInitialLoad = true

    private var resolvedMapStyle: MapStyle {
        // Apply the user's selected map style regardless of dark mode
        switch viewModel.preferredMapStyle {
        case "imagery": return .imagery
        case "hybrid": return .hybrid
        case "standard": return .standard
        default: return .standard
        }
    }

    var body: some View {
        GeometryReader { geometry in
            NavigationStack {
            ZStack(alignment: .bottom) {
            // Fullscreen map showing user's current location and saved pin if any
            Map(position: $cameraPosition, interactionModes: [.all]) {
                // Show the blue dot for user's location
                UserAnnotation()
                
                // Enhanced parking location annotation
                if let saved = viewModel.savedLocation {
                    Annotation("", coordinate: saved.coordinate) {
                        // Entire annotation container that moves together
                        VStack(spacing: 0) {
                            // Location information bubble - wide horizontal layout
                            VStack(alignment: .leading, spacing: 3) {
                                // Header with time
                                HStack {
                                    Text("Parked Here")
                                        .font(.system(size: 11, weight: .semibold))
                                        .foregroundColor(Color.black.opacity(0.5))
                                    
                                    if let savedAt = viewModel.savedAt {
                                        Text("• " + timeAgoString(from: savedAt))
                                            .font(.system(size: 11, weight: .medium))
                                            .foregroundColor(Color.black.opacity(0.5))
                                    }
                                    
                                    Spacer()
                                }
                                .frame(maxWidth: .infinity)
                                
                                if let address = viewModel.savedAddress {
                                    // Show full address with better width usage
                                    Text(address)
                                        .font(.system(size: 13, weight: .bold))
                                        .foregroundColor(.black)
                                        .lineLimit(2)
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                }
                            }
                            .padding(.horizontal, 16)
                            .padding(.vertical, 10)
                            .frame(minWidth: geometry.size.width * 0.7, maxWidth: geometry.size.width * 0.9)
                            .background(
                                RoundedRectangle(cornerRadius: 12, style: .continuous)
                                    .fill(Color.yellowGreen)
                                    .shadow(color: Color.black.opacity(0.15), radius: 8, y: 4)
                            )
                            .padding(.bottom, 10) // Space between bubble and car icon
                            
                            // Car marker with animated pulse rings
                            ZStack {
                                // Animated expanding pulse ring (fades out as it expands)
                                Circle()
                                    .stroke(Color.yellowGreen, lineWidth: 2)
                                    .frame(width: 60, height: 60)
                                    .scaleEffect(pulseAnimation ? 2.0 : 1.0)
                                    .opacity(pulseAnimation ? 0.0 : 0.6)
                                    .animation(
                                        .easeOut(duration: 3.0)  // Slower animation for less CPU usage
                                        .repeatForever(autoreverses: false)
                                        .delay(0.5),  // Add delay between pulses
                                        value: pulseAnimation
                                    )
                                
                                // Static outer ring for visibility
                                Circle()
                                    .fill(Color.yellowGreen.opacity(0.2))
                                    .frame(width: 100, height: 100)
                                
                                // Static middle ring
                                Circle()
                                    .fill(Color.yellowGreen.opacity(0.3))
                                    .frame(width: 70, height: 70)
                                
                                // Main marker (static)
                                ZStack {
                                    Circle()
                                        .fill(Color.yellowGreen)
                                        .frame(width: 44, height: 44)
                                    
                                    Image(systemName: "car.fill")
                                        .font(.system(size: 20, weight: .bold))
                                        .foregroundColor(.black)
                                }
                                .shadow(color: Color.yellowGreen.opacity(0.5), radius: 8, y: 4)
                            }
                            .onAppear {
                                // Trigger the pulse animation
                                pulseAnimation = true
                            }
                        }
                    }
                }
            }
            .ignoresSafeArea()
            .mapStyle(resolvedMapStyle)
            .preferredColorScheme(viewModel.useDarkMap ? .dark : .light)
            // Removed .id() to prevent map recreation on preference changes
            .onReceive(viewModel.$lastKnownCoordinate
                .removeDuplicates(by: { prev, new in
                    // Only update if coordinate actually changed significantly
                    guard let prev = prev, let new = new else { return prev == nil && new == nil }
                    return abs(prev.latitude - new.latitude) < 0.0001 && 
                           abs(prev.longitude - new.longitude) < 0.0001
                })
            ) { newCoord in
                // Center camera on user location when we receive it
                guard let coord = newCoord else { return }
                
                // Start with a zoomed-out region on initial load
                if isInitialLoad && !hasStartedZoomAnimation {
                    hasStartedZoomAnimation = true
                    cameraPosition = .region(
                        MKCoordinateRegion(
                            center: coord,
                            span: MKCoordinateSpan(latitudeDelta: 0.5, longitudeDelta: 0.5) // zoomed out
                        )
                    )
                    
                    // Animate to a closer zoom to indicate the map is working
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                        withAnimation(.easeInOut(duration: 1.0)) {
                            cameraPosition = .region(
                                MKCoordinateRegion(
                                    center: coord,
                                    span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
                                )
                            )
                        }
                        
                        // Final zoom after a short delay
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.9) {
                            withAnimation(.easeInOut(duration: 0.6)) {
                                cameraPosition = .region(
                                    MKCoordinateRegion(
                                        center: coord,
                                        span: MKCoordinateSpan(latitudeDelta: 0.02, longitudeDelta: 0.02)
                                    )
                                )
                                isInitialLoad = false
                                hasInitializedCamera = true
                            }
                        }
                    }
                } else if viewModel.savedLocation == nil && !hasInitializedCamera {
                    // Fallback centering if we haven't initialized through the animation
                    withAnimation(.easeInOut(duration: 0.35)) {
                        cameraPosition = .region(
                            MKCoordinateRegion(
                                center: coord,
                                span: MKCoordinateSpan(latitudeDelta: 0.02, longitudeDelta: 0.02)
                            )
                        )
                    }
                    hasInitializedCamera = true
                }
            }
            .onReceive(viewModel.$savedLocation) { savedLoc in
                // Zoom to parking location when it's saved
                guard let location = savedLoc else { return }
                
                // If this is the initial load with a saved location, start with zoom animation
                if isInitialLoad && !hasStartedZoomAnimation {
                    hasStartedZoomAnimation = true
                    // Start zoomed out
                    cameraPosition = .region(
                        MKCoordinateRegion(
                            center: location.coordinate,
                            span: MKCoordinateSpan(latitudeDelta: 0.5, longitudeDelta: 0.5)
                        )
                    )
                    
                    // Animate zoom in to saved location
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                        withAnimation(.easeInOut(duration: 1.2)) {
                            updateCameraForSavedLocation(location: location, offset: mapCameraOffset)
                            isInitialLoad = false
                        }
                    }
                } else {
                    updateCameraForSavedLocation(location: location, offset: mapCameraOffset)
                }
            }
            .onAppear {
                // If no location is available yet, request it to trigger the zoom animation
                if viewModel.lastKnownCoordinate == nil && viewModel.savedLocation == nil {
                    viewModel.refreshCurrentLocationForDisplay()
                }
            }

            // Title + top action icons (anchored to top)
            VStack {
                HStack {
                    NavigationLink(value: "settings") {
                        Image(systemName: "gearshape")
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundStyle(viewModel.useDarkMap ? .white : .black)
                            .shadow(radius: 3)
                            .frame(minWidth: 44, minHeight: 44)  // Ensure adequate touch target
                            .contentShape(Rectangle())  // Define clear tap area
                    }
                    Spacer()
                    Text("Parkee")
                        .font(.system(size: 36, weight: .heavy))
                        .foregroundStyle(Color.yellowGreen)
                        .shadow(color: .black.opacity(0.6), radius: 6, x: 0, y: 1)
                    Spacer()
                    NavigationLink(value: "history") {
                        Image(systemName: "clock.arrow.circlepath")
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundStyle(viewModel.useDarkMap ? .white : .black)
                            .shadow(radius: 3)
                            .frame(minWidth: 44, minHeight: 44)  // Ensure adequate touch target
                            .contentShape(Rectangle())  // Define clear tap area
                    }
                }
                .padding(.horizontal, 16)
                .padding(.top, 12)
                
                // Show locating indicator during initial zoom
                if isInitialLoad && hasStartedZoomAnimation {
                    HStack(spacing: 8) {
                        Image(systemName: "location.fill")
                            .font(.system(size: 14))
                            .foregroundColor(Color.yellowGreen)
                            .symbolEffect(.pulse.byLayer, options: .repeating)
                        Text("Locating...")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(viewModel.useDarkMap ? .white : .black)
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(
                        Capsule()
                            .fill(viewModel.useDarkMap ? Color.black.opacity(0.6) : Color.white.opacity(0.9))
                            .shadow(radius: 4)
                    )
                    .padding(.top, 8)
                    .transition(.opacity.combined(with: .scale))
                }
                
                Spacer()
            }

            // Bottom action buttons
            VStack(spacing: 14) {
                Button(action: {
                    // Save location first if needed, then show details
                    if viewModel.savedLocation == nil {
                        // Try immediate save using cached location
                        let savedImmediately = viewModel.saveLocationImmediately()
                        
                        if savedImmediately {
                            // Location saved immediately, show sheet right away
                            parkingNotes = viewModel.parkingNotes
                            showParkingDetailsSheet = true
                        } else {
                            // Need to wait for async location update
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                                // Load notes from viewModel when showing sheet
                                parkingNotes = viewModel.parkingNotes
                                showParkingDetailsSheet = true
                            }
                        }
                    } else {
                        // Load notes from viewModel when showing sheet
                        parkingNotes = viewModel.parkingNotes
                        showParkingDetailsSheet = true
                    }
                }) {
                    HStack(spacing: 10) {
                        Image(systemName: "p.circle.fill")
                            .font(.title2)
                        Text(viewModel.isSaving ? "Saving…" : (viewModel.savedLocation != nil ? "View Parking Details" : "Park My Car"))
                            .font(.system(size: 20, weight: .semibold))
                    }
                    .foregroundColor(.raisinBlack)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 18)
                    .background(Color.yellowGreen)
                    .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
                }
                .disabled(viewModel.isSaving)

                Button(action: {
                    if viewModel.savedLocation != nil {
                        showDirectionsModal = true
                    } else {
                        showParkFirstAlert = true
                    }
                }) {
                    HStack(spacing: 10) {
                        Image(systemName: "car.fill")
                            .font(.title3)
                        Text("Directions to Car")
                            .font(.system(size: 18, weight: .semibold))
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 18)
                    .background(Color.darkCard)
                    .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
                }

                if let saved = viewModel.savedLocation {
                    Text(String(format: "Saved at %.5f, %.5f", saved.latitude, saved.longitude))
                        .font(.footnote)
                        .foregroundColor(.white)
                        .shadow(radius: 4)
                }

                if let message = viewModel.errorMessage {
                    Text(message)
                        .font(.footnote)
                        .foregroundColor(.red)
                        .multilineTextAlignment(.center)
                }
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 24)
        }
        .onAppear {
            viewModel.requestPermissionIfNeeded()
            // If CoreLocation has a cached coordinate, center immediately to avoid Cupertino default
            if !hasInitializedCamera, let coord = viewModel.immediateCoordinate() {
                cameraPosition = .region(
                    MKCoordinateRegion(
                        center: coord,
                        span: MKCoordinateSpan(latitudeDelta: 0.02, longitudeDelta: 0.02)
                    )
                )
                hasInitializedCamera = true
            }
            viewModel.refreshCurrentLocationForDisplay()
        }
        .navigationDestination(for: String.self) { route in
            if route == "settings" {
                SettingsView(viewModel: viewModel)
            } else if route == "history" {
                HistoryView(viewModel: viewModel)
            }
        }
        .toolbar(.hidden, for: .navigationBar)
        .toolbarBackground(.hidden, for: .navigationBar)
        .preferredColorScheme(viewModel.useDarkMap ? .dark : .light)
        .alert("Park Your Car First", isPresented: $showParkFirstAlert) {
            Button("OK") { }
        } message: {
            Text("You need to park your car first before you can get directions to it. Tap 'Park My Car' to save your current location.")
        }
        .sheet(isPresented: $showDirectionsModal, onDismiss: {
            // When returning from directions, reload notes from viewModel
            parkingNotes = viewModel.parkingNotes
        }) {
            if let savedLocation = viewModel.savedLocation,
               let currentLocation = viewModel.lastKnownCoordinate {
                DirectionsMapView(
                    currentLocation: currentLocation,
                    destination: savedLocation.coordinate,
                    onEndSession: {
                        // Clear parking data when ending session from directions
                        viewModel.parkingNotes = parkingNotes
                        viewModel.clearAllParkingData()
                        showDirectionsModal = false
                    }
                )
                .presentationDetents([.large])  // Open directly at full height
                .presentationDragIndicator(.visible)
                .presentationCornerRadius(32)
                .presentationBackground(.regularMaterial)
                .presentationBackgroundInteraction(.disabled)  // No background interaction when fully expanded
                .interactiveDismissDisabled(false)  // Allow swipe down to dismiss
            }
        }
        .overlay(
            // Custom alert overlay
            Group {
                if showEndSessionConfirm {
                    ZStack {
                        // Background blur
                        Color.black.opacity(0.4)
                            .ignoresSafeArea()
                            .onTapGesture {
                                // Dismiss on background tap
                                showEndSessionConfirm = false
                            }
                        
                        // Alert content
                        VStack(spacing: 0) {
                            // Title
                            Text("End Parking Session")
                                .font(.system(size: 17, weight: .semibold))
                                .foregroundColor(colorScheme == .dark ? .white : .black)
                                .padding(.top, 20)
                                .padding(.horizontal, 16)
                            
                            // Message
                            Text("This will save your location to history and clear the current parking session.")
                                .font(.system(size: 13))
                                .foregroundColor(colorScheme == .dark ? Color.white.opacity(0.7) : Color.black.opacity(0.6))
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, 16)
                                .padding(.top, 8)
                                .padding(.bottom, 20)
                            
                            Divider()
                                .background(Color.gray.opacity(0.3))
                            
                            // Buttons
                            HStack(spacing: 0) {
                                // Cancel button
                                Button(action: {
                                    showEndSessionConfirm = false
                                }) {
                                    Text("Cancel")
                                        .font(.system(size: 17))
                                        .foregroundColor(Color.blue)
                                        .frame(maxWidth: .infinity)
                                        .padding(.vertical, 12)
                                }
                                
                                Divider()
                                    .background(Color.gray.opacity(0.3))
                                    .frame(width: 1)
                                
                                // End Session button with custom color
                                Button(action: {
                                    showEndSessionConfirm = false
                                    // Notes are already synced to viewModel at this point
                                    viewModel.clearAllParkingData()
                                    // Clear local notes state only after ending session
                                    parkingNotes = ""
                                }) {
                                    Text("End Session")
                                        .font(.system(size: 17, weight: .semibold))
                                        .foregroundColor(colorScheme == .dark ? Color.yellowGreen : Color.raisinBlack)
                                        .frame(maxWidth: .infinity)
                                        .padding(.vertical, 12)
                                }
                            }
                            .frame(height: 44)
                        }
                        .frame(width: 270)
                        .background(
                            RoundedRectangle(cornerRadius: 14)
                                .fill(colorScheme == .dark ? Color(UIColor.systemGray6) : Color.white)
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 14)
                                .stroke(Color.gray.opacity(0.2), lineWidth: 0.5)
                        )
                    }
                    .transition(.opacity)
                    .animation(.easeInOut(duration: 0.2), value: showEndSessionConfirm)
                }
            }
        )
        .onChange(of: showParkingDetailsSheet) { _, isShowing in
            // Adjust map camera when modal is shown to keep annotation visible
            if !showDirectionsModal {  // Only adjust if directions modal isn't shown
                mapCameraOffset = isShowing ? -0.002 : 0  // Negative moves map up
                if let location = viewModel.savedLocation {
                    updateCameraForSavedLocation(location: location, offset: mapCameraOffset)
                }
            }
        }
        .onChange(of: showDirectionsModal) { _, isShowing in
            // Adjust map camera when directions modal is shown
            mapCameraOffset = isShowing ? -0.002 : 0  // Negative moves map up
            if let location = viewModel.savedLocation {
                updateCameraForSavedLocation(location: location, offset: mapCameraOffset)
            }
        }
        .sheet(isPresented: $showParkingDetailsSheet, onDismiss: {
            // Save notes back to viewModel when sheet is dismissed (not ending session)
            viewModel.parkingNotes = parkingNotes
        }) {
            ParkingDetailsSheet(
                parkingNotes: $parkingNotes,
                isTimerRunning: viewModel.isTimerRunning,
                timerStartDate: viewModel.timerStart,
                accumulatedSeconds: viewModel.accumulatedSeconds,
                savedAddress: viewModel.savedAddress,
                colorScheme: colorScheme,
                onStartTimer: {
                    viewModel.startTimer()
                },
                onStopTimer: { 
                    viewModel.stopTimer()
                },
                onResetTimer: { 
                    viewModel.resetTimer()
                },
                onShowDirections: {
                    // Save notes before showing directions
                    viewModel.parkingNotes = parkingNotes
                    showParkingDetailsSheet = false
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                        showDirectionsModal = true
                    }
                },
                onEndSession: {
                    // Save notes before ending session
                    viewModel.parkingNotes = parkingNotes
                    showParkingDetailsSheet = false
                    showEndSessionConfirm = true
                }
            )
            .presentationDetents([.height(500), .large])
            .presentationDragIndicator(.visible)
            .presentationCornerRadius(32)
            .presentationBackground(.ultraThinMaterial)
            .interactiveDismissDisabled(false)
            .presentationBackgroundInteraction(.enabled)
        }
        .onDisappear {
            // Save notes back to viewModel when leaving the view entirely
            viewModel.parkingNotes = parkingNotes
        }
        }
        }
    }
}

// MARK: - Helper Functions
extension ContentView {
    private func updateCameraForSavedLocation(location: ParkingLocation, offset: CGFloat) {
        // Calculate the center point with offset applied
        // Negative offset moves the map up (so annotation appears higher on screen)
        let adjustedCenter = CLLocationCoordinate2D(
            latitude: location.coordinate.latitude + offset,
            longitude: location.coordinate.longitude
        )
        
        withAnimation(.easeInOut(duration: 0.4)) {
            cameraPosition = .region(
                MKCoordinateRegion(
                    center: adjustedCenter,
                    span: MKCoordinateSpan(latitudeDelta: 0.005, longitudeDelta: 0.005)
                )
            )
        }
    }
    
    private func timeAgoString(from date: Date) -> String {
        let now = Date()
        let interval = now.timeIntervalSince(date)
        
        if interval < 60 {
            return "Just now"
        } else if interval < 3600 {
            let minutes = Int(interval / 60)
            return "\(minutes) min\(minutes == 1 ? "" : "s") ago"
        } else if interval < 86400 {
            let hours = Int(interval / 3600)
            return "\(hours) hour\(hours == 1 ? "" : "s") ago"
        } else {
            let days = Int(interval / 86400)
            return "\(days) day\(days == 1 ? "" : "s") ago"
        }
    }
}

#Preview {
    ContentView()
        .environmentObject(ParkingViewModel())
}
