//
//  ParkingDetailsSheet.swift
//  Parkee
//
//  Modal sheet view for parking details
//

import SwiftUI

struct ParkingDetailsSheet: View {
    // Data bindings
    @Binding var parkingNotes: String
    let isTimerRunning: Bool
    let timerStartDate: Date?
    let accumulatedSeconds: TimeInterval
    let savedAddress: String?
    let colorScheme: ColorScheme
    
    // Actions
    let onStartTimer: () -> Void
    let onStopTimer: () -> Void
    let onResetTimer: () -> Void
    let onShowDirections: () -> Void
    let onEndSession: () -> Void
    
    @State private var expandedNotes: Bool = false
    @State private var expandedTimer: Bool = false
    @FocusState private var notesFocused: Bool
    @Environment(\.dismiss) private var dismiss
    
    // MARK: - Color System
    var backgroundColor: Color {
        colorScheme == .dark ? Color(red: 0.118, green: 0.118, blue: 0.165) : Color(UIColor.systemGray6)
    }
    
    var cardBackground: Color {
        colorScheme == .dark ? Color(red: 0.176, green: 0.176, blue: 0.208) : .white
    }
    
    var primaryText: Color {
        colorScheme == .dark ? .white : Color(red: 0.118, green: 0.118, blue: 0.165) // Raisin Black for light mode
    }
    
