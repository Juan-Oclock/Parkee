//
//  LottieView.swift
//  Parkee
//
//  SwiftUI wrapper for Lottie animations with fallback support
//

import SwiftUI

#if canImport(Lottie)
import Lottie

// Real Lottie implementation using lottie-spm package
struct LottieView: View {
    let animationName: String
    let loopMode: String
    let animationSpeed: CGFloat
    
    @State private var animationView: LottieAnimationView?
    
    init(
        animationName: String,
        loopMode: String = "loop",
        animationSpeed: CGFloat = 1.0
    ) {
        self.animationName = animationName
        self.loopMode = loopMode
        self.animationSpeed = animationSpeed
    }
    
    var body: some View {
        LottieViewRepresentable(
            animationName: animationName,
            loopMode: loopMode,
            animationSpeed: animationSpeed
        )
    }
}

struct LottieViewRepresentable: UIViewRepresentable {
    let animationName: String
    let loopMode: String
    let animationSpeed: CGFloat
    
    func makeUIView(context: Context) -> UIView {
        let containerView = UIView()
        let animationView = LottieAnimationView()
        
        // Configure animation view
        animationView.contentMode = .scaleAspectFit
        animationView.loopMode = loopMode == "loop" ? .loop : .playOnce
        animationView.animationSpeed = animationSpeed
        
        // Try to load the animation
        if let animation = loadAnimation(named: animationName) {
            animationView.animation = animation
            
            // Apply Parkee brand colors
            applyBrandColors(to: animationView)
            
            animationView.play()
        } else {
            // If Lottie animation fails to load, show fallback
            return createFallbackView(for: animationName)
        }
        
        // Add animation view to container
        containerView.addSubview(animationView)
        animationView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            animationView.topAnchor.constraint(equalTo: containerView.topAnchor),
            animationView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor),
            animationView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor),
            animationView.bottomAnchor.constraint(equalTo: containerView.bottomAnchor)
        ])
        
        return containerView
    }
    
    func updateUIView(_ uiView: UIView, context: Context) {
        // Animation updates can be handled here if needed
    }
    
    private func loadAnimation(named name: String) -> LottieAnimation? {
        // Try loading from main bundle first
        if let animation = LottieAnimation.named(name) {
            return animation
        }
        
        // Try loading from Animations folder
        if let animation = LottieAnimation.named(name, subdirectory: "Animations") {
            return animation
        }
        
        return nil
    }
    
    private func applyBrandColors(to animationView: LottieAnimationView) {
        // Parkee brand colors - new color scheme
        let irisPurple = UIColor.parkeeIrisPurple      // #6B41C7
        let yellowGreen = UIColor.parkeeYellowGreen    // #A8DE28
        let raisinBlack = UIColor.parkeeRaisinBlack    // #1E1E2A
        let appleGreen = UIColor.parkeeAppleGreen      // #8DB633
        let white = UIColor.white
        
        // Apply colors to different animation elements
        // Specific targeting for car-driving animation and others
        let colorMappings: [(String, UIColor)] = [
            // Car-driving specific targeting (based on JSON structure)
            ("**.âCar safetyâè½®å».**.å¡«å 1.Color", yellowGreen),
            ("**.Mask.**.å¡«å 1.Color", irisPurple),
            ("**.è·¯å¾.å¡«å 1.Color", yellowGreen),
            ("**.è·¯å¾ 2.å¡«å 1.Color", appleGreen),
            ("**.è·¯å¾ 3.å¡«å 1.Color", irisPurple),
            
            // Car elements - generic patterns
            ("**.Ellipse 1.Fill 1.Color", yellowGreen),
            ("**.Rectangle 1.Fill 1.Color", irisPurple),
            ("**.Shape Layer 1.Fill 1.Color", yellowGreen),
            ("**.Shape Layer 2.Fill 1.Color", appleGreen),
            ("**.car.Fill 1.Color", yellowGreen),
            ("**.vehicle.Fill 1.Color", yellowGreen),
            
            // Location pin elements
            ("**.Location Pin.Fill 1.Color", yellowGreen),
            ("**.Pin.Fill 1.Color", yellowGreen),
            ("**.Circle.Fill 1.Color", irisPurple),
            ("**.pin.Fill 1.Color", yellowGreen),
            
            // Map elements
            ("**.Map.Fill 1.Color", appleGreen),
            ("**.Background.Fill 1.Color", white),
            ("**.Path.Stroke 1.Color", raisinBlack),
            ("**.map.Fill 1.Color", appleGreen),
            
            // Generic shape targeting (covers most animations)
            ("**.Fill 1.Color", yellowGreen),
            ("**.Stroke 1.Color", raisinBlack),
            ("**.å¡«å 1.Color", yellowGreen),  // Chinese "Fill" in car-driving
            ("**.æè¾¹ 1.Color", raisinBlack),   // Chinese "Stroke" in car-driving
        ]
        
        // Apply each color mapping
        for (keyPath, color) in colorMappings {
            let colorProvider = ColorValueProvider(color.lottieColorValue)
            animationView.setValueProvider(colorProvider, keypath: AnimationKeypath(keypath: keyPath))
        }
    }
    
    private func createFallbackView(for animationName: String) -> UIView {
        let hostingController = UIHostingController(rootView: FallbackAnimationView(animationName: animationName))
        hostingController.view.backgroundColor = .clear
        return hostingController.view
    }
}

#else

// Fallback implementation when Lottie is not available
struct LottieView: View {
    let animationName: String
    let loopMode: String
    let animationSpeed: CGFloat
    
    init(
        animationName: String,
        loopMode: String = "loop",
        animationSpeed: CGFloat = 1.0
    ) {
        self.animationName = animationName
        self.loopMode = loopMode
        self.animationSpeed = animationSpeed
    }
    
    var body: some View {
        FallbackAnimationView(animationName: animationName)
    }
}

#endif

// Shared fallback animation view
struct FallbackAnimationView: View {
    let animationName: String
    
    @State private var isAnimating = false
    @State private var rotationAngle: Double = 0
    @State private var scaleEffect: CGFloat = 1.0
    @State private var offset: CGFloat = 0
    
    var body: some View {
        Group {
            switch animationName {
            case "car-driving":
                Image(systemName: "car.fill")
                    .font(.system(size: 120, weight: .medium))
                    .foregroundColor(.yellowGreen)
                    .offset(x: offset)
                    .onAppear {
                        withAnimation(.easeInOut(duration: 2.0).repeatForever(autoreverses: true)) {
                            offset = 30
                        }
                    }
                    
            case "location-pin":
                Image(systemName: "location.fill")
                    .font(.system(size: 120, weight: .medium))
                    .foregroundColor(.yellowGreen)
                    .scaleEffect(scaleEffect)
                    .onAppear {
                        withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true)) {
                            scaleEffect = 1.3
                        }
                    }
                    
            case "navigation-map":
                Image(systemName: "map.fill")
                    .font(.system(size: 120, weight: .medium))
                    .foregroundColor(.appleGreen)
                    .rotationEffect(.degrees(rotationAngle))
                    .onAppear {
                        withAnimation(.linear(duration: 3.0).repeatForever(autoreverses: false)) {
                            rotationAngle = 360
                        }
                    }
                    
            default:
                Image(systemName: "questionmark.circle.fill")
                    .font(.system(size: 120, weight: .medium))
                    .foregroundColor(.irisPurple)
            }
        }
    }
}

