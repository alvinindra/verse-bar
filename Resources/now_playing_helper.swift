// Long-running helper spawned by VerseBar.
// Must run via Apple-signed /usr/bin/swift so MediaRemote returns data
// on macOS 15.4+ (Apple restricts ad-hoc/unsigned apps from reading it).
//
// Writes one JSON object per line to stdout, polled by the parent process.
import Foundation

typealias GetInfoFn = @convention(c) (DispatchQueue, @escaping ([String: Any]) -> Void) -> Void
typealias GetIsPlayingFn = @convention(c) (DispatchQueue, @escaping (Bool) -> Void) -> Void

let frameworkURL = URL(fileURLWithPath: "/System/Library/PrivateFrameworks/MediaRemote.framework")
guard let bundle = CFBundleCreate(kCFAllocatorDefault, frameworkURL as CFURL),
      let infoPtr = CFBundleGetFunctionPointerForName(bundle, "MRMediaRemoteGetNowPlayingInfo" as CFString),
      let playingPtr = CFBundleGetFunctionPointerForName(bundle, "MRMediaRemoteGetNowPlayingApplicationIsPlaying" as CFString) else {
    FileHandle.standardError.write("MediaRemote bind failed\n".data(using: .utf8)!)
    exit(1)
}

let getInfo = unsafeBitCast(infoPtr, to: GetInfoFn.self)
let getIsPlaying = unsafeBitCast(playingPtr, to: GetIsPlayingFn.self)
let workQueue = DispatchQueue(label: "np.helper", qos: .userInitiated)

func emit(_ dict: [String: Any]) {
    guard let data = try? JSONSerialization.data(withJSONObject: dict, options: []),
          let line = String(data: data, encoding: .utf8) else { return }
    FileHandle.standardOutput.write((line + "\n").data(using: .utf8)!)
}

func poll() {
    getInfo(workQueue) { info in
        var dict: [String: Any] = [:]
        if let t = info["kMRMediaRemoteNowPlayingInfoTitle"] as? String { dict["title"] = t }
        if let a = info["kMRMediaRemoteNowPlayingInfoArtist"] as? String { dict["artist"] = a }
        if let alb = info["kMRMediaRemoteNowPlayingInfoAlbum"] as? String { dict["album"] = alb }
        if let d = info["kMRMediaRemoteNowPlayingInfoDuration"] as? Double { dict["duration"] = d }
        if let e = info["kMRMediaRemoteNowPlayingInfoElapsedTime"] as? Double { dict["elapsed"] = e }
        if let ts = info["kMRMediaRemoteNowPlayingInfoTimestamp"] as? Date { dict["timestamp"] = ts.timeIntervalSince1970 }
        if let art = info["kMRMediaRemoteNowPlayingInfoArtworkData"] as? Data {
            dict["artwork"] = art.base64EncodedString()
            if let aid = info["kMRMediaRemoteNowPlayingInfoArtworkIdentifier"] as? String {
                dict["artworkId"] = aid
            }
        }
        getIsPlaying(workQueue) { isPlaying in
            dict["isPlaying"] = isPlaying
            emit(dict)
        }
    }
}

// Quick interval; parent throttles. Keeps elapsed fresh.
Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in poll() }
poll()
RunLoop.main.run()
