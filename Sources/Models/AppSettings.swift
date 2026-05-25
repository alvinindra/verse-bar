import Foundation
import Combine

class AppSettings: ObservableObject {
    static let shared = AppSettings()
    
    @Published var showArtist: Bool {
        didSet { UserDefaults.standard.set(showArtist, forKey: "showArtist") }
    }
    
    @Published var showTitle: Bool {
        didSet { UserDefaults.standard.set(showTitle, forKey: "showTitle") }
    }
    
    @Published var showLyrics: Bool {
        didSet { UserDefaults.standard.set(showLyrics, forKey: "showLyrics") }
    }
    
    @Published var launchAtLogin: Bool {
        didSet { UserDefaults.standard.set(launchAtLogin, forKey: "launchAtLogin") }
    }
    
    @Published var trackingSafari: Bool {
        didSet { UserDefaults.standard.set(trackingSafari, forKey: "trackingSafari") }
    }
    
    @Published var trackingChrome: Bool {
        didSet { UserDefaults.standard.set(trackingChrome, forKey: "trackingChrome") }
    }
    
    @Published var trackingYTMDesktop: Bool {
        didSet { UserDefaults.standard.set(trackingYTMDesktop, forKey: "trackingYTMDesktop") }
    }
    
    @Published var trackingArc: Bool {
        didSet { UserDefaults.standard.set(trackingArc, forKey: "trackingArc") }
    }
    
    @Published var manualSyncOffset: TimeInterval {
        didSet { UserDefaults.standard.set(manualSyncOffset, forKey: "manualSyncOffset") }
    }

    @Published var pinPopover: Bool {
        didSet { UserDefaults.standard.set(pinPopover, forKey: "pinPopover") }
    }

    @Published var showNotchIsland: Bool {
        didSet { UserDefaults.standard.set(showNotchIsland, forKey: "showNotchIsland") }
    }

    @Published var hasCompletedOnboarding: Bool {
        didSet { UserDefaults.standard.set(hasCompletedOnboarding, forKey: "hasCompletedOnboarding") }
    }

    @Published var showRomanization: Bool {
        didSet { UserDefaults.standard.set(showRomanization, forKey: "showRomanization") }
    }

    private init() {
        UserDefaults.standard.register(defaults: [
            "showArtist": true,
            "showTitle": true,
            "showLyrics": true,
            "launchAtLogin": false,
            "trackingSafari": true,
            "trackingChrome": true,
            "trackingArc": true,
            "trackingYTMDesktop": true,
            "manualSyncOffset": 0.0,
            "pinPopover": false,
            "showNotchIsland": false,
            "hasCompletedOnboarding": false,
            "showRomanization": true
        ])

        self.showArtist = UserDefaults.standard.bool(forKey: "showArtist")
        self.showTitle = UserDefaults.standard.bool(forKey: "showTitle")
        self.showLyrics = UserDefaults.standard.bool(forKey: "showLyrics")
        self.launchAtLogin = UserDefaults.standard.bool(forKey: "launchAtLogin")
        self.trackingSafari = UserDefaults.standard.bool(forKey: "trackingSafari")
        self.trackingChrome = UserDefaults.standard.bool(forKey: "trackingChrome")
        self.trackingArc = UserDefaults.standard.bool(forKey: "trackingArc")
        self.trackingYTMDesktop = UserDefaults.standard.bool(forKey: "trackingYTMDesktop")
        self.manualSyncOffset = UserDefaults.standard.double(forKey: "manualSyncOffset")
        self.pinPopover = UserDefaults.standard.bool(forKey: "pinPopover")
        self.showNotchIsland = UserDefaults.standard.bool(forKey: "showNotchIsland")
        self.hasCompletedOnboarding = UserDefaults.standard.bool(forKey: "hasCompletedOnboarding")
        self.showRomanization = UserDefaults.standard.bool(forKey: "showRomanization")
    }
}
