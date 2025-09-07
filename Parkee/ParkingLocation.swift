//
//  ParkingLocation.swift
//  Parkee
//
//  Model representing a saved parking coordinate.
//

import CoreLocation

/// Simple model for a saved parking location
struct ParkingLocation: Equatable {
    /// Latitude in decimal degrees
    let latitude: Double
    /// Longitude in decimal degrees
    let longitude: Double

    /// Convenience accessor for CoreLocation consumers
    var coordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }
}



