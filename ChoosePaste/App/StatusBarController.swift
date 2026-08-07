import Cocoa
import SwiftUI

enum MenuBarIconState {
    case atRest
    case success
    case error
    case empty
    case disabled
}

class StatusBarController: NSObject {
    private var statusItem: NSStatusItem!
    private var popoverManager: PopoverManager!

    override init() {
        super.init()

        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)

        if let button = statusItem.button {
            button.image = NSImage(systemSymbolName: "doc.on.clipboard", accessibilityDescription: "choosepaste")
            button.action = #selector(statusBarButtonClicked(_:))
            button.target = self
        }

        popoverManager = PopoverManager()
    }

    @objc private func statusBarButtonClicked(_ sender: NSStatusBarButton) {
        if popoverManager.isShown {
            popoverManager.close()
        } else {
            showPopoverAtCursor()
        }
    }

    func showPopoverAtCursor() {
        let clipboard = ClipboardService.shared.snapshot()
        popoverManager.show(clipboard: clipboard)
    }

    func closePopover() {
        popoverManager.close()
    }

    func flashIcon(state: MenuBarIconState) {
        guard let button = statusItem.button else { return }

        switch state {
        case .success:
            button.image = NSImage(systemSymbolName: "checkmark", accessibilityDescription: "Success")
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                self.resetIcon()
            }
        case .error:
            button.image = NSImage(systemSymbolName: "exclamationmark.triangle", accessibilityDescription: "Error")
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                self.resetIcon()
            }
        case .empty:
            button.image = NSImage(systemSymbolName: "questionmark", accessibilityDescription: "Empty clipboard")
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                self.resetIcon()
            }
        case .disabled:
            button.image = NSImage(systemSymbolName: "doc.on.clipboard", accessibilityDescription: "choosepaste (disabled)")
            button.alphaValue = 0.5
        case .atRest:
            resetIcon()
        }
    }

    private func resetIcon() {
        guard let button = statusItem.button else { return }
        button.image = NSImage(systemSymbolName: "doc.on.clipboard", accessibilityDescription: "choosepaste")
        button.alphaValue = 1.0
    }
}
