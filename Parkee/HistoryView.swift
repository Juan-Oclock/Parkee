import SwiftUI
import MapKit

struct HistoryView: View {
    @ObservedObject var viewModel: ParkingViewModel
    @State private var expandedItems: Set<UUID> = []
    
    var body: some View {
        List {
            if viewModel.history.isEmpty {
                Text("No saved locations yet.")
                    .foregroundColor(.secondary)
            } else {
                ForEach(viewModel.history) { record in
                    HistoryItemView(record: record, isExpanded: expandedItems.contains(record.id)) {
                        if expandedItems.contains(record.id) {
                            expandedItems.remove(record.id)
                        } else {
                            expandedItems.insert(record.id)
                        }
                    }
                }
            }
        }
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                if !viewModel.history.isEmpty {
                    Button("Clear History") { viewModel.clearHistory() }
                }
            }
        }
        .navigationTitle("History")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct HistoryItemView: View {
    let record: ParkingRecord
    let isExpanded: Bool
    let onToggle: () -> Void
    
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
        VStack(alignment: .leading, spacing: 8) {
            // Main content
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    // Location name or fallback to coordinates
                    Text(record.locationName ?? String(format: "%.5f, %.5f", record.latitude, record.longitude))
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.primary)
                    
                    // Date and time
                    Text(record.savedAt, style: .date) + Text("  ") + Text(record.savedAt, style: .time)
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    // Indicator chips for available data
                    if hasAdditionalData {
                        HStack(spacing: 4) {
                            if record.notes != nil {
                                Text("Notes")
                                    .font(.caption2)
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 2)
                                    .background(Color.blue.opacity(0.2))
                                    .foregroundColor(.blue)
                                    .cornerRadius(4)
                            }
                            
                            if record.timerSeconds != nil {
                                Text("Timer")
                                    .font(.caption2)
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 2)
                                    .background(Color.green.opacity(0.2))
                                    .foregroundColor(.green)
                                    .cornerRadius(4)
                            }
                            
                            if record.hasPhoto {
                                Text("Photo")
                                    .font(.caption2)
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 2)
                                    .background(Color.orange.opacity(0.2))
                                    .foregroundColor(.orange)
                                    .cornerRadius(4)
                            }
                        }
                        .padding(.top, 2)
                    }
                }
                
                Spacer()
                
                // Expand/collapse button
                if hasAdditionalData {
                    Button(action: onToggle) {
                        Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                            .foregroundColor(.secondary)
                            .font(.caption)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
            
            // Expanded details
            if isExpanded && hasAdditionalData {
                VStack(alignment: .leading, spacing: 8) {
                    Divider()
                    
                    if let notes = record.notes {
                        VStack(alignment: .leading, spacing: 4) {
                            HStack {
                                Image(systemName: "note.text")
                                    .foregroundColor(.blue)
                                    .font(.caption)
                                Text("Notes")
                                    .font(.caption)
                                    .fontWeight(.semibold)
                                    .foregroundColor(.blue)
                            }
                            Text(notes)
                                .font(.footnote)
                                .foregroundColor(.primary)
                        }
                    }
                    
                    if let timerSeconds = record.timerSeconds {
                        VStack(alignment: .leading, spacing: 4) {
                            HStack {
                                Image(systemName: "timer")
                                    .foregroundColor(.green)
                                    .font(.caption)
                                Text("Timer")
                                    .font(.caption)
                                    .fontWeight(.semibold)
                                    .foregroundColor(.green)
                            }
                            Text(formatTimer(timerSeconds))
                                .font(.footnote)
                                .foregroundColor(.primary)
                        }
                    }
                    
                    if record.hasPhoto {
                        HStack {
                            Image(systemName: "camera.fill")
                                .foregroundColor(.orange)
                                .font(.caption)
                            Text("Photo was saved")
                                .font(.caption)
                                .fontWeight(.semibold)
                                .foregroundColor(.orange)
                        }
                    }
                }
            }
        }
        .padding(.vertical, 4)
    }
}


