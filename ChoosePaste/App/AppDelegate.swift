import Cocoa

class AppDelegate: NSObject, NSApplicationDelegate {
    private var statusBarController: StatusBarController!
    private var hotkeyService: HotkeyService!

    func applicationDidFinishLaunching(_ notification: Notification) {
        statusBarController = StatusBarController()
        hotkeyService = HotkeyService(statusBarController: statusBarController)
        hotkeyService.start()
    }

    func applicationWillTerminate(_ notification: Notification) {
        hotkeyService.stop()
    }
}
