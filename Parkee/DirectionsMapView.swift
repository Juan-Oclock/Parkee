//
//  DirectionsMapView.swift
//  Parkee
//
//  Created by Juan Oclock on 9/7/25.
//

import SwiftUI
import MapKit
import CoreLocation

struct DirectionsMapView: View {
    let initialLocation: CLLocationCoordinate2D
    let destination: CLLocationCoordinate2D
    let onEndSession: (() -> Void)?
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) var colorScheme
    @StateObject private var viewModel: DirectionsViewModel
    @State private var cameraPosition: MapCameraPosition = .automatic
    @State private var currentUserLocation: CLLocationCoordinate2D
    @State private var showNavigationPanel = false
    @State private var showArrivalAlert = false
    @State private var showEndSessionConfirm = false
    
    init(currentLocation: CLLocationCoordinate2D, destination: CLLocationCoordinate2D, onEndSession: (() -> Void)? = nil) {
        self.initialLocation = currentLocation
        self.destination = destination
        self.onEndSession = onEndSession
        self._currentUserLocation = State(initialValue: currentLocation)
        self._viewModel = StateObject(wrappedValue: DirectionsViewModel(
            from: currentLocation,
            to: destination
        ))
    }
    
    // MARK: - Color System
    var backgroundColor: Color {
        // Darker background for better contrast with the map behind
        colorScheme == .dark ? Color(red: 0.08, green: 0.08, blue: 0.12) : Color(red: 0.96, green: 0.96, blue: 0.97)
    }
    
    var cardBackground: Color {
        // Slightly elevated card backgrounds
        colorScheme == .dark ? Color(red: 0.15, green: 0.15, blue: 0.18) : Color.white
    }
    
    var primaryText: Color {
        colorScheme == .dark ? .white : .black
    }
    
    var secondaryText: Color {
        colorScheme == .dark ? Color.white.opacity(0.5) : Color.black.opacity(0.5)
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                // Background with enhanced contrast
                LinearGradient(
                    gradient: Gradient(colors: [
                        backgroundColor,
                        backgroundColor.opacity(0.95)
                    ]),
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()
                
                // Subtle overlay for depth
                Color.black.opacity(colorScheme == .dark ? 0.2 : 0.05)
                    .ignoresSafeArea()
                
                Map(position: $cameraPosition) {
                    // Current location marker - now using updated location
                    Annotation("Your Location", coordinate: currentUserLocation) {
                        ZStack {
                            Circle()
                                .fill(Color.blue.opacity(0.3))
                                .frame(width: 30, height: 30)
                            Circle()
                                .fill(Color.blue)
                                .frame(width: 16, height: 16)
                            Circle()
                                .fill(.white)
                                .frame(width: 6, height: 6)
                        }
                    }
                    
                    // Parked car marker with Parkee style
                    Annotation("Parked Car", coordinate: destination) {
                        ZStack {
                            Circle()
                                .fill(Color.yellowGreen.opacity(0.3))
                                .frame(width: 40, height: 40)
                            Circle()
                                .fill(Color.yellowGreen)
                                .frame(width: 30, height: 30)
                            Image(systemName: "car.fill")
                                .font(.system(size: 16, weight: .bold))
                                .foregroundColor(.black)
                        }
                        .shadow(color: Color.yellowGreen.opacity(0.5), radius: 5, y: 3)
                    }
                    
                    // Show route if available
                    if let route = viewModel.route {
                        MapPolyline(route.polyline)
                            .stroke(Color.yellowGreen, lineWidth: 5)
                    }
                }
                .mapStyle(.standard)
                .clipShape(RoundedRectangle(cornerRadius: 24))
                .overlay(
                    RoundedRectangle(cornerRadius: 24)
                        .stroke(Color.white.opacity(colorScheme == .dark ? 0.1 : 0.2), lineWidth: 1)
                )
                .shadow(color: Color.black.opacity(0.2), radius: 12, y: 6)  // Single optimized shadow
                .padding(.horizontal, 16)
                .padding(.top, 10)  // Reduced from 70 to give map more height
                .padding(.bottom, 100)
                .onAppear {
                    // Set initial camera position to show both points
                    let region = regionThatFits(
                        coordinate1: currentUserLocation,
                        coordinate2: destination
                    )
                    cameraPosition = .region(region)
                    
                    // Request directions and start location updates
                    viewModel.getDirections()
                    viewModel.startLocationUpdates()
                }
                .onReceive(viewModel.$route) { route in
                    // Adjust camera when route is calculated to show the entire route
                    if route != nil {
                        // Small delay to ensure route polyline is rendered
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                            withAnimation(.easeInOut(duration: 0.5)) {
                                let adjustedRegion = regionThatFits(
                                    coordinate1: currentUserLocation,
                                    coordinate2: destination
                                )
                                cameraPosition = .region(adjustedRegion)
                            }
                        }
                    }
                }
                .onReceive(viewModel.$userLocation) { newLocation in
                    // Update user location when it changes
                    if let newLocation = newLocation {
                        withAnimation(.easeInOut(duration: 0.3)) {
                            currentUserLocation = newLocation
                        }
                        // Recalculate route if user has moved significantly
                        viewModel.updateRouteIfNeeded(from: newLocation)
                    }
                }
                .onDisappear {
                    // Stop location updates when view disappears
                    viewModel.stopLocationUpdates()
                }
                
                // Loading indicator
                if viewModel.isLoading {
                    VStack(spacing: 12) {
                        ProgressView()
                            .scaleEffect(1.2)
                            .tint(Color.yellowGreen)
                        Text("Getting directions...")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(secondaryText)
                    }
                    .padding(20)
                    .background(
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .fill(cardBackground)
                            .shadow(color: Color.black.opacity(0.15), radius: 10, y: 5)
                    )
                }
                
                // Navigation Panel or Route Info Card
                VStack {
                    Spacer()
                    
                    if showNavigationPanel, let route = viewModel.route {
                        // Turn-by-turn navigation panel
                        VStack(spacing: 0) {
                            // Add Start Navigation button inside the panel when not navigating
                            if !viewModel.isNavigating {
                                Button(action: {
                                    viewModel.startNavigation()
                                }) {
                                    HStack(spacing: 10) {
                                        Image(systemName: "location.north.fill")
                                            .font(.system(size: 18))
                                        Text("Start Navigation")
                                            .font(.system(size: 16, weight: .semibold))
                                    }
                                    .foregroundColor(.black)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 14)
                                    .background(
                                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                                            .fill(Color.yellowGreen)
                                            .shadow(color: Color.black.opacity(0.1), radius: 5, y: 2)
                                    )
                                    .padding(.horizontal, 20)
                                    .padding(.bottom, 12)
                                }
                                .transition(.scale.combined(with: .opacity))
                            }
                            
                            TurnByTurnNavigationView(
                                route: route,
                                currentStepIndex: viewModel.currentStepIndex,
                                distanceToNextStep: viewModel.distanceToNextStep,
                                isNavigating: viewModel.isNavigating,
                                colorScheme: colorScheme,
                                onClose: {
                                    withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                                        showNavigationPanel = false
                                        viewModel.stopNavigation()
                                    }
                                }
                            )
                            .frame(maxHeight: viewModel.isNavigating ? 350 : 250)
                        }
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                        .padding(.horizontal, 16)
                        .padding(.bottom, 20)
                    } else if let route = viewModel.route {
                        // Original route info card
                        VStack(spacing: 16) {
                            // Context-aware suggestion
                            contextAwareSuggestion(for: route)
                            
                            // Route info
                            HStack(spacing: 30) {
                                // Distance
                                HStack(spacing: 8) {
                                    Image(systemName: "location.north.circle.fill")
                                        .font(.system(size: 20))
                                        .foregroundColor(Color.yellowGreen)
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(formatDistance(route.distance))
                                            .font(.system(size: 18, weight: .bold))
                                            .foregroundColor(primaryText)
                                        Text("Distance")
                                            .font(.system(size: 12))
                                            .foregroundColor(secondaryText)
                                    }
                                }
                                
                                // Time
                                HStack(spacing: 8) {
                                    Image(systemName: "clock.circle.fill")
                                        .font(.system(size: 20))
                                        .foregroundColor(Color.yellowGreen)
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(formatTime(route.expectedTravelTime))
                                            .font(.system(size: 18, weight: .bold))
                                            .foregroundColor(primaryText)
                                        Text("Duration")
                                            .font(.system(size: 12))
                                            .foregroundColor(secondaryText)
                                    }
                                }
                                
                                Spacer()
                            }
                            .padding(.horizontal, 20)
                            
                            // Buttons row
                            HStack(spacing: 12) {
                                // Turn-by-turn navigation button
                                Button(action: {
                                    withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                                        showNavigationPanel = true
                                    }
                                }) {
                                    HStack(spacing: 8) {
                                        Image(systemName: "location.north.line.fill")
                                            .font(.system(size: 16))
                                        Text("Turn-by-Turn")
                                            .font(.system(size: 14, weight: .semibold))
                                    }
                                    .foregroundColor(.white)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 12)
                                    .background(
                                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                                            .fill(Color.appleGreen)
                                    )
                                }
                                
                                // Open in Maps button
                                Button(action: openInMapsApp) {
                                    HStack(spacing: 8) {
                                        Image(systemName: "map.fill")
                                            .font(.system(size: 16))
                                        Text("Open in Maps")
                                            .font(.system(size: 14, weight: .semibold))
                                    }
                                    .foregroundColor(.black)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 12)
                                    .background(
                                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                                            .fill(Color.yellowGreen)
                                    )
                                }
                            }
                            .padding(.horizontal, 20)
                            
                            // End Parking Session button
                            Button(action: {
                                showEndSessionConfirm = true
                            }) {
                                HStack(spacing: 8) {
                                    Image(systemName: "checkmark.circle")
                                        .font(.system(size: 16))
                                    Text("End Parking Session")
                                        .font(.system(size: 15, weight: .medium))
                                }
                                .foregroundColor(colorScheme == .dark ? .white : Color(red: 0.118, green: 0.118, blue: 0.165))
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 14)
                                .background(
                                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                                        .stroke(colorScheme == .dark ? Color.white.opacity(0.2) : Color(red: 0.118, green: 0.118, blue: 0.165).opacity(0.3), lineWidth: 1)
                                        .background(
                                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                                .fill(colorScheme == .dark ? Color.white.opacity(0.05) : Color(red: 0.118, green: 0.118, blue: 0.165).opacity(0.03))
                                        )
                                )
                            }
                            .padding(.horizontal, 20)
                            .padding(.top, 4)
                        }
                        .padding(.vertical, 20)
                        .background(
                            RoundedRectangle(cornerRadius: 24, style: .continuous)
                                .fill(cardBackground)
                                .shadow(color: Color.black.opacity(0.2), radius: 15, y: 8)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 24, style: .continuous)
                                        .stroke(Color.white.opacity(colorScheme == .dark ? 0.05 : 0.1), lineWidth: 1)
                                )
                        )
                        .padding(.horizontal, 16)
                        .padding(.bottom, 20)
                    }
                }
                
                // Error message
                if let errorMessage = viewModel.errorMessage {
                    VStack(spacing: 12) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .font(.system(size: 24))
                            .foregroundColor(.red)
                        Text("Directions Unavailable")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(primaryText)
                        Text(errorMessage)
                            .font(.system(size: 14))
                            .foregroundColor(secondaryText)
                            .multilineTextAlignment(.center)
                        Button(action: { viewModel.getDirections() }) {
                            Text("Try Again")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(.white)
                                .padding(.horizontal, 20)
                                .padding(.vertical, 8)
                                .background(
                                    RoundedRectangle(cornerRadius: 8)
                                        .fill(Color.yellowGreen)
                                )
                        }
                        .padding(.top, 4)
                    }
                    .padding(20)
                    .background(
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .fill(cardBackground)
                            .shadow(color: Color.black.opacity(0.15), radius: 10, y: 5)
                    )
                }
            }
            .navigationTitle("Directions to Car")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbarBackground(
                LinearGradient(
                    gradient: Gradient(colors: [
                        backgroundColor.opacity(0.98),
                        backgroundColor.opacity(0.95)
                    ]),
                    startPoint: .top,
                    endPoint: .bottom
                ),
                for: .navigationBar
            )
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundColor(Color.yellowGreen)
                }
            }
        }
        .onReceive(viewModel.$hasArrivedAtDestination) { hasArrived in
            if hasArrived {
                showArrivalAlert = true
            }
        }
        .alert("You've Arrived!", isPresented: $showArrivalAlert) {
            Button("OK") {
                showNavigationPanel = false
                viewModel.stopNavigation()
            }
        } message: {
            Text("You have reached your parked car. Have a safe journey!")
        }
        .alert("End Parking Session", isPresented: $showEndSessionConfirm) {
            Button("Cancel", role: .cancel) { }
            Button("End Session", role: .destructive) {
                // Call the callback and dismiss
                onEndSession?()
                dismiss()
            }
        } message: {
            Text("This will save your location to history and clear the current parking session.")
        }
    }
    
    private func regionThatFits(coordinate1: CLLocationCoordinate2D, coordinate2: CLLocationCoordinate2D) -> MKCoordinateRegion {
        let minLat = min(coordinate1.latitude, coordinate2.latitude)
        let maxLat = max(coordinate1.latitude, coordinate2.latitude)
        let minLon = min(coordinate1.longitude, coordinate2.longitude)
        let maxLon = max(coordinate1.longitude, coordinate2.longitude)
        
        let center = CLLocationCoordinate2D(
            latitude: (minLat + maxLat) / 2,
            longitude: (minLon + maxLon) / 2
        )
        
        // Calculate the distance to determine appropriate padding
        let latDelta = maxLat - minLat
        let lonDelta = maxLon - minLon
        
        // Dynamic padding based on distance
        // Closer pins need more padding (relatively), farther pins need less
        let paddingMultiplier: Double
        if latDelta < 0.001 && lonDelta < 0.001 {
            // Very close (< 100m approximately)
            paddingMultiplier = 5.0  // Show wider area for context
        } else if latDelta < 0.005 && lonDelta < 0.005 {
            // Close (< 500m approximately)
            paddingMultiplier = 3.0
        } else if latDelta < 0.01 && lonDelta < 0.01 {
            // Medium distance (< 1km approximately)
            paddingMultiplier = 2.0
        } else {
            // Far distance
            paddingMultiplier = 1.5
        }
        
        // Ensure minimum span for visibility and maximum for usability
        let span = MKCoordinateSpan(
            latitudeDelta: min(max(latDelta * paddingMultiplier, 0.003), 0.1),  // Min: ~300m view, Max: ~10km view
            longitudeDelta: min(max(lonDelta * paddingMultiplier, 0.003), 0.1)
        )
        
        return MKCoordinateRegion(center: center, span: span)
    }
    
    private func formatDistance(_ distance: CLLocationDistance) -> String {
        let formatter = MKDistanceFormatter()
        formatter.unitStyle = .abbreviated
        // Use user's locale for automatic metric/imperial conversion
        formatter.locale = Locale.current
        let result = formatter.string(fromDistance: distance)
        // Clean up formatting
        return result.replacingOccurrences(of: "  ", with: " ")
    }
    
    private func formatTime(_ time: TimeInterval) -> String {
        let minutes = Int(time / 60)
        if minutes == 0 {
            return "<1 min"
        } else if minutes < 60 {
            return "\(minutes) min"
        } else {
            let hours = minutes / 60
            let remainingMinutes = minutes % 60
            return "\(hours)h \(remainingMinutes)m"
        }
    }
    
    private func openInMapsApp() {
        let placemark = MKPlacemark(coordinate: destination)
        let mapItem = MKMapItem(placemark: placemark)
        mapItem.name = "Parked Car"
        
        // Smart transport mode based on distance
        let directionsMode: String
        if let route = viewModel.route {
            // Use walking for short distances (< 0.5 miles), driving for longer
            directionsMode = route.distance < 804.67 ? MKLaunchOptionsDirectionsModeWalking : MKLaunchOptionsDirectionsModeDriving
        } else {
            directionsMode = MKLaunchOptionsDirectionsModeDriving
        }
        
        let launchOptions = [MKLaunchOptionsDirectionsModeKey: directionsMode]
        mapItem.openInMaps(launchOptions: launchOptions)
    }
    
    // MARK: - Context-Aware Suggestions
    @ViewBuilder
    private func contextAwareSuggestion(for route: MKRoute) -> some View {
        let suggestion = getContextualSuggestion(for: route)
        
        HStack(spacing: 8) {
            Image(systemName: suggestion.icon)
                .font(.system(size: 16))
                .foregroundColor(Color.yellowGreen)
            
            Text(suggestion.message)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(primaryText)
            
            Spacer()
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 10)
        .background(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(Color.yellowGreen.opacity(0.1))
        )
        .padding(.horizontal, 20)
    }
    
    private func getContextualSuggestion(for route: MKRoute) -> (icon: String, message: String) {
        let distanceInMiles = route.distance * 0.000621371 // Convert meters to miles
        let timeInMinutes = route.expectedTravelTime / 60
        
        if distanceInMiles < 0.1 {
            return ("figure.walk", "Very close! Just a short walk to your car.")
        } else if distanceInMiles < 0.3 {
            return ("figure.walk", "Perfect walking distance - about \(Int(timeInMinutes)) minutes.")
        } else if distanceInMiles < 0.5 {
            return ("figure.walk", "Moderate walk - consider the weather and your energy!")
        } else if distanceInMiles < 2.0 {
            return ("car", "Good driving distance - hop in a rideshare or drive.")
        } else if timeInMinutes > 20 {
            return ("map", "Complex route ahead - navigation recommended.")
        } else {
            return ("car", "Quick drive to your car.")
        }
    }
    
    private func getNavigationIcon(for route: MKRoute) -> String {
        let distanceInMiles = route.distance * 0.000621371
        return distanceInMiles < 0.5 ? "figure.walk" : "car.fill"
    }
    
    private func getNavigationButtonText(for route: MKRoute) -> String {
        let distanceInMiles = route.distance * 0.000621371
        let timeInMinutes = route.expectedTravelTime / 60
        
        if distanceInMiles < 0.5 {
            return "Get Walking Directions"
        } else if timeInMinutes > 15 {
            return "Navigate with Turn-by-Turn"
        } else {
            return "Get Driving Directions"
        }
    }
}

