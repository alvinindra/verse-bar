import Cocoa

let app = NSApplication.shared
let delegate = AppDelegate()
app.delegate = delegate
app.setActivationPolicy(.accessory) // Hides app from Dock and Command-Tab, running purely in the status area
app.run()
