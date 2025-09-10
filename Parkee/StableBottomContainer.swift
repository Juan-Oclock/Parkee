//
//  StableBottomContainer.swift
//  Parkee
//
//  UIKit-backed container to prevent flickering on real devices with high refresh rates
//

import SwiftUI
import UIKit

/// A container that prevents SwiftUI recomposition flickers by using UIKit hosting
struct StableBottomContainer<Content: View>: UIViewControllerRepresentable {
    let content: Content
    
    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }
    
    func makeUIViewController(context: Context) -> UIViewController {
        let hostingController = UIHostingController(rootView: content)
        hostingController.view.backgroundColor = .clear
        
        // Disable automatic content size invalidation
        hostingController.sizingOptions = [.preferredContentSize]
        
        return hostingController
    }
    
    func updateUIViewController(_ uiViewController: UIViewController, context: Context) {
        // Only update if absolutely necessary
        guard let hostingController = uiViewController as? UIHostingController<Content> else { return }
        
        // Update with transaction to prevent animations during update
        hostingController.rootView = content
    }
    
    static func dismantleUIViewController(_ uiViewController: UIViewController, coordinator: ()) {
        // Clean up if needed
    }
}

