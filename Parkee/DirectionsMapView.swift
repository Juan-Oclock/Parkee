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
    let currentLocation: CLLocationCoordinate2D
    let destination: CLLocationCoordinate2D
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) var colorScheme
    @StateObject private var viewModel: DirectionsViewModel
    @State private var cameraPosition: MapCameraPosition = .automatic
    
    init(currentLocation: CLLocationCoordinate2D, destination: CLLocationCoordinate2D) {
        self.currentLocation = currentLocation
        self.destination = destination
        self._viewModel = StateObject(wrappedValue: DirectionsViewModel(
            from: currentLocation,
            to: destination
        ))
    }
    
    // MARK: - Color System
    var backgroundColor: Color {
        colorScheme == .dark ? Color(red: 0.118, green: 0.118, blue: 0.165) : Color.white
    }
    
    var cardBackground: Color {
        colorScheme == .dark ? Color(red: 0.176, green: 0.176, blue: 0.208) : Color(UIColor.systemGray6)
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
                // Background color
                backgroundColor.ignoresSafeArea()
                
                Map(position: $cameraPosition) {
                    // Current location marker
                    Annotation("Your Location", coordinate: currentLocation) {
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
                .clipShape(RoundedRectangle(cornerRadius: 20))
                .padding(.horizontal, 16)
                .padding(.top, 10)  // Reduced from 70 to give map more height
                .padding(.bottom, 100)
                .onAppear {
                    // Set initial camera position to show both points
                    let region = regionThatFits(
                        coordinate1: currentLocation,
                        coordinate2: destination
                    )
                    cameraPosition = .region(region)
                    
                    // Request directions
                    viewModel.getDirections()
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
                    )
                }
                
                // Distance and time info bottom card
                VStack {
                    Spacer()
                    
                    if let route = viewModel.route {
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
                            
                            // Smart Open in Maps button with context
                            Button(action: openInMapsApp) {
                                HStack(spacing: 10) {
                                    Image(systemName: getNavigationIcon(for: route))
                                        .font(.system(size: 18))
                                    Text(getNavigationButtonText(for: route))
                                        .font(.system(size: 16, weight: .semibold))
                                }
                                .foregroundColor(.black)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 14)
                                .background(
                                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                                        .fill(Color.yellowGreen)
                                )
                            }
                            .padding(.horizontal, 20)
                        }
                        .padding(.vertical, 20)
                        .background(
                            RoundedRectangle(cornerRadius: 20, style: .continuous)
                                .fill(cardBackground)
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
                    )
                }
            }
            .navigationTitle("Directions to Car")
            .navigationBarTitleDisplayMode(.inline)
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
        
        let span = MKCoordinateSpan(
            latitudeDelta: max((maxLat - minLat) * 1.8, 0.01), // More padding for better overview
            longitudeDelta: max((maxLon - minLon) * 1.8, 0.01)
        )
        
        return MKCoordinateRegion(center: center, span: span)
    }
    
    private func formatDistance(_ distance: CLLocationDistance) -> String {
        let formatter = MKDistanceFormatter()
        formatter.unitStyle = .abbreviated
        return formatter.string(fromDistance: distance)
    }
    
    private func formatTime(_ time: TimeInterval) -> String {
        let minutes = Int(time / 60)
        if minutes < 60 {
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

// ViewModel for handling directions
class DirectionsViewModel: ObservableObject {
    @Published var route: MKRoute?
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private let fromCoordinate: CLLocationCoordinate2D
    private let toCoordinate: CLLocationCoordinate2D
    
    init(from: CLLocationCoordinate2D, to: CLLocationCoordinate2D) {
        self.fromCoordinate = from
        self.toCoordinate = to
    }
    
    func getDirections() {
        isLoading = true
        errorMessage = nil
        
        let request = MKDirections.Request()
        request.source = MKMapItem(placemark: MKPlacemark(coordinate: fromCoordinate))
        request.destination = MKMapItem(placemark: MKPlacemark(coordinate: toCoordinate))
        request.transportType = .automobile
        
        let directions = MKDirections(request: request)
        directions.calculate { [weak self] response, error in
            DispatchQueue.main.async {
                self?.isLoading = false
                
                if let error = error {
                    self?.errorMessage = "Unable to get directions: \(error.localizedDescription)"
                    return
                }
                
                guard let response = response,
                      let route = response.routes.first else {
                    self?.errorMessage = "No route found"
                    return
                }
                
                self?.route = route
            }
        }
    }
}

#Preview {
    DirectionsMapView(
        currentLocation: CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194),
        destination: CLLocationCoordinate2D(latitude: 37.7849, longitude: -122.4094)
    )
}
