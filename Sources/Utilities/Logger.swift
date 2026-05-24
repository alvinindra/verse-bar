import Foundation
import os.log

enum Logger {
    private static let subsystem = "com.versebar.VerseBar"
    private static let generalLog = OSLog(subsystem: subsystem, category: "general")
    private static let playbackLog = OSLog(subsystem: subsystem, category: "playback")
    private static let lyricsLog = OSLog(subsystem: subsystem, category: "lyrics")
    
    // Log file for easy debugging
    private static let logFileURL: URL = {
        let paths = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)
        let appDir = paths[0].appendingPathComponent("com.versebar.VerseBar", isDirectory: true)
        try? FileManager.default.createDirectory(at: appDir, withIntermediateDirectories: true)
        return appDir.appendingPathComponent("debug.log")
    }()
    
    static func info(_ message: String, category: String = "general") {
        let log = getLog(for: category)
        os_log("%{public}@", log: log, type: .info, message)
        writeToFile("ℹ️ [\(category.uppercased())] \(message)")
    }
    
    static func error(_ message: String, category: String = "general", error: Error? = nil) {
        let log = getLog(for: category)
        let errMsg = error != nil ? " (Error: \(error!.localizedDescription))" : ""
        os_log("❌ %{public}@%@", log: log, type: .error, message, errMsg)
        writeToFile("❌ [\(category.uppercased())] \(message)\(errMsg)")
    }
    
    private static func writeToFile(_ message: String) {
        let timestamp = ISO8601DateFormatter().string(from: Date())
        let line = "[\(timestamp)] \(message)\n"
        
        if FileManager.default.fileExists(atPath: logFileURL.path) {
            if let handle = try? FileHandle(forWritingTo: logFileURL) {
                handle.seekToEndOfFile()
                if let data = line.data(using: .utf8) {
                    handle.write(data)
                }
                handle.closeFile()
            }
        } else {
            try? line.write(to: logFileURL, atomically: true, encoding: .utf8)
        }
    }
    
    static func clearLog() {
        try? "".write(to: logFileURL, atomically: true, encoding: .utf8)
    }
    
    static var logFilePath: String {
        return logFileURL.path
    }
    
    private static func getLog(for category: String) -> OSLog {
        switch category {
        case "playback": return playbackLog
        case "lyrics": return lyricsLog
        default: return generalLog
        }
    }
}
