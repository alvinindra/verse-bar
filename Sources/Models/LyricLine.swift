import Foundation

struct LyricLine: Identifiable, Equatable {
    let id = UUID()
    let timestamp: TimeInterval // Elapsed time in seconds from start of song
    let text: String
    let romanized: String?

    init(timestamp: TimeInterval, text: String, romanized: String? = nil) {
        self.timestamp = timestamp
        self.text = text
        self.romanized = romanized
    }
}
