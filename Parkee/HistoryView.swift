import SwiftUI
import MapKit

struct HistoryView: View {
    @ObservedObject var viewModel: ParkingViewModel
    @State private var expandedItems: Set<UUID> = []
    @State private var showingClearConfirmation = false
    @Environment(\.colorScheme) var colorScheme
    
    var backgroundColor: Color {
        colorScheme == .dark ? Color.raisinBlack : Color(UIColor.systemGray6)
    }
    
    var cardBackgroundColor: Color {
        colorScheme == .dark ? Color.darkCard : Color.white
    }
    
    var textColor: Color {
        colorScheme == .dark ? Color.white : Color.black
    }
    
    var secondaryTextColor: Color {
        colorScheme == .dark ? Color.white.opacity(0.7) : Color.black.opacity(0.6)
    }
    
    var body: some View {
        ZStack {
            // Clean solid background
            backgroundColor
                .ignoresSafeArea()
            
            if viewModel.history.isEmpty {
                // Empty state
                VStack(spacing: 20) {
                    Image(systemName: "clock.arrow.circlepath")
                        .font(.system(size: 56))
                        .foregroundColor(secondaryTextColor)
                    
                    Text("No parking history yet")
                        .font(.system(size: 24, weight: .semibold))
                        .foregroundColor(textColor)
                    
                    Text("Your past parking sessions will appear here")
                        .font(.system(size: 17))
                        .foregroundColor(secondaryTextColor)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 40)
                }
            } else {
                ScrollView {
                    LazyVStack(spacing: 12) {
                        ForEach(viewModel.history) { record in
                            SwipeToDeleteCardView(
                                record: record,
                                isExpanded: expandedItems.contains(record.id),
                                colorScheme: colorScheme,
                                cardBackgroundColor: cardBackgroundColor,
                                onToggle: {
                                    withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                                        if expandedItems.contains(record.id) {
                                            expandedItems.remove(record.id)
                                        } else {
                                            expandedItems.insert(record.id)
                                        }
                                    }
                                },
                                onDelete: {
                                    withAnimation(.easeInOut(duration: 0.3)) {
                                        // Remove from expanded items if it's currently expanded
                                        expandedItems.remove(record.id)
                                        // Delete from view model
                                        viewModel.deleteHistoryItem(withId: record.id)
                                        
                                        // Trigger haptic feedback
                                        if viewModel.isHapticsEnabled {
                                            let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
                                            impactFeedback.impactOccurred()
                                        }
                                    }
                                }
                            )
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 20)
                    .padding(.bottom, 20)
                }
            }
        }
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                if !viewModel.history.isEmpty {
                    Button(action: { showingClearConfirmation = true }) {
                        Text("Clear")
                            .font(.system(size: 17))
                            .foregroundColor(Color.yellowGreen)
                    }
                }
            }
        }
        .navigationTitle("")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(backgroundColor, for: .navigationBar)
        .toolbarColorScheme(colorScheme == .dark ? .dark : .light, for: .navigationBar)
        .alert("Clear All History", isPresented: $showingClearConfirmation) {
            Button("Cancel", role: .cancel) { }
            Button("Clear", role: .destructive) {
                withAnimation(.easeInOut(duration: 0.3)) {
                    viewModel.clearHistory()
                }
                
                // Trigger haptic feedback
                if viewModel.isHapticsEnabled {
                    let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
                    impactFeedback.impactOccurred()
                }
            }
        } message: {
            Text("This will permanently delete all your parking history. This action cannot be undone.")
        }
    }
}

struct HistoryItemView: View {
    let record: ParkingRecord
    let isExpanded: Bool
    let colorScheme: ColorScheme
    let onToggle: () -> Void
    
    var textColor: Color {
        colorScheme == .dark ? Color.white : Color.black
    }
    
    var secondaryTextColor: Color {
        colorScheme == .dark ? Color.white.opacity(0.7) : Color.black.opacity(0.6)
    }
    