// ViewModel for handling directions and location updates
class DirectionsViewModel: NSObject, ObservableObject {
    @Published var route: MKRoute?
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var userLocation: CLLocationCoordinate2D?
    
    // Navigation state
    @Published var isNavigating = false
    @Published var currentStepIndex = 0
    @Published var distanceToNextStep: CLLocationDistance = 0
    @Published var hasArrivedAtDestination = false
    
    private var fromCoordinate: CLLocationCoordinate2D
    private let toCoordinate: CLLocationCoordinate2D
    private let locationManager = CLLocationManager()
    private var lastRouteUpdateLocation: CLLocationCoordinate2D?
    private let routeUpdateThreshold: CLLocationDistance = 50 // meters
    private let walkingThreshold: CLLocationDistance = 900 // meters; use walking routes for short distances
    
    // Navigation thresholds
    private let stepCompletionThreshold: CLLocationDistance = 30 // meters to consider step completed
    private let arrivalThreshold: CLLocationDistance = 20 // meters to consider arrived at destination
    
    init(from: CLLocationCoordinate2D, to: CLLocationCoordinate2D) {
        self.fromCoordinate = from
        self.toCoordinate = to
        self.userLocation = from
        super.init()
        setupLocationManager()
    }
    
    private func setupLocationManager() {
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBestForNavigation
        locationManager.distanceFilter = 20 // Update every 20 meters to reduce CPU usage
        locationManager.activityType = .automotiveNavigation  // Optimize for driving
    }
    
