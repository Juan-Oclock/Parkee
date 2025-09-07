import Foundation
import CoreLocation

struct ParkingRecord: Codable, Identifiable, Equatable {
    let id: UUID
    let latitude: Double
    let longitude: Double
    let savedAt: Date
    var locationName: String?
    var notes: String?
    var timerSeconds: TimeInterval?
    var hasPhoto: Bool

    init(latitude: Double, longitude: Double, savedAt: Date, locationName: String?, notes: String?, timerSeconds: TimeInterval?, hasPhoto: Bool) {
        self.id = UUID()
        self.latitude = latitude
        self.longitude = longitude
        self.savedAt = savedAt
        self.locationName = locationName
        self.notes = notes
        self.timerSeconds = timerSeconds
        self.hasPhoto = hasPhoto
    }
    
    // Legacy support for existing records
    enum CodingKeys: String, CodingKey {
        case id, latitude, longitude, savedAt, locationName, notes, timerSeconds, hasPhoto
        case address // For backward compatibility
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        latitude = try container.decode(Double.self, forKey: .latitude)
        longitude = try container.decode(Double.self, forKey: .longitude)
        savedAt = try container.decode(Date.self, forKey: .savedAt)
        
        // Try to decode new format first, fallback to legacy
        if let name = try container.decodeIfPresent(String.self, forKey: .locationName) {
            locationName = name
        } else {
            // Legacy fallback - use address as location name
            locationName = try container.decodeIfPresent(String.self, forKey: .address)
        }
        
        notes = try container.decodeIfPresent(String.self, forKey: .notes)
        timerSeconds = try container.decodeIfPresent(TimeInterval.self, forKey: .timerSeconds)
        hasPhoto = try container.decodeIfPresent(Bool.self, forKey: .hasPhoto) ?? false
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(latitude, forKey: .latitude)
        try container.encode(longitude, forKey: .longitude)
        try container.encode(savedAt, forKey: .savedAt)
        try container.encodeIfPresent(locationName, forKey: .locationName)
        try container.encodeIfPresent(notes, forKey: .notes)
        try container.encodeIfPresent(timerSeconds, forKey: .timerSeconds)
        try container.encode(hasPhoto, forKey: .hasPhoto)
    }

    var coordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }
}