    var secondaryText: Color {
        colorScheme == .dark ? Color.white.opacity(0.5) : Color(red: 0.3, green: 0.3, blue: 0.35)
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 16) {
                    // Address Section
                    if let address = savedAddress {
                        VStack(alignment: .leading, spacing: 8) {
                            Label("Parking Location", systemImage: "mappin.circle.fill")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(secondaryText)
                            
                            Text(address)
                                .font(.system(size: 18, weight: .semibold))
                                .foregroundColor(primaryText)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(20)
                        .background(
                            RoundedRectangle(cornerRadius: 16, style: .continuous)
                                .fill(cardBackground)
                        )
                    }
                    
                    // Notes Section
                    notesSection
                    
                    // Timer Section
                    timerSection
                    
                    // Action Buttons
                    VStack(spacing: 12) {
                        // Directions Button
                        Button(action: {
                            dismiss()
                            onShowDirections()
                        }) {
                            HStack(spacing: 10) {
                                Image(systemName: "location.north.circle.fill")
                                    .font(.system(size: 20))
                                Text("Directions to Car")
                                    .font(.system(size: 17, weight: .semibold))
                            }
                            .foregroundColor(.black)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(
                                RoundedRectangle(cornerRadius: 16, style: .continuous)
                                    .fill(Color.yellowGreen)
                                    .shadow(color: Color.black.opacity(0.1), radius: 3, y: 2)
                            )
                        }
                        .buttonStyle(PlainButtonStyle())
                        
                        // End Session Button
                        Button(action: {
                            dismiss()
                            onEndSession()
                        }) {
                            Text("End Parking Session")
                                .font(.system(size: 17, weight: .medium))
                                .foregroundColor(colorScheme == .dark ? .white : Color(red: 0.118, green: 0.118, blue: 0.165))
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 16)
                                .background(
                                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                                        .stroke(colorScheme == .dark ? Color.white.opacity(0.25) : Color(red: 0.118, green: 0.118, blue: 0.165).opacity(0.3), lineWidth: 1)
                                        .background(
                                            RoundedRectangle(cornerRadius: 16, style: .continuous)
                                                .fill(colorScheme == .dark ? Color.white.opacity(0.06) : Color(red: 0.118, green: 0.118, blue: 0.165).opacity(0.05))
                                        )
                                )
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                    .padding(.top, 10)
                }
                .padding(20)
                .padding(.bottom, 40)  // Add significant bottom padding inside the content
            }
            .background(backgroundColor.ignoresSafeArea())
            .navigationTitle("Parking Details")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundColor(colorScheme == .dark ? Color.yellowGreen : Color(red: 0.118, green: 0.118, blue: 0.165))
                }
            }
        }
        .onAppear {
            // Always start with notes section closed
            expandedNotes = false
            expandedTimer = false
            notesFocused = false
        }
    }
    
    // MARK: - Notes Section
    @ViewBuilder
    private var notesSection: some View {
        VStack(spacing: 0) {
            // Header
            Button(action: {
                withAnimation(.easeInOut(duration: 0.25)) {
                    expandedNotes.toggle()
                    if expandedNotes {
                        notesFocused = true
                        // Auto-collapse timer section when notes is expanded
                        expandedTimer = false
                    } else {
                        notesFocused = false
                    }
                }
            }) {
                HStack {
                    Label("Parking Notes", systemImage: "note.text")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(secondaryText)
                    
                    Spacer()
                    
                    if !expandedNotes && !parkingNotes.isEmpty {
                        Text(parkingNotes)
                            .font(.system(size: 14))
                            .foregroundColor(secondaryText)
                            .lineLimit(1)
                            .truncationMode(.tail)
                            .frame(maxWidth: 150, alignment: .trailing)
                    }
                    
                    Image(systemName: expandedNotes ? "chevron.up" : "chevron.down")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(colorScheme == .dark ? Color.yellowGreen : Color(red: 0.118, green: 0.118, blue: 0.165))
                        .padding(.leading, 8)
                }
                .padding(20)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            
            // Expanded Content
            if expandedNotes {
                ZStack(alignment: .topLeading) {
                    if parkingNotes.isEmpty {
                        Text("e.g., Level 3, Section B")
                            .foregroundColor(secondaryText.opacity(0.5))
                            .padding(.horizontal, 20)
                            .padding(.vertical, 12)
                    }
                    
                    TextEditor(text: $parkingNotes)
                        .scrollContentBackground(.hidden)
                        .background(Color.clear)
                        .foregroundColor(primaryText)
                        .tint(Color.yellowGreen)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .frame(minHeight: 80, maxHeight: 150)
                        .focused($notesFocused)
                }
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(cardBackground)
        )
    }
    
    // MARK: - Timer Section
    @ViewBuilder
    private var timerSection: some View {
        VStack(spacing: 0) {
            // Header
            Button(action: {
                withAnimation(.easeInOut(duration: 0.25)) {
                    expandedTimer.toggle()
                    if expandedTimer {
                        // Auto-collapse notes section when timer is expanded
                        expandedNotes = false
                        notesFocused = false
                    }
                }
            }) {
                HStack {
                    HStack(spacing: 8) {
                        if isTimerRunning {
                            Circle()
                                .fill(Color.yellowGreen)
                                .frame(width: 8, height: 8)
                        }
                        
                        Label("Parking Timer", systemImage: "timer")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(isTimerRunning ? Color.yellowGreen : secondaryText)
                    }
                    
                    Spacer()
                    
                    // Isolated timer view to prevent parent re-renders
                    TimerDisplayView(
                        isRunning: isTimerRunning,
                        startDate: timerStartDate,
                        accumulatedSeconds: accumulatedSeconds,
                        textColor: isTimerRunning ? Color.yellowGreen : primaryText
                    )
                    
                    Image(systemName: expandedTimer ? "chevron.up" : "chevron.down")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(colorScheme == .dark ? Color.yellowGreen : Color(red: 0.118, green: 0.118, blue: 0.165))
                        .padding(.leading, 8)
                }
                .padding(20)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            
            // Expanded Content
            if expandedTimer {
                HStack(spacing: 12) {
                    Button(action: {
                        if isTimerRunning {
                            onStopTimer()
                        } else {
                            onStartTimer()
                        }
                    }) {
                        Label(
                            isTimerRunning ? "Pause" : "Start",
                            systemImage: isTimerRunning ? "pause.fill" : "play.fill"
                        )
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(isTimerRunning ? .black : (colorScheme == .dark ? .white : Color(red: 0.118, green: 0.118, blue: 0.165)))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(
                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                .fill(isTimerRunning ? Color.yellowGreen : (colorScheme == .dark ? Color.white.opacity(0.1) : Color(red: 0.118, green: 0.118, blue: 0.165).opacity(0.08)))
                        )
                    }
                    
                    Button(action: onResetTimer) {
                        Label("Reset", systemImage: "arrow.clockwise")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(colorScheme == .dark ? .red : Color(red: 0.8, green: 0.2, blue: 0.2))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 10)
                            .background(
                                RoundedRectangle(cornerRadius: 12, style: .continuous)
                                    .fill(colorScheme == .dark ? Color.red.opacity(0.15) : Color(red: 0.8, green: 0.2, blue: 0.2).opacity(0.12))
                            )
                    }
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 16)
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(cardBackground)
        )
    }
    
    private func elapsedTimeString(reference: Date) -> String {
        let seconds = currentElapsedSeconds(reference: reference)
        let total = Int(seconds.rounded())
        let hrs = total / 3600
        let mins = (total % 3600) / 60
        let secs = total % 60
        
        if hrs > 0 {
            return String(format: "%02d:%02d:%02d", hrs, mins, secs)
        }
        return String(format: "%02d:%02d", mins, secs)
    }
    
    private func currentElapsedSeconds(reference: Date) -> TimeInterval {
        if isTimerRunning, let start = timerStartDate {
            return accumulatedSeconds + reference.timeIntervalSince(start)
        }
        return accumulatedSeconds
    }
}

// Isolated timer display to prevent parent view re-renders
struct TimerDisplayView: View {
    let isRunning: Bool
    let startDate: Date?
    let accumulatedSeconds: TimeInterval
    let textColor: Color
    
    var body: some View {
        if isRunning {
            TimelineView(.periodic(from: .now, by: 1)) { timeline in
                Text(elapsedTimeString(reference: timeline.date))
                    .font(.system(size: 16, weight: .bold, design: .monospaced))
                    .foregroundColor(textColor)
            }
        } else {
            Text(elapsedTimeString(reference: Date()))
                .font(.system(size: 16, weight: .bold, design: .monospaced))
                .foregroundColor(textColor)
        }
    }
    
    private func elapsedTimeString(reference: Date) -> String {
        let seconds = currentElapsedSeconds(reference: reference)
        let total = Int(seconds.rounded())
        let hrs = total / 3600
        let mins = (total % 3600) / 60
        let secs = total % 60
        
        if hrs > 0 {
            return String(format: "%02d:%02d:%02d", hrs, mins, secs)
        }
        return String(format: "%02d:%02d", mins, secs)
    }
    
    private func currentElapsedSeconds(reference: Date) -> TimeInterval {
        if isRunning, let start = startDate {
            return accumulatedSeconds + reference.timeIntervalSince(start)
        }
        return accumulatedSeconds
    }
}
