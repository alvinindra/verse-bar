import Foundation

struct LyricLine: Identifiable, Equatable {
    let id = UUID()
    let timestamp: TimeInterval // Elapsed time in seconds from start of song
    let text: String
}
