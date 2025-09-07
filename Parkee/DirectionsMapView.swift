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
    
    var body: some View {
        ZStack {
                Map(position: $cameraPosition) {
                    // Current location marker
                    Annotation("Your Location", coordinate: currentLocation) {
                        Image(systemName: "location.fill")
                            .font(.system(size: 20))
                            .foregroundStyle(.blue)
                            .background(Circle().fill(.white))
                    }
                    
                    // Parked car marker
                    Annotation("Parked Car", coordinate: destination) {
                        Image(systemName: "car.fill")
                            .font(.system(size: 24))
                            .foregroundStyle(.red)
                            .background(Circle().fill(.white))
                    }
                    
                    // Show route if available
                    if let route = viewModel.route {
                        MapPolyline(route.polyline)
                            .stroke(.blue, lineWidth: 5)
                    }
                }
                .mapStyle(.standard)
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
                    VStack {
                        ProgressView()
                            .scaleEffect(1.2)
                        Text("Getting directions...")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .padding(.top, 8)
                    }
                    .padding()
                    .background(.regularMaterial)
                    .cornerRadius(12)
                }
                
                // Distance and time info
                if let route = viewModel.route {
                    VStack {
                        Spacer()
                        VStack(spacing: 8) {
                            HStack {
                                Image(systemName: "location.north.fill")
                                    .foregroundColor(.blue)
                                Text(formatDistance(route.distance))
                                    .font(.headline)
                                
                                Spacer()
                                
                                Image(systemName: "clock.fill")
                                    .foregroundColor(.blue)
                                Text(formatTime(route.expectedTravelTime))
                                    .font(.headline)
                            }
                            
                            Button("Open in Maps App") {
                                openInMapsApp()
                            }
                            .font(.subheadline)
                            .foregroundColor(.blue)
                        }
                        .padding()
                        .background(.regularMaterial)
                        .cornerRadius(12)
                        .padding(.horizontal)
                        .padding(.bottom, 20)
                    }
                }
                
                // Error message
                if let errorMessage = viewModel.errorMessage {
                    VStack {
                        Text("Directions Unavailable")
                            .font(.headline)
                        Text(errorMessage)
                            .font(.caption)
                            .multilineTextAlignment(.center)
                        Button("Try Again") {
                            viewModel.getDirections()
                        }
                        .padding(.top, 8)
                    }
                    .padding()
                    .background(.regularMaterial)
                    .cornerRadius(12)
                }
            }
            .overlay(alignment: .top) {
                // Custom header with title and close button
                HStack {
                    Text("Directions to Car")
                        .font(.headline)
                        .fontWeight(.semibold)
                    Spacer()
                    Button("Done") {
                        dismiss()
                    }
                    .font(.body)
                    .fontWeight(.medium)
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 16)
                .background(.regularMaterial)
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                .padding(.top, 8)
                .padding(.horizontal, 16)
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
            latitudeDelta: (maxLat - minLat) * 1.3, // Add some padding
            longitudeDelta: (maxLon - minLon) * 1.3
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
        
        let launchOptions = [MKLaunchOptionsDirectionsModeKey: MKLaunchOptionsDirectionsModeDriving]
        mapItem.openInMaps(launchOptions: launchOptions)
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
