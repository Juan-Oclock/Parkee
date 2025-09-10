//
//  ParkeeApp.swift
//  Parkee
//
//  Created by Juan Oclock on 9/5/25.
//

import SwiftUI

@main
struct ParkeeApp: App {
    @StateObject private var viewModel = ParkingViewModel()
    
    var body: some Scene {
        WindowGroup {
            Group {
                if viewModel.hasSeenOnboarding {
                    ContentView()
                        .environmentObject(viewModel)
                } else {
                    OnboardingView(viewModel: viewModel)
                }
            }
        }
    }
}
