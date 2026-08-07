import Cocoa

let app = NSApplication.shared
app.setActivationPolicy(.accessory) // LSUIElement equivalent: no dock icon

let delegate = AppDelegate()
app.delegate = delegate
app.run()
