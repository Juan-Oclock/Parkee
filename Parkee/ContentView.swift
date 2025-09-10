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
    @State private var annotationOffset: CGFloat = 0
    @State private var showCustomEndAlert = false
    @State private var pulseScale: CGFloat = 1.0
    @State private var pulseOpacity: Double = 0.3

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
                                // Outer animated pulse ring
                                Circle()
                                    .fill(Color.yellowGreen.opacity(0.15))
                                    .frame(width: 100, height: 100)
                                    .scaleEffect(pulseScale * 1.3)
                                    .opacity(pulseOpacity * 0.6)
                                
                                // Middle animated pulse ring
                                Circle()
                                    .fill(Color.yellowGreen.opacity(0.25))
                                    .frame(width: 80, height: 80)
                                    .scaleEffect(pulseScale * 1.1)
                                    .opacity(pulseOpacity * 0.8)
                                
                                // Inner pulse ring
                                Circle()
                                    .fill(Color.yellowGreen.opacity(0.35))
                                    .frame(width: 60, height: 60)
                                    .scaleEffect(pulseScale)
                                    .opacity(pulseOpacity)
                                
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
                                // Start the pulsing animation
                                withAnimation(.easeInOut(duration: 2.0).repeatForever(autoreverses: true)) {
                                    pulseScale = 1.4
                                }
                                withAnimation(.easeInOut(duration: 2.5).repeatForever(autoreverses: true)) {
                                    pulseOpacity = 0.1
                                }
                            }
                        }
                        .offset(y: annotationOffset)
                        .animation(.easeInOut(duration: 0.4), value: annotationOffset)
                    }
                }
            }
            .ignoresSafeArea()
            .mapStyle(resolvedMapStyle)
            .preferredColorScheme(viewModel.useDarkMap ? .dark : .light)
            .id("map-\(viewModel.preferredMapStyle)-\(viewModel.useDarkMap)")
            .onReceive(viewModel.$lastKnownCoordinate) { newCoord in
                // Center camera on user location when we receive it
                guard let coord = newCoord else { return }
                // Only auto-center if we don't have a saved location
                if viewModel.savedLocation == nil {
                    withAnimation(.easeInOut(duration: 0.35)) {
                        cameraPosition = .region(
                            MKCoordinateRegion(
                                center: coord,
                                span: MKCoordinateSpan(latitudeDelta: 0.02, longitudeDelta: 0.02)
                            )
                        )
                    }
                }
            }
            .onReceive(viewModel.$savedLocation) { savedLoc in
                // Zoom to parking location when it's saved
                guard let location = savedLoc else { return }
                withAnimation(.easeInOut(duration: 0.6)) {
                    cameraPosition = .region(
                        MKCoordinateRegion(
                            center: location.coordinate,
                            span: MKCoordinateSpan(latitudeDelta: 0.005, longitudeDelta: 0.005)
                        )
                    )
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
                    }
                }
                .padding(.horizontal, 16)
                .padding(.top, 12)
                Spacer()
            }

            // Bottom action buttons
            VStack(spacing: 14) {
                Button(action: {
                    // Save location first if needed, then show details
                    if viewModel.savedLocation == nil {
                        viewModel.saveCurrentLocation()
                        // Wait for save to complete before showing sheet
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                            // Sync notes when showing sheet
                            parkingNotes = viewModel.parkingNotes
                            showParkingDetailsSheet = true
                        }
                    } else {
                        // Sync notes when showing sheet
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
            if let coord = viewModel.immediateCoordinate() {
                cameraPosition = .region(
                    MKCoordinateRegion(
                        center: coord,
                        span: MKCoordinateSpan(latitudeDelta: 0.02, longitudeDelta: 0.02)
                    )
                )
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
        .sheet(isPresented: $showDirectionsModal) {
            if let savedLocation = viewModel.savedLocation,
               let currentLocation = viewModel.lastKnownCoordinate {
                DirectionsMapView(
                    currentLocation: currentLocation,
                    destination: savedLocation.coordinate
                )
                .presentationDetents([.fraction(0.7)])
                .presentationDragIndicator(.visible)
                .presentationCornerRadius(32)
                .presentationBackgroundInteraction(.enabled)  // Allow interaction with map behind
                .interactiveDismissDisabled(false)
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
                                    // Sync notes to viewModel BEFORE clearing data
                                    viewModel.parkingNotes = parkingNotes
                                    viewModel.clearAllParkingData()
                                    // Clear local notes state
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
            // Move entire annotation up when modal is shown, down when hidden
            if !showDirectionsModal {  // Only adjust if directions modal isn't shown
                annotationOffset = isShowing ? -150 : 0
            }
        }
        .onChange(of: showDirectionsModal) { _, isShowing in
            // Move entire annotation up when directions modal is shown, down when hidden
            annotationOffset = isShowing ? -150 : 0
        }
        .sheet(isPresented: $showParkingDetailsSheet) {
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
                    showParkingDetailsSheet = false
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                        showDirectionsModal = true
                    }
                },
                onEndSession: { 
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
            // Save notes back to viewModel when leaving
            viewModel.parkingNotes = parkingNotes
        }
        }
        }
    }
}

// MARK: - Helper Functions
extension ContentView {
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
