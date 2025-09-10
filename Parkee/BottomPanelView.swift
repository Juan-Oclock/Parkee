//
//  BottomPanelView.swift
//  Parkee
//
//  Isolated bottom panel to prevent flickering from ViewModel updates
//

import SwiftUI

struct BottomPanelView: View, Equatable {
    // Only the specific data we need - not the whole ViewModel
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
    
    // MARK: - Color System
    var backgroundColor: Color {
        colorScheme == .dark ? Color.black : Color.white
    }
    
    var cardBackground: Color {
        colorScheme == .dark ? Color(red: 0.11, green: 0.11, blue: 0.12) : Color(UIColor.systemGray6)
    }
    
    var primaryText: Color {
        colorScheme == .dark ? .white : .black
    }
    
    var secondaryText: Color {
        colorScheme == .dark ? Color.white.opacity(0.5) : Color.black.opacity(0.5)
    }
    
    var body: some View {
        ZStack(alignment: .bottom) {
            // Gradient
            LinearGradient(
                colors: [Color.clear, backgroundColor.opacity(0.8), backgroundColor],
                startPoint: .top,
                endPoint: .bottom
            )
            .frame(height: 400) // Increased height
            .ignoresSafeArea()
            .allowsHitTesting(false)

            // Content
            VStack(spacing: 0) {
                // Sections Container
                VStack(spacing: 1) {
                    notesSection
                    timerSection
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 20)

                // Action Buttons
                VStack(spacing: 12) {
                    // Directions Button
                    Button(action: {
                        // Dismiss keyboard first, then show directions
                        if notesFocused {
                            notesFocused = false
                        }
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
                        )
                    }
                    .buttonStyle(PlainButtonStyle())

                    // End Session Button
                    Button(action: {
                        // Dismiss keyboard first, then end session
                        if notesFocused {
                            notesFocused = false
                        }
                        onEndSession()
                    }) {
                        Text("End Parking Session")
                            .font(.system(size: 17, weight: .medium))
                            .foregroundColor(colorScheme == .dark ? Color.yellowGreen : .red)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 40) // Reduced padding
            }
            .padding(.top, 20)
            .background(
                backgroundColor
                    .ignoresSafeArea()
                    .contentShape(Rectangle())
                    .onTapGesture {
                        // Dismiss keyboard when tapping the background
                        if notesFocused {
                            notesFocused = false
                        }
                    }
            )
        }
        .onAppear {
            // Auto-expand notes if they exist without animation
            if !parkingNotes.isEmpty {
                expandedNotes = true
            }
        }
        
        .onChange(of: notesFocused) { _, isFocused in
            if !isFocused {
                // Auto-collapse notes section when focus is lost
                withAnimation(.easeInOut(duration: 0.25)) {
                    expandedNotes = false
                }
            }
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
                }
            }) {
                HStack {
                    Text("Parking Notes")
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
                        .foregroundColor(colorScheme == .dark ? Color.yellowGreen : primaryText)
                        .padding(.leading, 8)
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 16)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)

            // Expanded Content
            VStack(alignment: .leading, spacing: 0) {
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
                            .tint(Color.yellowGreen) // Cursor color
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .frame(minHeight: 60, maxHeight: 120)
                            .focused($notesFocused)
                            .environment(\.colorScheme, colorScheme) // Ensure proper theming
                            .toolbar {
                                ToolbarItemGroup(placement: .keyboard) {
                                    Spacer()
                                    Button("Done") {
                                        notesFocused = false
                                    }
                                }
                            }
                    }
                }
            }
            .frame(maxHeight: expandedNotes ? 120 : 0)
            .clipped()
        }
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(cardBackground)
        )
        .padding(.top, 16)
        .onChange(of: expandedNotes) { _, isExpanded in
            if isExpanded {
                // Auto-focus when expanded
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    notesFocused = true
                }
            } else {
                // Remove focus when collapsed
                notesFocused = false
            }
        }
    }
    
    // MARK: - Timer Section
    @ViewBuilder
    private var timerSection: some View {
        VStack(spacing: 0) {
            // Header
            Button(action: {
                withAnimation(.easeInOut(duration: 0.25)) {
                    expandedTimer.toggle()
                }
            }) {
                HStack {
                    HStack(spacing: 8) {
                        if isTimerRunning {
                            Circle()
                                .fill(Color.yellowGreen)
                                .frame(width: 8, height: 8)
                        }
                        
                        Text("Parking Timer")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(isTimerRunning ? Color.yellowGreen : secondaryText)
                    }
                    
                    Spacer()
                    
                    if isTimerRunning {
                        TimelineView(.periodic(from: .now, by: 1)) { timeline in
                            Text(elapsedTimeString(reference: timeline.date))
                                .font(.system(size: 16, weight: .bold, design: .monospaced))
                                .foregroundColor(Color.yellowGreen)
                        }
                    } else {
                        Text(elapsedTimeString(reference: Date()))
                            .font(.system(size: 16, weight: .bold, design: .monospaced))
                            .foregroundColor(primaryText)
                    }
                    
                    Image(systemName: expandedTimer ? "chevron.up" : "chevron.down")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(colorScheme == .dark ? Color.yellowGreen : primaryText)
                        .padding(.leading, 8)
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 16)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            
            // Expanded Content
            VStack(spacing: 12) {
                if expandedTimer {
                    // Timer Controls
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
                            .foregroundColor(isTimerRunning ? .black : primaryText)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 10)
                            .background(
                                RoundedRectangle(cornerRadius: 12, style: .continuous)
                                    .fill(isTimerRunning ? Color.yellowGreen : Color.white.opacity(0.1))
                            )
                        }
                        
                        Button(action: onResetTimer) {
                            Label("Reset", systemImage: "arrow.clockwise")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(.red)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 10)
                                .background(
                                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                                        .fill(Color.red.opacity(0.15))
                                )
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 16)
                }
            }
            .frame(maxHeight: expandedTimer ? 100 : 0)
            .clipped()
        }
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(cardBackground)
        )
        .padding(.top, 16)
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
    
    

    // Equatable conformance to prevent unnecessary updates
    static func == (lhs: BottomPanelView, rhs: BottomPanelView) -> Bool {
        lhs.parkingNotes == rhs.parkingNotes &&
        lhs.isTimerRunning == rhs.isTimerRunning &&
        lhs.timerStartDate == rhs.timerStartDate &&
        lhs.accumulatedSeconds == rhs.accumulatedSeconds &&
        lhs.savedAddress == rhs.savedAddress &&
        lhs.colorScheme == rhs.colorScheme
    }
}
