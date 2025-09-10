//
//  ParkingDetailsView.swift
//  Parkee
//
//  Full-screen map layout with expandable sections
//

import SwiftUI
import MapKit
import PhotosUI
import UIKit

// MARK: - Main View
struct ParkingDetailsView: View {
    @ObservedObject var viewModel: ParkingViewModel
    @Environment(\.dismiss) private var dismiss
    @Environment(\.displayScale) var displayScale
    @State private var cameraPosition: MapCameraPosition = .automatic
    @State private var showClearConfirm: Bool = false
    @State private var showDirectionsModal = false
    @State private var showDetailsSheet = false  // New state for details sheet
    @State private var hasInitializedCamera: Bool = false
    
    // Cache values we need - initialized once
    @State private var savedLocation: ParkingLocation?
    @State private var savedAddress: String?
    @State private var lastKnownCoordinate: CLLocationCoordinate2D?
    @State private var parkingNotes: String = ""
    
    // Cache timer state to minimize ViewModel dependencies
    @State private var cachedIsTimerRunning: Bool = false
    @State private var cachedTimerStart: Date?
    @State private var cachedAccumulatedSeconds: TimeInterval = 0
    
    // Stable map style to prevent reinitialization
    @State private var currentMapStyle: MapStyle = .standard
    @State private var currentUseDarkMap: Bool = false
    
    // Timer reference for proper cleanup
    @State private var updateTimer: Timer?
    
    // Store the background color immediately
    private let backgroundColor: Color
    private let isDarkMode: Bool
    
    init(viewModel: ParkingViewModel) {
        self.viewModel = viewModel
        
        // Set background color immediately based on system appearance
        let currentIsDark = UITraitCollection.current.userInterfaceStyle == .dark
        self.isDarkMode = currentIsDark
        self.backgroundColor = Color(currentIsDark ? UIColor.black : UIColor.white)
        
        // Initialize all cached values from viewModel
        _savedLocation = State(initialValue: viewModel.savedLocation)
        _savedAddress = State(initialValue: viewModel.savedAddress)
        _lastKnownCoordinate = State(initialValue: viewModel.lastKnownCoordinate)
        _parkingNotes = State(initialValue: viewModel.parkingNotes)
        _cachedIsTimerRunning = State(initialValue: viewModel.isTimerRunning)
        _cachedTimerStart = State(initialValue: viewModel.timerStart)
        _cachedAccumulatedSeconds = State(initialValue: viewModel.accumulatedSeconds)
        
        // Set map style
        let mapStyle: MapStyle = {
            switch viewModel.preferredMapStyle {
            case "imagery": return .imagery
            case "hybrid": return .hybrid
            case "standard": return .standard
            default: return .standard
            }
        }()
        _currentMapStyle = State(initialValue: mapStyle)
        _currentUseDarkMap = State(initialValue: viewModel.useDarkMap)
        
        // Set camera position
        if let saved = viewModel.savedLocation {
            _cameraPosition = State(initialValue: .region(
                MKCoordinateRegion(
                    center: saved.coordinate,
                    span: MKCoordinateSpan(latitudeDelta: 0.005, longitudeDelta: 0.005)
                )
            ))
        } else if let coord = viewModel.lastKnownCoordinate {
            _cameraPosition = State(initialValue: .region(
                MKCoordinateRegion(
                    center: coord,
                    span: MKCoordinateSpan(latitudeDelta: 0.005, longitudeDelta: 0.005)
                )
            ))
        }
    }
    
    // MARK: - Color System
    var primaryText: Color {
        isDarkMode ? .white : .black
    }
    
    private var resolvedMapStyle: MapStyle {
        // Apply the user's selected map style
        switch viewModel.preferredMapStyle {
        case "imagery": return .imagery
        case "hybrid": return .hybrid
        case "standard": return .standard
        default: return .standard
        }
    }

    
    
