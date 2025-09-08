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
    @Environment(\.colorScheme) var colorScheme
    @Environment(\.displayScale) var displayScale
    @State private var cameraPosition: MapCameraPosition = .automatic
    @State private var showClearConfirm: Bool = false
    @State private var showDirectionsModal = false
    @State private var hasInitializedCamera: Bool = false
    
    // Cache values we need
    @State private var savedLocation: ParkingLocation?
    @State private var savedAddress: String?
    @State private var lastKnownCoordinate: CLLocationCoordinate2D?
    @State private var parkingNotes: String = ""
    
    // MARK: - Color System
    var primaryText: Color {
        colorScheme == .dark ? .white : .black
    }

    
    
    var body: some View {
        ZStack {
            // Full Screen Map
            mapView
                .ignoresSafeArea()
        }
        // Top controls overlay
        .overlay(alignment: .topLeading) {
            topBar
                .padding(.top, 50)
        }
        // Bottom overlay
        .safeAreaInset(edge: .bottom, spacing: 0) {
            BottomPanelView(
                parkingNotes: $parkingNotes,
                isTimerRunning: $viewModel.isTimerRunning,
                timerStartDate: viewModel.timerStart,
                accumulatedSeconds: viewModel.accumulatedSeconds,
                savedAddress: viewModel.savedAddress,
                colorScheme: colorScheme,
                onStartTimer: { viewModel.startTimer() },
                onStopTimer: { viewModel.stopTimer() },
                onResetTimer: { viewModel.resetTimer() },
                onShowDirections: { showDirectionsModal = true },
                onEndSession: { showClearConfirm = true }
            )
            
        }
        .navigationBarHidden(true)
        .alert("End Parking Session", isPresented: $showClearConfirm) {
            Button("Cancel", role: .cancel) { }
            Button("End Session", role: .destructive) {
                viewModel.clearAllParkingData()
                dismiss()
            }
        } message: {
            Text("This will save your location to history and clear the current parking session.")
        }
        .onDisappear {
            // Save notes back to viewModel when leaving
            viewModel.parkingNotes = parkingNotes
        }
        .sheet(isPresented: $showDirectionsModal) {
            if let savedLocation = savedLocation,
               let currentLocation = lastKnownCoordinate {
                DirectionsMapView(
                    currentLocation: currentLocation,
                    destination: savedLocation.coordinate
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
        .mapStyle(.standard(elevation: .realistic))
    }
    
    // MARK: - Top Bar
    @ViewBuilder
    private var topBar: some View {
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
    }
    
    
    // MARK: - Helper Methods
    private func setupMapPosition() {
        if let coord = savedLocation?.coordinate ?? viewModel.immediateCoordinate() {
            // Set camera instantly to avoid global animations that can cause flicker
            cameraPosition = .region(
                MKCoordinateRegion(
                    center: coord,
                    span: MKCoordinateSpan(latitudeDelta: 0.005, longitudeDelta: 0.005)
                )
            )
            hasInitializedCamera = true
        }
    }
}
