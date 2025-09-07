//
//  ParkingDetailsView.swift
//  Parkee
//
//  Minimal details screen showing the saved location with a map and actions.
//

import SwiftUI
import MapKit
import PhotosUI
import UIKit

struct ParkingDetailsView: View {
    @ObservedObject var viewModel: ParkingViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var cameraPosition: MapCameraPosition = .automatic
    @State private var tick: Date = Date()
    @State private var showMapBubble: Bool = true
    @State private var showClearConfirm: Bool = false
    @State private var showDirectionsModal = false
    @FocusState private var notesFocused: Bool
    
    enum DetailSection {
        case notes, timer, photo
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Map card
                Group {
                    Map(position: $cameraPosition) {
                        if let saved = viewModel.savedLocation {
                            Annotation("Parked Car", coordinate: saved.coordinate) {
                                Image(systemName: "mappin.circle.fill")
                                    .font(.system(size: 32))
                                    .foregroundStyle(.red)
                                    .shadow(radius: 3)
                            }
                        }
                        UserAnnotation()
                    }
                    .frame(height: 154)
                    .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                    // Bubble label and green marker overlay like the mock
                    .overlay(alignment: .center) {
                        VStack(spacing: 10) {
                            if viewModel.savedLocation != nil {
                                // Bubble with title + address
                                if showMapBubble {
                                    VStack(alignment: .leading, spacing: 3) {
                                        Text("Parked Location")
                                            .font(.footnote)
                                            .foregroundStyle(.black)
                                        Text(viewModel.savedAddress ?? "")
                                            .font(.caption)
                                            .foregroundStyle(.gray)
                                    }
                                    .padding(.vertical, 8)
                                    .padding(.horizontal, 12)
                                    .background(
                                        ZStack(alignment: .bottom) {
                                            RoundedRectangle(cornerRadius: 8, style: .continuous)
                                                .fill(Color.white)
                                            Triangle()
                                                .fill(Color.white)
                                                .frame(width: 16, height: 8)
                                                .offset(y: 8)
                                        }
                                    )
                                }
                                // Green circular marker
                                Button(action: { withAnimation(.easeInOut(duration: 0.2)) { showMapBubble.toggle() } }) {
                                    ZStack {
                                        Circle().fill(Color.green)
                                        Image(systemName: "car.fill")
                                            .foregroundStyle(.white)
                                    }
                                    .frame(width: 56, height: 56)
                                    .shadow(radius: 3)
                                }
                            }
                        }
                    }
                }
                .padding(.horizontal)

