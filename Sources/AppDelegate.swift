import Cocoa
import SwiftUI
import UserNotifications

class AppDelegate: NSObject, NSApplicationDelegate {
    private var settingsWindow: NSWindow?
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        // Notification authorization is handled by the onboarding flow on
        // first launch. After that we no-op — the user already made a choice.
        if AppSettings.shared.hasCompletedOnboarding {
            let center = UNUserNotificationCenter.current()
            center.requestAuthorization(options: [.alert, .badge, .sound]) { _, _ in }
        }

        // Initialize StatusItemManager to load the status bar item and start tracking
        _ = StatusItemManager.shared

        // Initialize the Music Island overlay (it is hidden until the user
        // enables the toggle in Preferences and something is playing).
        _ = NotchIslandController.shared

        // Observe window presentation requests
        NotificationCenter.default.addObserver(self, selector: #selector(showSettingsWindow), name: Notification.Name("ShowSettingsWindow"), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(showOnboardingWindow), name: Notification.Name("ShowOnboardingWindow"), object: nil)

        // Show the first-run setup window if the user hasn't finished it.
        DispatchQueue.main.async {
            OnboardingController.shared.showIfNeeded()
        }

        Logger.info("Verse Bar application launched.", category: "general")
    }

    @objc func showOnboardingWindow() {
        OnboardingController.shared.show()
    }
    
    @objc func showSettingsWindow() {
        if let window = settingsWindow {
            window.makeKeyAndOrderFront(nil)
            NSApp.activate(ignoringOtherApps: true)
            return
        }
        
        // Create a beautiful native window for preferences
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 420, height: 480),
            styleMask: [.titled, .closable, .miniaturizable],
            backing: .buffered,
            defer: false
        )
        
        window.center()
        window.title = "Verse Bar Preferences"
        window.isReleasedWhenClosed = false
        window.titlebarAppearsTransparent = true
        window.titleVisibility = .hidden
        
        // Enable premium look matching standard macOS utility settings
        window.standardWindowButton(.zoomButton)?.isHidden = true
        
        // Embed the SwiftUI SettingsView
        window.contentViewController = NSHostingController(rootView: SettingsView())
        
        self.settingsWindow = window
        window.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
        
        // Register cleanup callback on window close
        NotificationCenter.default.addObserver(self, selector: #selector(settingsWindowWillClose(_:)), name: NSWindow.willCloseNotification, object: window)
    }
    
    @objc func settingsWindowWillClose(_ notification: Notification) {
        if let closedWindow = notification.object as? NSWindow, closedWindow == settingsWindow {
            self.settingsWindow = nil
            NotificationCenter.default.removeObserver(self, name: NSWindow.willCloseNotification, object: closedWindow)
            Logger.info("Preferences window closed.", category: "general")
        }
    }
}
