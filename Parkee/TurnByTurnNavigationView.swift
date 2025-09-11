//
//  TurnByTurnNavigationView.swift
//  Parkee
//
//  Turn-by-turn navigation interface for directions to parked car
//

import SwiftUI
import MapKit
import CoreLocation

struct TurnByTurnNavigationView: View {
    let route: MKRoute
    let currentStepIndex: Int
    let distanceToNextStep: CLLocationDistance
    let isNavigating: Bool
    let colorScheme: ColorScheme
    let onClose: () -> Void
    
    @State private var showAllSteps = false
    
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
        VStack(spacing: 0) {
            // Navigation Header
            navigationHeader
            
            if isNavigating {
                // Current Step Card
                if currentStepIndex < route.steps.count {
                    currentStepCard(step: route.steps[currentStepIndex])
                }
                
                // Next Step Preview
                if currentStepIndex + 1 < route.steps.count {
                    nextStepPreview(step: route.steps[currentStepIndex + 1])
                }
            }
            
            // Steps List Button/Expanded View
            if showAllSteps {
                expandedStepsList
            } else {
                stepsListButton
            }
        }
        .background(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(backgroundColor)
                .shadow(color: Color.black.opacity(0.15), radius: 20, y: -5)
        )
    }
    
    // MARK: - Navigation Header
    @ViewBuilder
    private var navigationHeader: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(isNavigating ? "Navigating" : "Turn-by-Turn Directions")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(primaryText)
                
                if isNavigating {
                    HStack(spacing: 6) {
                        Circle()
                            .fill(Color.yellowGreen)
                            .frame(width: 8, height: 8)
                            .overlay(
                                Circle()
                                    .fill(Color.yellowGreen.opacity(0.3))
                                    .frame(width: 16, height: 16)
                                    .scaleEffect(1.5)
                                    .opacity(0.5)
                                    .animation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true), value: isNavigating)
                            )
                        
                        Text("Following route to your car")
                            .font(.system(size: 14))
                            .foregroundColor(secondaryText)
                    }
                }
            }
            
            Spacer()
            
            Button(action: onClose) {
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: 24))
                    .foregroundColor(secondaryText.opacity(0.6))
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
        .background(
            Rectangle()
                .fill(backgroundColor)
                .shadow(color: Color.black.opacity(0.05), radius: 1, y: 1)
        )
    }
    
    // MARK: - Current Step Card
    @ViewBuilder
    private func currentStepCard(step: MKRoute.Step) -> some View {
        VStack(spacing: 0) {
            // Distance to next turn
            HStack {
                Text(formatShortDistance(distanceToNextStep))
                    .font(.system(size: 36, weight: .bold))
                    .foregroundColor(Color.yellowGreen)
                
                Spacer()
                
                // Turn icon
                navigationIcon(for: step.instructions)
                    .font(.system(size: 44))
                    .foregroundColor(Color.yellowGreen)
            }
            .padding(.horizontal, 24)
            .padding(.top, 20)
            
            // Instruction
            Text(step.instructions)
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(primaryText)
                .multilineTextAlignment(.leading)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 24)
                .padding(.top, 12)
                .padding(.bottom, 20)
            
            // Progress indicator
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    // Background track
                    RoundedRectangle(cornerRadius: 2)
                        .fill(Color.yellowGreen.opacity(0.2))
                        .frame(height: 4)
                    
                    // Progress
                    let progress = step.distance > 0 ? max(0, min(1, 1 - (distanceToNextStep / step.distance))) : 0
                    RoundedRectangle(cornerRadius: 2)
                        .fill(Color.yellowGreen)
                        .frame(width: geometry.size.width * progress, height: 4)
                        .animation(.linear(duration: 0.3), value: progress)
                }
            }
            .frame(height: 4)
            .padding(.horizontal, 24)
            .padding(.bottom, 8)
        }
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(cardBackground)
        )
        .padding(.horizontal, 16)
        .padding(.top, 12)
    }
    
    // MARK: - Next Step Preview
    @ViewBuilder
    private func nextStepPreview(step: MKRoute.Step) -> some View {
        HStack(spacing: 16) {
            // Icon
            navigationIcon(for: step.instructions)
                .font(.system(size: 24))
                .foregroundColor(secondaryText)
                .frame(width: 40, height: 40)
                .background(
                    Circle()
                        .fill(Color.yellowGreen.opacity(0.1))
                )
            
            VStack(alignment: .leading, spacing: 4) {
                Text("Then")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(secondaryText)
                
                Text(step.instructions)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(primaryText)
                    .lineLimit(1)
                    .truncationMode(.tail)
            }
            
            Spacer()
            
            Text(formatDistance(step.distance))
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(secondaryText)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 14)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(cardBackground.opacity(0.6))
        )
        .padding(.horizontal, 16)
        .padding(.top, 8)
    }
    
    // MARK: - Steps List Button
    @ViewBuilder
    private var stepsListButton: some View {
        Button(action: {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                showAllSteps = true
            }
        }) {
            HStack {
                Image(systemName: "list.bullet")
                    .font(.system(size: 16))
                
                Text("View All Steps (\(route.steps.count))")
                    .font(.system(size: 15, weight: .medium))
                
                Spacer()
                
                Image(systemName: "chevron.up")
                    .font(.system(size: 14))
            }
            .foregroundColor(primaryText)
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
        }
        .buttonStyle(.plain)
    }
    
    // MARK: - Expanded Steps List
    @ViewBuilder
    private var expandedStepsList: some View {
        VStack(spacing: 0) {
            // Header
            Button(action: {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                    showAllSteps = false
                }
            }) {
                HStack {
                    Image(systemName: "list.bullet")
                        .font(.system(size: 16))
                    
                    Text("All Steps")
                        .font(.system(size: 15, weight: .semibold))
                    
                    Spacer()
                    
                    Image(systemName: "chevron.down")
                        .font(.system(size: 14))
                }
                .foregroundColor(primaryText)
                .padding(.horizontal, 20)
                .padding(.vertical, 16)
            }
            .buttonStyle(.plain)
            
            Divider()
                .background(secondaryText.opacity(0.2))
            
            // Steps list
            ScrollView {
                VStack(spacing: 0) {
                    ForEach(Array(route.steps.enumerated()), id: \.offset) { index, step in
                        if !step.instructions.isEmpty {
                            stepRow(step: step, index: index)
                            
                            if index < route.steps.count - 1 {
                                Divider()
                                    .background(secondaryText.opacity(0.1))
                                    .padding(.leading, 60)
                            }
                        }
                    }
                }
            }
            .frame(maxHeight: 300)
        }
    }
    
    // MARK: - Step Row
    @ViewBuilder
    private func stepRow(step: MKRoute.Step, index: Int) -> some View {
        HStack(spacing: 12) {
            // Step number or icon
            ZStack {
                if index == currentStepIndex && isNavigating {
                    Circle()
                        .fill(Color.yellowGreen)
                        .frame(width: 36, height: 36)
                    
                    navigationIcon(for: step.instructions)
                        .font(.system(size: 18))
                        .foregroundColor(.black)
                } else if index < currentStepIndex {
                    Circle()
                        .fill(Color.yellowGreen.opacity(0.3))
                        .frame(width: 36, height: 36)
                    
                    Image(systemName: "checkmark")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(Color.yellowGreen)
                } else {
                    Circle()
                        .stroke(secondaryText.opacity(0.3), lineWidth: 1)
                        .frame(width: 36, height: 36)
                    
                    Text("\(index + 1)")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(secondaryText)
                }
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(step.instructions)
                    .font(.system(size: 14, weight: index == currentStepIndex ? .semibold : .regular))
                    .foregroundColor(index == currentStepIndex ? primaryText : secondaryText)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)
                
                if step.distance > 0 {
                    Text(formatDistance(step.distance))
                        .font(.system(size: 12))
                        .foregroundColor(secondaryText.opacity(0.7))
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            
            if index == currentStepIndex && isNavigating {
                Text(formatShortDistance(distanceToNextStep))
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(Color.yellowGreen)
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
        .background(
            index == currentStepIndex && isNavigating ?
            Color.yellowGreen.opacity(0.05) : Color.clear
        )
    }
    
    // MARK: - Helper Functions
    private func navigationIcon(for instruction: String) -> some View {
        let lowercased = instruction.lowercased()
        
        let iconName: String
        if lowercased.contains("left") {
            iconName = "arrow.turn.up.left"
        } else if lowercased.contains("right") {
            iconName = "arrow.turn.up.right"
        } else if lowercased.contains("straight") || lowercased.contains("continue") {
            iconName = "arrow.up"
        } else if lowercased.contains("merge") {
            iconName = "arrow.merge"
        } else if lowercased.contains("exit") || lowercased.contains("ramp") {
            iconName = "arrow.turn.right.up"
        } else if lowercased.contains("roundabout") || lowercased.contains("rotary") {
            iconName = "arrow.triangle.circlepath"
        } else if lowercased.contains("u-turn") || lowercased.contains("u turn") {
            iconName = "arrow.uturn.up"
        } else if lowercased.contains("destination") || lowercased.contains("arrive") {
            iconName = "mappin.circle.fill"
        } else if lowercased.contains("depart") || lowercased.contains("start") {
            iconName = "location.fill"
        } else {
            iconName = "arrow.up"
        }
        
        return Image(systemName: iconName)
    }
    
    private func formatDistance(_ distance: CLLocationDistance) -> String {
        let formatter = MKDistanceFormatter()
        formatter.unitStyle = .abbreviated
        return formatter.string(fromDistance: distance)
    }
    
    private func formatShortDistance(_ distance: CLLocationDistance) -> String {
        let formatter = MKDistanceFormatter()
        formatter.unitStyle = .abbreviated
        
        // For very short distances, show in feet/meters
        if distance < 100 {
            formatter.units = .metric // or .imperial based on user preference
            let result = formatter.string(fromDistance: distance)
            // Make it more concise
            return result.replacingOccurrences(of: "meters", with: "m")
                        .replacingOccurrences(of: "feet", with: "ft")
        }
        
        return formatter.string(fromDistance: distance)
    }
}

// MARK: - Preview
struct TurnByTurnNavigationView_Previews: PreviewProvider {
    static var previews: some View {
        TurnByTurnNavigationView(
            route: MKRoute(),
            currentStepIndex: 0,
            distanceToNextStep: 150,
            isNavigating: true,
            colorScheme: .dark,
            onClose: {}
        )
        .frame(height: 400)
        .previewLayout(.sizeThatFits)
    }
}