                // Info card under the map (address + saved time)
                VStack(alignment: .leading, spacing: 4) {
                    Text("Parked Location")
                        .font(.footnote)
                        .foregroundColor(.secondary)
                    Text(viewModel.savedAddress ?? "Paco-Balindog Road Kidapawan City")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.primary)
                        .fixedSize(horizontal: false, vertical: true)
                    if let when = viewModel.formattedSavedAt() {
                        Text("Saved \(when)")
                            .font(.footnote)
                            .foregroundColor(.secondary)
                    }
                }
                .padding(16)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .fill(.regularMaterial)
                        .shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 1)
                )
                .padding(.horizontal, 16)

                // Add details chips
                HStack(spacing: 8) {
                    DetailChip(title: "Notes", isOn: $viewModel.showNotes) {
                        toggleSection(.notes)
                    }
                    DetailChip(title: "Timer", isOn: $viewModel.showTimer) {
                        toggleSection(.timer)
                    }
                    DetailChip(title: "Photo", isOn: $viewModel.showPhoto) {
                        toggleSection(.photo)
                    }
                    Spacer()
                }
                .padding(.horizontal)
                .contentShape(Rectangle())
                .zIndex(1)

                // Notes
            if viewModel.showNotes {
            VStack(alignment: .leading, spacing: 12) {
                Text("Parking Notes")
                    .font(.system(size: 19.5, weight: .semibold))
                    .foregroundColor(.primary)
                ZStack(alignment: .topLeading) {
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .fill(.regularMaterial)
                    TextEditor(text: $viewModel.parkingNotes)
                        .scrollContentBackground(.hidden)
                        .background(Color.clear)
                        .padding(16)
                        .frame(minHeight: 100)
                        .focused($notesFocused)
                    if viewModel.parkingNotes.isEmpty {
                        Text("Add a note about your parking spot (e.g., Level 2, Section A, near elevator)")
                            .foregroundColor(.secondary)
                            .font(.system(size: 15))
                            .padding(.horizontal, 20)
                            .padding(.vertical, 20)
                            .allowsHitTesting(false)
                    }
                }
                .overlay(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .stroke(Color(.separator).opacity(0.3), lineWidth: 0.5)
                )
            }
            .padding(.horizontal)
            .contentShape(Rectangle())
            .zIndex(2)
            .transition(.opacity.combined(with: .move(edge: .top)))
            }

                // Timer
            if viewModel.showTimer {
            VStack(alignment: .leading, spacing: 12) {
                Text("Parking Timer")
                    .font(.system(size: 19.5, weight: .semibold))
                    .foregroundColor(.primary)
                
                // Timer display container
                VStack(spacing: 20) {
                    // Timer display
                    VStack(spacing: 8) {
                        if viewModel.isTimerRunning || viewModel.accumulatedSeconds > 0 {
                            Text(timeString(viewModel.currentElapsedSeconds(reference: tick)))
                                .monospacedDigit()
                                .font(.system(size: 40, weight: .bold, design: .monospaced))
                                .foregroundStyle(
                                    LinearGradient(
                                        colors: [Color.green, Color.green.opacity(0.8)],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .frame(maxWidth: .infinity, alignment: .center)
                        } else {
                            VStack(spacing: 4) {
                                Image(systemName: "timer")
                                    .font(.system(size: 24))
                                    .foregroundColor(.secondary)
                                Text("No timer set")
                                    .font(.system(size: 16, weight: .medium))
                                    .foregroundColor(.secondary)
                            }
                            .frame(maxWidth: .infinity, alignment: .center)
                            .padding(.vertical, 8)
                        }
                    }
                    .frame(minHeight: 80)
                    .padding(.vertical, 16)
                    .padding(.horizontal, 20)
                    .background(
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .fill(Color(.secondarySystemGroupedBackground))
                            .overlay(
                                RoundedRectangle(cornerRadius: 16, style: .continuous)
                                    .stroke(Color(.separator).opacity(0.2), lineWidth: 0.5)
                            )
                    )
                    
                    // Timer controls
                    HStack(spacing: 12) {
                        // Start/Stop button
                        Button(action: { viewModel.isTimerRunning ? viewModel.stopTimer() : viewModel.startTimer() }) {
                            HStack(spacing: 8) {
                                Image(systemName: viewModel.isTimerRunning ? "stop.fill" : "play.fill")
                                    .font(.system(size: 16, weight: .semibold))
                                Text(viewModel.isTimerRunning ? "Stop Timer" : "Start Timer")
                                    .font(.system(size: 17, weight: .semibold))
                            }
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(
                                RoundedRectangle(cornerRadius: 14, style: .continuous)
                                    .fill(
                                        LinearGradient(
                                            colors: viewModel.isTimerRunning ? 
                                                [Color.red, Color.red.opacity(0.8)] : 
                                                [Color.green, Color.green.opacity(0.8)],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        )
                                    )
                                    .shadow(
                                        color: (viewModel.isTimerRunning ? Color.red : Color.green).opacity(0.3), 
                                        radius: 6, x: 0, y: 3
                                    )
                            )
                        }
                        .buttonStyle(.plain)
                        
                        // Reset button (only show when timer is running or has accumulated time)
                        if viewModel.isTimerRunning || viewModel.accumulatedSeconds > 0 {
                            Button(action: { viewModel.resetTimer() }) {
                                HStack(spacing: 6) {
                                    Image(systemName: "arrow.clockwise")
                                        .font(.system(size: 14, weight: .semibold))
                                    Text("Reset")
                                        .font(.system(size: 16, weight: .semibold))
                                }
                                .foregroundColor(.primary)
                                .frame(minWidth: 80)
                                .padding(.vertical, 16)
                                .padding(.horizontal, 12)
                                .background(
                                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                                        .fill(Color(.tertiarySystemGroupedBackground))
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 14, style: .continuous)
                                                .stroke(Color(.separator).opacity(0.3), lineWidth: 0.5)
                                        )
                                )
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
                .padding(24)
                .background(
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .fill(Color(.systemGroupedBackground))
                        .overlay(
                            RoundedRectangle(cornerRadius: 20, style: .continuous)
                                .stroke(Color(.separator).opacity(0.1), lineWidth: 0.5)
                        )
                        .shadow(
                            color: Color(.systemBackground) == Color.black ? 
                                Color.white.opacity(0.02) : Color.black.opacity(0.04),
                            radius: 8, x: 0, y: 2
                        )
                )
            }
            .padding(.horizontal)
            .contentShape(Rectangle())
            .zIndex(2)
            .transition(.opacity.combined(with: .move(edge: .top)))
            }

                // Photo
            if viewModel.showPhoto {
            VStack(alignment: .leading, spacing: 12) {
                Text("Parking Photo")
                    .font(.system(size: 19.5, weight: .semibold))
                    .foregroundColor(.primary)
                ParkingPhotoRow(viewModel: viewModel)
                    .contentShape(Rectangle())
                    .zIndex(1)
            }
            .padding(.horizontal)
            .transition(.opacity.combined(with: .move(edge: .top)))
            }

            // (actions moved to a fixed bottom inset)

            }
            .padding(.top, 16)
        }
        .safeAreaInset(edge: .bottom) {
            VStack(spacing: 14) {
                Button(action: { showDirectionsModal = true }) {
                    HStack(spacing: 10) {
                        Image(systemName: "arrow.triangle.turn.up.right.circle.fill")
                            .font(.system(size: 18))
                        Text("Directions to Car")
                            .font(.system(size: 18, weight: .semibold))
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 18)
                    .background(
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .fill(.black)
                            .shadow(color: .black.opacity(0.2), radius: 8, x: 0, y: 4)
                    )
                }
                .buttonStyle(.plain)

                Button(action: { showClearConfirm = true }) {
                    HStack(spacing: 10) {
                        Image(systemName: "trash")
                            .font(.system(size: 16))
                        Text("Return to Car")
                            .font(.system(size: 18, weight: .semibold))
                    }
                    .foregroundColor(.red)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 18)
                    .background(
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .fill(.red.opacity(0.1))
                            .overlay(
                                RoundedRectangle(cornerRadius: 16, style: .continuous)
                                    .stroke(.red.opacity(0.2), lineWidth: 0.5)
                            )
                    )
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 16)
            .padding(.top, 12)
            .padding(.bottom, 8)
            .background(.regularMaterial)
        }
        .alert("End parking session?", isPresented: $showClearConfirm) {
            Button("Yes, I'm back", role: .destructive) {
                viewModel.clearAllParkingData()
                dismiss()
            }
            Button("Not yet", role: .cancel) { }
        } message: {
            Text("This will save your parking session to history and clear the current location.")
        }
        .toolbar { // Keyboard toolbar with Done button
            ToolbarItemGroup(placement: .keyboard) {
                Spacer()
                Button("Done") { notesFocused = false }
            }
        }
        .onAppear {
            // Center map on saved location or last known
            if let coord = viewModel.savedLocation?.coordinate ?? viewModel.immediateCoordinate() {
                cameraPosition = .region(
                    MKCoordinateRegion(
                        center: coord,
                        span: MKCoordinateSpan(latitudeDelta: 0.02, longitudeDelta: 0.02)
                    )
                )
            }
        }
        .onReceive(Timer.publish(every: 1, on: .main, in: .common).autoconnect()) { now in
            // Drive UI updates once per second for the timer label
            tick = now
        }
        .navigationTitle("Parked Location")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar(.visible, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        .toolbarBackground(Color(.systemBackground), for: .navigationBar)
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
    
    // MARK: - Accordion Logic
    private func toggleSection(_ section: DetailSection) {
        withAnimation(.easeInOut(duration: 0.3)) {
            switch section {
            case .notes:
                if viewModel.showNotes {
                    // If Notes is already open, close it
                    viewModel.showNotes = false
                } else {
                    // Close other sections and open Notes
                    viewModel.showTimer = false
                    viewModel.showPhoto = false
                    viewModel.showNotes = true
                }
            case .timer:
                if viewModel.showTimer {
                    // If Timer is already open, close it
                    viewModel.showTimer = false
                } else {
                    // Close other sections and open Timer
                    viewModel.showNotes = false
                    viewModel.showPhoto = false
                    viewModel.showTimer = true
                }
            case .photo:
                if viewModel.showPhoto {
                    // If Photo is already open, close it
                    viewModel.showPhoto = false
                } else {
                    // Close other sections and open Photo
                    viewModel.showNotes = false
                    viewModel.showTimer = false
                    viewModel.showPhoto = true
                }
            }
        }
    }
}

private func timeString(_ seconds: TimeInterval) -> String {
    let total = Int(seconds.rounded())
    let hrs = total / 3600
    let mins = (total % 3600) / 60
    let secs = total % 60
    if hrs > 0 {
        return String(format: "%02d:%02d:%02d", hrs, mins, secs)
    }
    return String(format: "%02d:%02d:%02d", 0, mins, secs)
}

// MARK: - Detail chip
struct DetailChip: View {
    let title: String
    @Binding var isOn: Bool
    let action: (() -> Void)?
    
    @Environment(\.colorScheme) private var colorScheme
    
    init(title: String, isOn: Binding<Bool>, action: (() -> Void)? = nil) {
        self.title = title
        self._isOn = isOn
        self.action = action
    }
    
    var body: some View {
        Button(action: {
            if let action = action {
                action()
            } else {
                withAnimation { isOn.toggle() }
            }
        }) {
            Text(title)
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(isOn ? .primary : .secondary)
                .padding(.vertical, 10)
                .padding(.horizontal, 16)
                .background(
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .fill(isOn ? Color(red: 46/255, green: 234/255, blue: 123/255).opacity(colorScheme == .dark ? 0.3 : 0.2) : 
                              (colorScheme == .dark ? Color(.systemGray5) : Color(.systemGray6)))
                        .overlay(
                            RoundedRectangle(cornerRadius: 20, style: .continuous)
                                .stroke(isOn ? Color(red: 46/255, green: 234/255, blue: 123/255).opacity(0.4) : Color.clear, lineWidth: 1)
                        )
                )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Photo Row
struct ParkingPhotoRow: View {
    @ObservedObject var viewModel: ParkingViewModel
    @State private var pickerItem: PhotosPickerItem? = nil
    @State private var thumbnail: Image? = nil
    @State private var hasPhoto: Bool = false
    @State private var showSourceDialog: Bool = false
    @State private var isPhotoPickerPresented: Bool = false
    @State private var isCameraPresented: Bool = false

    var body: some View {
        Group {
            if hasPhoto, let image = thumbnail ?? loadImageFromURL() {
                ZStack(alignment: .topTrailing) {
                    image
                        .resizable()
                        .scaledToFill()
                        .frame(height: 180)
                        .frame(maxWidth: .infinity)
                        .clipped()
                        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                    Button {
                        viewModel.clearPhoto()
                        thumbnail = nil
                        hasPhoto = false
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 22, weight: .semibold))
                            .foregroundColor(.white)
                            .shadow(radius: 3)
                    }
                    .padding(10)
                }
            } else {
                Button(action: { showSourceDialog = true }) {
                    HStack(spacing: 10) {
                        Image(systemName: "camera.fill")
                            .font(.system(size: 18, weight: .semibold))
                        Text("Add Photo")
                            .font(.system(size: 18, weight: .semibold))
                    }
                    .foregroundColor(.primary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 20)
                    .background(
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .fill(.regularMaterial)
                            .overlay(
                                RoundedRectangle(cornerRadius: 16, style: .continuous)
                                    .stroke(Color(.separator).opacity(0.3), lineWidth: 0.5)
                            )
                    )
                }
            }
        }
        .confirmationDialog("Add Photo", isPresented: $showSourceDialog, titleVisibility: .visible) {
            Button("Camera") { isCameraPresented = true }
            Button("Photo Library") { isPhotoPickerPresented = true }
            Button("Cancel", role: .cancel) { }
        }
        .photosPicker(isPresented: $isPhotoPickerPresented, selection: $pickerItem, matching: .images)
        .onChange(of: pickerItem) { _, item in
            guard let item else { return }
            Task {
                if let data = try? await item.loadTransferable(type: Data.self) {
                    viewModel.savePhoto(data: data)
                    if let ui = UIImage(data: data) { thumbnail = Image(uiImage: ui) }
                    hasPhoto = true
                }
            }
        }
        .fullScreenCover(isPresented: $isCameraPresented) {
            if UIImagePickerController.isSourceTypeAvailable(.camera) {
                CameraPicker(isPresented: $isCameraPresented) { uiImage in
                    if let jpeg = uiImage.jpegData(compressionQuality: 0.9) {
                        viewModel.savePhoto(data: jpeg)
                        thumbnail = Image(uiImage: uiImage)
                        hasPhoto = true
                    }
                }
            } else {
                Text("Camera not available")
                    .padding()
            }
        }
        .onAppear {
            hasPhoto = viewModel.photoURL != nil
            if hasPhoto { _ = loadImageFromURL() }
        }
    }

    private func loadImageFromURL() -> Image? {
        guard let url = viewModel.photoURL, let ui = UIImage(contentsOfFile: url.path) else { return nil }
        let img = Image(uiImage: ui)
        if thumbnail == nil { thumbnail = img }
        return img
    }
}

// UIKit camera picker wrapper
struct CameraPicker: UIViewControllerRepresentable {
    @Binding var isPresented: Bool
    var onImagePicked: (UIImage) -> Void

    func makeCoordinator() -> Coordinator { Coordinator(isPresented: $isPresented, onImagePicked: onImagePicked) }

    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.sourceType = .camera
        picker.allowsEditing = false
        picker.delegate = context.coordinator
        return picker
    }

    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}

    final class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        @Binding var isPresented: Bool
        let onImagePicked: (UIImage) -> Void
        init(isPresented: Binding<Bool>, onImagePicked: @escaping (UIImage) -> Void) {
            _isPresented = isPresented
            self.onImagePicked = onImagePicked
        }
        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
            if let image = info[.originalImage] as? UIImage {
                onImagePicked(image)
            }
            picker.dismiss(animated: true) { self.isPresented = false }
        }
        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            picker.dismiss(animated: true) { self.isPresented = false }
        }
    }
}