    func startLocationUpdates() {
        // Check authorization status
        let status = locationManager.authorizationStatus
        if status == .authorizedWhenInUse || status == .authorizedAlways {
            locationManager.startUpdatingLocation()
        }
    }
    
    func stopLocationUpdates() {
        locationManager.stopUpdatingLocation()
    }
    
    func updateRouteIfNeeded(from newLocation: CLLocationCoordinate2D) {
        // Update the from coordinate
        self.fromCoordinate = newLocation
        
        // Check if we need to recalculate the route
        if let lastLocation = lastRouteUpdateLocation {
            let lastCLLocation = CLLocation(latitude: lastLocation.latitude, longitude: lastLocation.longitude)
            let newCLLocation = CLLocation(latitude: newLocation.latitude, longitude: newLocation.longitude)
            let distance = newCLLocation.distance(from: lastCLLocation)
            
            // Only recalculate if user has moved significantly
            if distance > routeUpdateThreshold {
                // Recalculate to get updated distance and time
                getDirections()
                lastRouteUpdateLocation = newLocation
            }
        } else {
            // First route calculation
            lastRouteUpdateLocation = newLocation
        }
    }
    
    func getDirections() {
        isLoading = true
        errorMessage = nil
        
        let request = MKDirections.Request()
        request.source = MKMapItem(placemark: MKPlacemark(coordinate: fromCoordinate))
        request.destination = MKMapItem(placemark: MKPlacemark(coordinate: toCoordinate))
        
        // Choose transport type based on approximate straight-line distance
        let fromLoc = CLLocation(latitude: fromCoordinate.latitude, longitude: fromCoordinate.longitude)
        let toLoc = CLLocation(latitude: toCoordinate.latitude, longitude: toCoordinate.longitude)
        let approxDistance = fromLoc.distance(from: toLoc)
        request.transportType = approxDistance <= walkingThreshold ? .walking : .automobile
        request.requestsAlternateRoutes = true
        request.departureDate = Date() // Use current time for accurate ETA
        
        let directions = MKDirections(request: request)
        directions.calculate { [weak self] response, error in
            DispatchQueue.main.async {
                self?.isLoading = false
                
                if let error = error {
                    self?.errorMessage = "Unable to get directions: \(error.localizedDescription)"
                    return
                }
                
                guard let response = response,
                      let route = response.routes.min(by: { $0.expectedTravelTime < $1.expectedTravelTime }) else {
                    self?.errorMessage = "No route found"
                    return
                }
                
                self?.route = route
                // Reset navigation state when new route is calculated
                self?.currentStepIndex = 0
                self?.hasArrivedAtDestination = false
                if self?.isNavigating == true {
                    self?.updateNavigationProgress()
                }
            }
        }
    }
    
