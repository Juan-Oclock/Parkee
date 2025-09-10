//
//  Colors.swift
//  Parkee
//
//  Parkee color scheme and design system colors
//

import SwiftUI

extension Color {
    // MARK: - Parkee Brand Colors
    
    /// Primary brand color - Iris Purple (#6B41C7)
    /// Used for: Primary backgrounds, headers, brand elements
    static let irisPurple = Color(hex: "#6B41C7")
    
    /// Primary action color - Yellow Green (#A8DE28)
    /// Used for: Primary buttons, main CTAs, active states
    static let yellowGreen = Color(hex: "#A8DE28")
    
    /// Dark background color - Raisin Black (#1E1E2A)
    /// Used for: Dark backgrounds, primary text areas
    static let raisinBlack = Color(hex: "#1E1E2A")
    
    /// Secondary accent color - Apple Green (#8DB633)
    /// Used for: Secondary accents, progress indicators, success states
    static let appleGreen = Color(hex: "#8DB633")
    
    /// Card background color - Dark Card (#2D2D35)
    /// Used for: Card backgrounds, secondary dark elements
    static let darkCard = Color(hex: "#2D2D35")
    
    // MARK: - Semantic Colors
    
    /// Primary button color
    static let primaryButton = yellowGreen
    
    /// Secondary button color
    static let secondaryButton = appleGreen
    
    /// Primary background
    static let primaryBackground = irisPurple
    
    /// Secondary background
    static let secondaryBackground = raisinBlack
    
    /// Card background
    static let cardBackground = darkCard
    
    /// Success color
    static let success = appleGreen
    
    /// Primary text on dark backgrounds
    static let primaryTextOnDark = Color.white
    
    /// Secondary text on dark backgrounds
    static let secondaryTextOnDark = Color.white.opacity(0.7)
    
    /// Text on light/colored buttons
    static let textOnButton = raisinBlack
    
    // MARK: - Legacy Support (for gradual migration)
    
    @available(*, deprecated, message: "Use irisPurple instead")
    static let primaryGreen = irisPurple
    
    @available(*, deprecated, message: "Use raisinBlack instead")
    static let primaryBlack = raisinBlack
    
    // MARK: - Hex Color Initializer
    
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (1, 1, 1, 0)
        }

        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue:  Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

// MARK: - UIColor Extensions for Lottie

extension UIColor {
    // Parkee brand colors as UIColors for Lottie animations
    static let parkeeIrisPurple = UIColor(red: 107/255, green: 65/255, blue: 199/255, alpha: 1.0)
    static let parkeeYellowGreen = UIColor(red: 168/255, green: 222/255, blue: 40/255, alpha: 1.0)
    static let parkeeRaisinBlack = UIColor(red: 30/255, green: 30/255, blue: 42/255, alpha: 1.0)
    static let parkeeAppleGreen = UIColor(red: 141/255, green: 182/255, blue: 51/255, alpha: 1.0)
    static let parkeeDarkCard = UIColor(red: 45/255, green: 45/255, blue: 53/255, alpha: 1.0)
}