    var dividerColor: Color {
        colorScheme == .dark ? Color.white.opacity(0.1) : Color.black.opacity(0.08)
    }
    
    private func formatTimer(_ seconds: TimeInterval) -> String {
        let hours = Int(seconds) / 3600
        let minutes = Int(seconds.truncatingRemainder(dividingBy: 3600)) / 60
        let secs = Int(seconds.truncatingRemainder(dividingBy: 60))
        
        if hours > 0 {
            return String(format: "%dh %02dm %02ds", hours, minutes, secs)
        } else {
            return String(format: "%02dm %02ds", minutes, secs)
        }
    }
    
    private var hasAdditionalData: Bool {
        record.notes != nil || record.timerSeconds != nil || record.hasPhoto
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Main content
            HStack(alignment: .center) {
                VStack(alignment: .leading, spacing: 6) {
                    // Location name or fallback to coordinates
                    Text(record.locationName ?? String(format: "%.5f, %.5f", record.latitude, record.longitude))
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundColor(textColor)
                        .lineLimit(2)
                    
                    // Date and time
                    HStack(spacing: 4) {
                        Image(systemName: "calendar")
                            .font(.system(size: 12))
                            .foregroundColor(secondaryTextColor)
                        Text(record.savedAt, style: .date)
                            .font(.system(size: 14))
                            .foregroundColor(secondaryTextColor)
                        Text("•")
                            .foregroundColor(secondaryTextColor)
                        Image(systemName: "clock")
                            .font(.system(size: 12))
                            .foregroundColor(secondaryTextColor)
                        Text(record.savedAt, style: .time)
                            .font(.system(size: 14))
                            .foregroundColor(secondaryTextColor)
                    }
                    
                    // Indicator chips for available data
                    if hasAdditionalData {
                        HStack(spacing: 6) {
                            if record.notes != nil {
                                HStack(spacing: 3) {
                                    Image(systemName: "note.text")
                                        .font(.system(size: 10))
                                    Text("Notes")
                                        .font(.system(size: 12, weight: .medium))
                                }
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(Color.appleGreen.opacity(0.2))
                                .foregroundColor(Color.appleGreen)
                                .cornerRadius(6)
                            }
                            
                            if record.timerSeconds != nil {
                                HStack(spacing: 3) {
                                    Image(systemName: "timer")
                                        .font(.system(size: 10))
                                    Text("Timer")
                                        .font(.system(size: 12, weight: .medium))
                                }
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(Color.yellowGreen.opacity(0.2))
                                .foregroundColor(Color.yellowGreen)
                                .cornerRadius(6)
                            }
                            
                            if record.hasPhoto {
                                HStack(spacing: 3) {
                                    Image(systemName: "camera.fill")
                                        .font(.system(size: 10))
                                    Text("Photo")
                                        .font(.system(size: 12, weight: .medium))
                                }
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(Color.irisPurple.opacity(0.2))
                                .foregroundColor(Color.irisPurple)
                                .cornerRadius(6)
                            }
                        }
                        .padding(.top, 4)
                    }
                }
                
                Spacer()
                
                // Expand/collapse indicator
                if hasAdditionalData {
                    Image(systemName: isExpanded ? "chevron.up.circle.fill" : "chevron.down.circle.fill")
                        .foregroundColor(colorScheme == .dark ? Color.yellowGreen : Color.black)
                        .font(.system(size: 22))
                }
            }
            
            // Expanded details
            if isExpanded && hasAdditionalData {
                VStack(alignment: .leading, spacing: 16) {
                    Divider()
                        .background(dividerColor)
                    
                    if let notes = record.notes {
                        VStack(alignment: .leading, spacing: 8) {
                            HStack(spacing: 6) {
                                Image(systemName: "note.text")
                                    .foregroundColor(Color.appleGreen)
                                    .font(.system(size: 14))
                                Text("Notes")
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundColor(Color.appleGreen)
                            }
                            Text(notes)
                                .font(.system(size: 15))
                                .foregroundColor(textColor)
                                .padding(.leading, 20)
                        }
                    }
                    
                    if let timerSeconds = record.timerSeconds {
                        VStack(alignment: .leading, spacing: 8) {
                            HStack(spacing: 6) {
                                Image(systemName: "timer")
                                    .foregroundColor(Color.yellowGreen)
                                    .font(.system(size: 14))
                                Text("Parking Duration")
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundColor(Color.yellowGreen)
                            }
                            Text(formatTimer(timerSeconds))
                                .font(.system(size: 15))
                                .foregroundColor(textColor)
                                .padding(.leading, 20)
                        }
                    }
                    
                    if record.hasPhoto {
                        HStack(spacing: 6) {
                            Image(systemName: "camera.fill")
                                .foregroundColor(Color.irisPurple)
                                .font(.system(size: 14))
                            Text("Photo saved with this location")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(Color.irisPurple)
                        }
                    }
                }
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
        .contentShape(Rectangle())
        .onTapGesture {
            if hasAdditionalData {
                onToggle()
            }
        }
    }
}

// MARK: - Swipe to Delete Card View
struct SwipeToDeleteCardView: View {
    let record: ParkingRecord
    let isExpanded: Bool
    let colorScheme: ColorScheme
    let cardBackgroundColor: Color
    let onToggle: () -> Void
    let onDelete: () -> Void
    