    // MARK: - Navigation Methods
    func startNavigation() {
        guard route != nil else { return }
        isNavigating = true
        currentStepIndex = 0
        hasArrivedAtDestination = false
        updateNavigationProgress()
    }
    
    func stopNavigation() {
        isNavigating = false
    }
    
    private func updateNavigationProgress() {
        guard let route = route,
              let currentLocation = userLocation,
              isNavigating else { return }
        
        // Check if arrived at destination
        let destinationLocation = CLLocation(latitude: toCoordinate.latitude, longitude: toCoordinate.longitude)
        let currentCLLocation = CLLocation(latitude: currentLocation.latitude, longitude: currentLocation.longitude)
        let distanceToDestination = currentCLLocation.distance(from: destinationLocation)
        
        if distanceToDestination < arrivalThreshold {
            hasArrivedAtDestination = true
            isNavigating = false
            return
        }
        
        // Find the current step based on user location
        var closestStepIndex = currentStepIndex
        var minDistance = Double.infinity
        
        // Check current step and next few steps to find the closest one
        for i in max(0, currentStepIndex)...min(route.steps.count - 1, currentStepIndex + 2) {
            let step = route.steps[i]
            if let stepLocation = getStepLocation(step: step, in: route) {
                let stepCLLocation = CLLocation(latitude: stepLocation.latitude, longitude: stepLocation.longitude)
                let distance = currentCLLocation.distance(from: stepCLLocation)
                
                if distance < minDistance {
                    minDistance = distance
                    closestStepIndex = i
                }
            }
        }
        
        // Update current step if we've moved to a new one
        if closestStepIndex > currentStepIndex && minDistance < stepCompletionThreshold {
            currentStepIndex = closestStepIndex
        }
        
        // Calculate distance to next step
        if currentStepIndex < route.steps.count {
            if let nextStepLocation = getStepLocation(step: route.steps[currentStepIndex], in: route) {
                let nextStepCLLocation = CLLocation(latitude: nextStepLocation.latitude, longitude: nextStepLocation.longitude)
                distanceToNextStep = currentCLLocation.distance(from: nextStepCLLocation)
                
                // Auto-advance if very close to current step
                if distanceToNextStep < stepCompletionThreshold && currentStepIndex < route.steps.count - 1 {
                    currentStepIndex += 1
                    // Recalculate distance for new step
                    if let newNextStepLocation = getStepLocation(step: route.steps[currentStepIndex], in: route) {
                        let newNextStepCLLocation = CLLocation(latitude: newNextStepLocation.latitude, longitude: newNextStepLocation.longitude)
                        distanceToNextStep = currentCLLocation.distance(from: newNextStepCLLocation)
                    }
                }
            }
        }
    }
    
