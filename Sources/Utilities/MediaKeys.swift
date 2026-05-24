import Cocoa

/// Synthesises macOS media keys (Play/Pause, Next, Previous).
/// Routes to whatever has registered with the system's Now Playing service —
/// YouTube Music in any browser, YTMDesktop, Apple Music, etc.
enum MediaKeys {
    // NX_KEYTYPE_* constants from IOKit's ev_keymap.h
    static let play: Int32     = 16   // NX_KEYTYPE_PLAY
    static let next: Int32     = 17   // NX_KEYTYPE_NEXT
    static let previous: Int32 = 18   // NX_KEYTYPE_PREVIOUS

    static func send(_ key: Int32) {
        post(key: key, down: true)
        post(key: key, down: false)
    }

    private static func post(key: Int32, down: Bool) {
        let flagsRaw: UInt = down ? 0xa00 : 0xb00
        let data1 = (Int(key) << 16) | ((down ? 0xA : 0xB) << 8)

        guard let event = NSEvent.otherEvent(
            with: .systemDefined,
            location: .zero,
            modifierFlags: NSEvent.ModifierFlags(rawValue: flagsRaw),
            timestamp: 0,
            windowNumber: 0,
            context: nil,
            subtype: 8, // NSSystemDefinedEventSubtypeAUXControlButtons
            data1: data1,
            data2: -1
        ), let cgEvent = event.cgEvent else {
            return
        }
        cgEvent.post(tap: .cghidEventTap)
    }
}
