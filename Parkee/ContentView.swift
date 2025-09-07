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
    @StateObject private var viewModel = ParkingViewModel()
    @State private var cameraPosition: MapCameraPosition = .automatic
    @State private var showParkFirstAlert = false
    @State private var showDirectionsModal = false

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
        NavigationStack {
        ZStack(alignment: .bottom) {
            // Fullscreen map showing user's current location and saved pin if any
            Map(position: $cameraPosition, interactionModes: [.all]) {
                // Show the blue dot for user's location
                UserAnnotation()
                if let saved = viewModel.savedLocation {
                    Annotation("Parked Car", coordinate: saved.coordinate) {
                        Image(systemName: "mappin.circle.fill")
                            .font(.system(size: 32))
                            .foregroundStyle(.red)
                            .shadow(radius: 3)
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
                withAnimation(.easeInOut(duration: 0.35)) {
                    cameraPosition = .region(
                        MKCoordinateRegion(
                            center: coord,
                            span: MKCoordinateSpan(latitudeDelta: 0.02, longitudeDelta: 0.02)
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
                        .foregroundStyle(Color(red: 46/255, green: 234/255, blue: 123/255))
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
                NavigationLink(value: "details", label: {
                    HStack(spacing: 10) {
                        Image(systemName: "p.circle.fill")
                            .font(.title2)
                        Text(viewModel.isSaving ? "Saving…" : (viewModel.savedLocation != nil ? "View Parking Details" : "Park My Car"))
                            .font(.system(size: 20, weight: .semibold))
                    }
                    .foregroundColor(.black)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 18)
                    .background(Color.green)
                    .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
                })
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
                    .background(Color.black.opacity(0.35))
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
            if route == "details" {
                // Trigger save before navigating content displays
                ParkingDetailsView(viewModel: viewModel)
                    .onAppear {
                        if viewModel.savedLocation == nil {
                            viewModel.saveCurrentLocation()
                        }
                    }
            } else if route == "settings" {
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
            }
        }
        }
    }
}

#Preview {
    ContentView()
}