    private func getStepLocation(step: MKRoute.Step, in route: MKRoute) -> CLLocationCoordinate2D? {
        // Get the coordinate for the end of this step
        let stepIndex = route.steps.firstIndex(where: { $0 === step }) ?? 0
        
        // Calculate the cumulative distance to this step
        var cumulativeDistance: CLLocationDistance = 0
        for i in 0..<stepIndex {
            cumulativeDistance += route.steps[i].distance
        }
        cumulativeDistance += step.distance
        
        // Find the point on the polyline at this distance
        let points = route.polyline.points()
        let pointCount = route.polyline.pointCount
        
        var accumulatedDistance: CLLocationDistance = 0
        for i in 0..<pointCount - 1 {
            let point1 = points[i]
            let point2 = points[i + 1]
            
            let loc1 = CLLocation(latitude: point1.coordinate.latitude, longitude: point1.coordinate.longitude)
            let loc2 = CLLocation(latitude: point2.coordinate.latitude, longitude: point2.coordinate.longitude)
            let segmentDistance = loc1.distance(from: loc2)
            
            if accumulatedDistance + segmentDistance >= cumulativeDistance {
                // This step ends somewhere in this segment
                return point2.coordinate
            }
            
            accumulatedDistance += segmentDistance
        }
        
        // Default to the last point if we couldn't find it
        if pointCount > 0 {
            return points[pointCount - 1].coordinate
        }
        return nil
    }
}

// MARK: - CLLocationManagerDelegate
extension DirectionsViewModel: CLLocationManagerDelegate {
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        
        // Update published user location
        DispatchQueue.main.async {
            self.userLocation = location.coordinate
            
            // Update navigation progress if navigating
            if self.isNavigating {
                self.updateNavigationProgress()
            }
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        // Silent fail - no need to log in production
    }
}

#Preview {
    DirectionsMapView(
        currentLocation: CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194),
        destination: CLLocationCoordinate2D(latitude: 37.7849, longitude: -122.4094)
    )
}
