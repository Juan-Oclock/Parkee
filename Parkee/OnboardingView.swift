//
//  OnboardingView.swift
//  Parkee
//
//  Onboarding flow for first-time users with 3 welcome screens
//

import SwiftUI

struct OnboardingView: View {
    @ObservedObject var viewModel: ParkingViewModel
    @State private var currentPage = 0
    
    var body: some View {
        VStack(spacing: 0) {
            // Main onboarding content
            TabView(selection: $currentPage) {
                // Screen 1: Welcome
                OnboardingScreenView(
                    title: "Welcome to Parkee",
                    bodyText: "The smart way to save your parking spot location and find your way back with ease",
                    lottieAnimation: "car-driving",
                    primaryColor: .yellowGreen
                )
                .tag(0)
                
                // Screen 2: One-Tap Parking
                OnboardingScreenView(
                    title: "One-Tap Parking",
                    bodyText: "Save your parking spot location instantly with a single tap. Never forget where you parked again",
                    lottieAnimation: "location-pin",
                    primaryColor: .yellowGreen
                )
                .tag(1)
                
                // Screen 3: Find Your Car
                OnboardingScreenView(
                    title: "Find Your Car with Ease",
                    bodyText: "Never lose your car again. Our smart map guides you directly to your spot, saving you time and stress",
                    lottieAnimation: "navigation-map",
                    primaryColor: .appleGreen
                )
                .tag(2)
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            .animation(.easeInOut(duration: 0.4), value: currentPage)
            
            // Bottom section with indicators and buttons
            VStack(spacing: 24) {
                // Page indicators
                HStack(spacing: 12) {
                    ForEach(0..<3, id: \.self) { index in
                        Circle()
                            .fill(index == currentPage ? Color.yellowGreen : Color.white.opacity(0.4))
                            .frame(width: 8, height: 8)
                            .scaleEffect(index == currentPage ? 1.2 : 1.0)
                            .animation(.easeInOut(duration: 0.3), value: currentPage)
                    }
                }
                
                // Action buttons
                VStack(spacing: 12) {
                    if currentPage < 2 {
                        // Next button
                        Button(action: {
                            withAnimation(.easeInOut(duration: 0.4)) {
                                currentPage += 1
                            }
                        }) {
                            HStack {
                            Text("Continue")
                                .font(.system(size: 17, weight: .semibold))
                                .foregroundColor(.raisinBlack)
                            
                            Image(systemName: "arrow.right")
                                .font(.system(size: 17, weight: .semibold))
                                .foregroundColor(.raisinBlack)
                            }
                            .frame(maxWidth: .infinity)
                            .frame(height: 56)
                            .background(Color.yellowGreen)
                            .cornerRadius(28)
                        }
                        
                        // Skip button
                        Button(action: {
                            completeOnboarding()
                        }) {
                            Text("Skip")
                                .font(.system(size: 17, weight: .medium))
                                .foregroundColor(.white.opacity(0.7))
                                .frame(height: 44)
                        }
                    } else {
                        // Get Started button (final screen)
                        Button(action: {
                            completeOnboarding()
                        }) {
                            HStack {
                            Text("Get Started")
                                .font(.system(size: 17, weight: .semibold))
                                .foregroundColor(.raisinBlack)
                            
                            Image(systemName: "arrow.right")
                                .font(.system(size: 17, weight: .semibold))
                                .foregroundColor(.raisinBlack)
                            }
                            .frame(maxWidth: .infinity)
                            .frame(height: 56)
                            .background(Color.yellowGreen)
                            .cornerRadius(28)
                        }
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 40)
        }
        .background(
            LinearGradient(
                colors: [Color.irisPurple, Color.raisinBlack],
                startPoint: .top,
                endPoint: .bottom
            )
        )
        .ignoresSafeArea(.all, edges: .top)
    }
    
    private func completeOnboarding() {
        // Trigger haptic feedback
        if viewModel.isHapticsEnabled {
            let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
            impactFeedback.impactOccurred()
        }
        
        // Mark onboarding as completed
        viewModel.completeOnboarding()
    }
}

struct OnboardingScreenView: View {
    let title: String
    let bodyText: String
    let lottieAnimation: String
    let primaryColor: Color
    
    var body: some View {
        VStack(spacing: 0) {
            Spacer()
            
            // Lottie animation
            VStack(spacing: 32) {
                LottieView(
                    animationName: lottieAnimation,
                    loopMode: "loop",
                    animationSpeed: 1.0
                )
                .frame(
                    width: lottieAnimation == "navigation-map" ? 280 : lottieAnimation == "location-pin" ? 250 : 350,
                    height: lottieAnimation == "navigation-map" ? 280 : lottieAnimation == "location-pin" ? 250 : 350
                )
                
                // Text content
                VStack(spacing: 16) {
                    Text(title)
                        .font(.system(size: 28, weight: .bold))
                        .foregroundColor(.white)
                        .multilineTextAlignment(.center)
                        .lineLimit(nil)
                    
                    Text(bodyText)
                        .font(.system(size: 17, weight: .regular))
                        .foregroundColor(.white.opacity(0.8))
                        .multilineTextAlignment(.center)
                        .lineLimit(nil)
                        .lineSpacing(4)
                }
                .padding(.horizontal, 32)
            }
            
            Spacer()
        }
    }
}


#Preview {
    OnboardingView(viewModel: ParkingViewModel())
}