    @State private var offset: CGFloat = 0
    @State private var isSwiped: Bool = false
    
    private let deleteWidth: CGFloat = UIScreen.main.bounds.width * 0.3 * 0.85 // 30% of screen width minus padding
    private var deleteThreshold: CGFloat { -deleteWidth * 0.8 }
    private var snapThreshold: CGFloat { -deleteWidth * 0.4 }
    
    var body: some View {
        ZStack {
            // Background delete area (only visible when swiped)
            HStack {
                Spacer()
                Button(action: {
                    onDelete()
                }) {
                    HStack(spacing: 6) {
                        Image(systemName: "trash")
                            .font(.system(size: 16, weight: .semibold))
                        Text("Delete")
                            .font(.system(size: 14, weight: .semibold))
                    }
                    .foregroundColor(.white)
                    .frame(width: deleteWidth)
                }
                .frame(maxHeight: .infinity)
            }
            .background(Color.irisPurple)
            .cornerRadius(18)
            .opacity(offset < -10 ? 1 : 0)
            
            // Main card content
            HistoryItemView(
                record: record,
                isExpanded: isExpanded,
                colorScheme: colorScheme,
                onToggle: onToggle
            )
            .background(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(cardBackgroundColor)
                    .shadow(color: Color.black.opacity(colorScheme == .dark ? 0.3 : 0.08), 
                            radius: colorScheme == .dark ? 12 : 6, 
                            x: 0, 
                            y: colorScheme == .dark ? 4 : 2)
            )
            .offset(x: offset)
            .gesture(
                DragGesture()
                    .onChanged { value in
                        let translation = value.translation.width
                        // Only allow left swipe (negative values)
                        if translation < 0 {
                            offset = translation
                        }
                    }
                    .onEnded { value in
                        let translation = value.translation.width
                        let velocity = value.velocity.width
                        
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                            if translation < deleteThreshold || velocity < -1000 {
                                // Swipe far enough or fast enough - trigger delete
                                offset = -UIScreen.main.bounds.width
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                                    onDelete()
                                }
                            } else if translation < snapThreshold {
                                // Snap to   show delete button
                                offset = -deleteWidth
                                isSwiped = true
                            } else {
                                // Snap back to original position
                                offset = 0
                                isSwiped = false
                            }
                        }
                    }
            )
        }
        .clipped()
        .onTapGesture {
            if isSwiped {
                // If swiped, tapping should close the swipe
                withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                    offset = 0
                    isSwiped = false
                }
            }
            // Note: The tap gesture for expansion is handled in HistoryItemView
        }
    }
}