    var body: some View {
        ZStack {
            // Full Screen Map
            mapView
                .ignoresSafeArea()
            
            // Top controls overlay
            VStack {
                HStack {
                    Button(action: { dismiss() }) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundColor(primaryText)
                            .frame(width: 44, height: 44)
                            .background(
                                Circle()
                                    .fill(.ultraThinMaterial)
                            )
                    }
                    
                    Spacer()
                }
                .padding(.horizontal, 20)
                .padding(.top, 50)
                
                Spacer()
                
                // Bottom button to show details
                Button(action: {
                    showDetailsSheet = true
                    // Adjust camera position to keep location visible above modal
                    adjustCameraForModal()
                }) {
                    HStack(spacing: 12) {
                        Image(systemName: "car.fill")
                            .font(.system(size: 20, weight: .bold))
                        Text("View Parking Details")
                            .font(.system(size: 17, weight: .semibold))
                    }
                    .foregroundColor(.black)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 18)
                    .background(
                        RoundedRectangle(cornerRadius: 28, style: .continuous)
                            .fill(Color.yellowGreen)
                            .shadow(color: Color.black.opacity(0.15), radius: 10, y: 5)
                    )
                    .padding(.horizontal, 20)
                    .padding(.bottom, 40)
                }
            }
        }
        .navigationBarHidden(true)
        .navigationBarBackButtonHidden(true)
        .toolbar(.hidden)
        .onAppear {
            // Sync notes with viewModel when view appears (important for new sessions)
            parkingNotes = viewModel.parkingNotes
            
            // Start periodic timer sync with proper reference for cleanup
            updateTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
                if cachedIsTimerRunning {
                    syncTimerStateDefensively()
                }
            }
        }
        .gesture(
            DragGesture()
                .onEnded { value in
                    // Detect swipe to right (positive translation.width)
                    if value.translation.width > 100 && abs(value.translation.height) < 50 {
                        dismiss()
                    }
                }
        )
        .alert("End Parking Session", isPresented: $showClearConfirm) {
            Button("Cancel", role: .cancel) { }
            Button("End Session", role: .destructive) {
                // Sync notes to viewModel BEFORE clearing data
                viewModel.parkingNotes = parkingNotes
                viewModel.clearAllParkingData()
                dismiss()
            }
        } message: {
            Text("This will save your location to history and clear the current parking session.")
        }
        .onDisappear {
            // Save notes back to viewModel when leaving
            viewModel.parkingNotes = parkingNotes
            // Clean up timer to prevent memory leaks
            updateTimer?.invalidate()
            updateTimer = nil
        }
        .onChange(of: showDetailsSheet) { _, isShowing in
            if !isShowing {
                // Reset camera position when modal is dismissed
                resetCameraPosition()
            }
        }
        .sheet(isPresented: $showDetailsSheet) {
            ParkingDetailsSheet(
                parkingNotes: $parkingNotes,
                isTimerRunning: cachedIsTimerRunning,
                timerStartDate: cachedTimerStart,
                accumulatedSeconds: cachedAccumulatedSeconds,
                savedAddress: savedAddress,
                colorScheme: isDarkMode ? .dark : .light,
                onStartTimer: { 
                    viewModel.startTimer()
                    syncTimerState()
                },
                onStopTimer: { 
                    viewModel.stopTimer()
                    syncTimerState()
                },
                onResetTimer: { 
                    viewModel.resetTimer()
                    syncTimerState()
                },
                onShowDirections: { 
                    showDetailsSheet = false
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                        showDirectionsModal = true
                    }
                },
                onEndSession: { 
                    // Sync notes to viewModel BEFORE showing confirmation
                    viewModel.parkingNotes = parkingNotes
                    showDetailsSheet = false
                    showClearConfirm = true 
                }
            )
            .presentationDetents([.height(500), .large])
            .presentationDragIndicator(.visible)
            .presentationCornerRadius(32)
            .presentationBackground(.ultraThinMaterial)
            .interactiveDismissDisabled(false)
            .presentationBackgroundInteraction(.enabled)
        }
        .sheet(isPresented: $showDirectionsModal) {
            if let savedLoc = savedLocation,
               let currentLoc = lastKnownCoordinate {
                DirectionsMapView(
                    currentLocation: currentLoc,
                    destination: savedLoc.coordinate
                )
                .presentationDetents([.fraction(0.75)])
                .presentationDragIndicator(.visible)
                .presentationCornerRadius(32)
            }
        }
        
    }
    
    // MARK: - Map View
    @ViewBuilder
    private var mapView: some View {
        Map(position: $cameraPosition) {
            if let saved = savedLocation {
                Annotation("", coordinate: saved.coordinate) {
                    ZStack {
                        // Outer pulse ring
                        Circle()
                            .fill(Color.yellowGreen.opacity(0.2))
                            .frame(width: 120, height: 120)
                        
                        // Inner pulse ring
                        Circle()
                            .fill(Color.yellowGreen.opacity(0.3))
                            .frame(width: 80, height: 80)
                        
                        // Main marker
                        ZStack {
                            Circle()
                                .fill(Color.yellowGreen)
                                .frame(width: 50, height: 50)
                            
                            Image(systemName: "car.fill")
                                .font(.system(size: 22, weight: .bold))
                                .foregroundColor(.black)
                        }
                        .shadow(color: Color.yellowGreen.opacity(0.5), radius: 10, y: 5)
                    }
                    .overlay(alignment: .top) {
                        // Location bubble
                        VStack(spacing: 2) {
                            // First line: "Parked Location"
                            Text("Parked Location")
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundColor(Color.black.opacity(0.6))
                                .fixedSize(horizontal: true, vertical: false)
                            
                            // Second line: Actual location name
                            Text(savedAddress ?? "Unknown Location")
                                .font(.system(size: 15, weight: .bold))
                                .foregroundColor(.black)
                                .lineLimit(1)
                                .truncationMode(.tail)
                                .frame(minWidth: 200)
                        }
                        .padding(.horizontal, 20)
                        .padding(.vertical, 12)
                        .background(
                            RoundedRectangle(cornerRadius: 14, style: .continuous)
                                .fill(Color.yellowGreen)
                                .shadow(color: Color.black.opacity(0.2), radius: 10, y: 5)
                        )
                        .offset(y: -90)
                    }
                }
            }
            
            UserAnnotation()
        }
        .mapStyle(currentMapStyle)
    }
    
    
    
    // MARK: - Helper Methods
    private func syncTimerState() {
        cachedIsTimerRunning = viewModel.isTimerRunning
        cachedTimerStart = viewModel.timerStart
        cachedAccumulatedSeconds = viewModel.accumulatedSeconds
    }
    
    private func syncTimerStateDefensively() {
        // Only update cached timer state if values have actually changed
        if cachedIsTimerRunning != viewModel.isTimerRunning {
            cachedIsTimerRunning = viewModel.isTimerRunning
        }
        
        if cachedTimerStart != viewModel.timerStart {
            cachedTimerStart = viewModel.timerStart
        }
        
        if cachedAccumulatedSeconds != viewModel.accumulatedSeconds {
            cachedAccumulatedSeconds = viewModel.accumulatedSeconds
        }
    }
    
    private func adjustCameraForModal() {
        guard let saved = savedLocation else { return }
        
        // Modal sheet with height(500) takes up approximately 50% of screen
        // To center the parking location in the remaining visible 50%,
        // we shift the map center down slightly (about 25% of visible area)
        let adjustedCenter = CLLocationCoordinate2D(
            latitude: saved.coordinate.latitude - 0.0012,  // Smaller shift to center in visible area
            longitude: saved.coordinate.longitude
        )
        
        // Keep normal zoom level - same as original view
        let region = MKCoordinateRegion(
            center: adjustedCenter,
            span: MKCoordinateSpan(latitudeDelta: 0.005, longitudeDelta: 0.005)  // Normal zoom
        )
        
        withAnimation(.easeInOut(duration: 0.5)) {
            cameraPosition = .region(region)
        }
    }
    
    private func resetCameraPosition() {
        guard let saved = savedLocation else { return }
        
        // Reset to original position
        let region = MKCoordinateRegion(
            center: saved.coordinate,
            span: MKCoordinateSpan(latitudeDelta: 0.005, longitudeDelta: 0.005)
        )
        
        withAnimation(.easeInOut(duration: 0.4)) {
            cameraPosition = .region(region)
        }
    }
}
