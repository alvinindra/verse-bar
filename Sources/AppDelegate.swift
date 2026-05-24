import Cocoa
import SwiftUI
import UserNotifications

class AppDelegate: NSObject, NSApplicationDelegate {
    private var settingsWindow: NSWindow?
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        // Request user permission for native track change notifications
        let center = UNUserNotificationCenter.current()
        center.requestAuthorization(options: [.alert, .badge, .sound]) { granted, error in
            if granted {
                Logger.info("System notification authorization granted.", category: "general")
            } else if let error = error {
                Logger.error("System notification authorization error", category: "general", error: error)
            }
        }
        
        // Initialize StatusItemManager to load the status bar item and start tracking
        _ = StatusItemManager.shared

        // Observe window presentation requests
        NotificationCenter.default.addObserver(self, selector: #selector(showSettingsWindow), name: Notification.Name("ShowSettingsWindow"), object: nil)
        
        Logger.info("Verse Bar application launched.", category: "general")
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
