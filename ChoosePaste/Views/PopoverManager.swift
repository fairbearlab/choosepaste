import Cocoa
import SwiftUI

class PopoverManager: NSObject {
    private var popover: NSPopover?
    private var positioningWindow: NSWindow?
    private var eventMonitor: Any?

    var isShown: Bool { popover?.isShown ?? false }

    func show(clipboard: ClipboardSnapshot) {
        close()

        let popover = NSPopover()
        popover.contentSize = NSSize(width: 250, height: 180)
        popover.behavior = .transient
        popover.animates = true
        popover.delegate = self

        let viewModel = TransformPopoverViewModel(clipboard: clipboard) { [weak self] in
            self?.close()
        }
        popover.contentViewController = NSHostingController(
            rootView: TransformPopoverView(viewModel: viewModel)
        )

        self.popover = popover

        // Position at cursor
        let mouseLocation = NSEvent.mouseLocation
        let screenFrame = NSScreen.main?.frame ?? .zero

        // Create a tiny invisible window at the cursor position
        let windowSize = NSSize(width: 1, height: 1)
        var origin = NSPoint(
            x: mouseLocation.x - windowSize.width / 2,
            y: mouseLocation.y - 12 // offset below cursor
        )

        // Edge avoidance: keep 20px from screen edges
        origin.x = max(screenFrame.minX + 20, min(origin.x, screenFrame.maxX - 20))
        origin.y = max(screenFrame.minY + 20, min(origin.y, screenFrame.maxY - 20))

        let window = NSWindow(
            contentRect: NSRect(origin: origin, size: windowSize),
            styleMask: .borderless,
            backing: .buffered,
            defer: false
        )
        window.isOpaque = false
        window.backgroundColor = .clear
        window.level = .popUpMenu
        window.orderFront(nil)

        positioningWindow = window

        popover.show(
            relativeTo: window.contentView!.bounds,
            of: window.contentView!,
            preferredEdge: .maxY
        )

        // Monitor for clicks outside to dismiss
        eventMonitor = NSEvent.addGlobalMonitorForEvents(matching: [.leftMouseDown, .rightMouseDown]) { [weak self] _ in
            self?.close()
        }
    }

    func close() {
        popover?.performClose(nil)
        popover = nil
        positioningWindow?.orderOut(nil)
        positioningWindow = nil

        if let monitor = eventMonitor {
            NSEvent.removeMonitor(monitor)
            eventMonitor = nil
        }
    }
}

extension PopoverManager: NSPopoverDelegate {
    func popoverDidClose(_ notification: Notification) {
        positioningWindow?.orderOut(nil)
        positioningWindow = nil

        if let monitor = eventMonitor {
            NSEvent.removeMonitor(monitor)
            eventMonitor = nil
        }
    }
}
