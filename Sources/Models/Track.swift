import Foundation

struct Track: Equatable {
    let title: String
    let artist: String
    var duration: TimeInterval
    var elapsedTime: TimeInterval
    var isPaused: Bool
    var lastUpdated: Date
    var isEstimatedProgress: Bool = false
    var artworkData: Data? = nil
    var artworkId: String? = nil
    
    // Returns the estimated current playback position by interpolating from the last update time
    var currentProgress: TimeInterval {
        if isPaused {
            return elapsedTime
        } else {
            let elapsedSinceUpdate = Date().timeIntervalSince(lastUpdated)
            return min(duration, elapsedTime + elapsedSinceUpdate)
        }
    }
    
    static func == (lhs: Track, rhs: Track) -> Bool {
        return lhs.title == rhs.title &&
               lhs.artist == rhs.artist &&
               lhs.isPaused == rhs.isPaused &&
               lhs.isEstimatedProgress == rhs.isEstimatedProgress &&
               lhs.artworkId == rhs.artworkId &&
               abs(lhs.elapsedTime - rhs.elapsedTime) < 1.0 // Allow slight drift without triggering full reload
    }
}
