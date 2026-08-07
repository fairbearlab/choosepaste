import Cocoa
import Carbon.HIToolbox

class HotkeyService {
    private weak var statusBarController: StatusBarController?
    private var eventTap: CFMachPort?

    // Hotkey definitions
    // ⌘⌥V = open popover
    // ⌃⌥P = direct plain text
    // ⌃⌥M = direct markdown
    private static let popoverKey = (keyCode: UInt16(kVK_ANSI_V), modifiers: CGEventFlags([.maskCommand, .maskAlternate]))
    private static let plainTextKey = (keyCode: UInt16(kVK_ANSI_P), modifiers: CGEventFlags([.maskControl, .maskAlternate]))
    private static let markdownKey = (keyCode: UInt16(kVK_ANSI_M), modifiers: CGEventFlags([.maskControl, .maskAlternate]))

    init(statusBarController: StatusBarController) {
        self.statusBarController = statusBarController
    }

    func start() {
        let eventMask: CGEventMask = (1 << CGEventType.keyDown.rawValue)

        // Store self as a pointer to pass into the C callback.
        // Using passUnretained because AppDelegate holds a strong reference to HotkeyService.
        let selfPtr = Unmanaged.passUnretained(self).toOpaque()

        guard let tap = CGEvent.tapCreate(
            tap: .cgSessionEventTap,
            place: .headInsertEventTap,
            options: .defaultTap,
            eventsOfInterest: eventMask,
            callback: { (proxy, type, event, refcon) -> Unmanaged<CGEvent>? in
                guard let refcon = refcon else { return Unmanaged.passUnretained(event) }
                let service = Unmanaged<HotkeyService>.fromOpaque(refcon).takeUnretainedValue()
                return service.handleEvent(proxy: proxy, type: type, event: event)
            },
            userInfo: selfPtr
        ) else {
            print("Failed to create event tap. Accessibility permission required.")
            statusBarController?.flashIcon(state: .disabled)
            return
        }

        eventTap = tap

        let runLoopSource = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, tap, 0)
        CFRunLoopAddSource(CFRunLoopGetCurrent(), runLoopSource, .commonModes)
        CGEvent.tapEnable(tap: tap, enable: true)
    }

    func stop() {
        if let tap = eventTap {
            CGEvent.tapEnable(tap: tap, enable: false)
            eventTap = nil
        }
    }

    private func handleEvent(proxy: CGEventTapProxy, type: CGEventType, event: CGEvent) -> Unmanaged<CGEvent>? {
        // Re-enable tap if it gets disabled (system can do this under load)
        if type == .tapDisabledByTimeout || type == .tapDisabledByUserInput {
            if let tap = eventTap {
                CGEvent.tapEnable(tap: tap, enable: true)
            }
            return Unmanaged.passUnretained(event)
        }

        guard type == .keyDown else { return Unmanaged.passUnretained(event) }

        let keyCode = UInt16(event.getIntegerValueField(.keyboardEventKeycode))
        let flags = event.flags

        // Mask to only modifier keys we care about
        let modifierMask: CGEventFlags = [.maskCommand, .maskControl, .maskAlternate, .maskShift]
        let activeModifiers = flags.intersection(modifierMask)

        // ⌘⌥V → open popover
        if keyCode == Self.popoverKey.keyCode && activeModifiers == Self.popoverKey.modifiers {
            DispatchQueue.main.async {
                self.statusBarController?.showPopoverAtCursor()
            }
            return nil // consume the event
        }

        // ⌃⌥P → direct plain text transform
        if keyCode == Self.plainTextKey.keyCode && activeModifiers == Self.plainTextKey.modifiers {
            DispatchQueue.main.async {
                self.directTransform("plaintext")
            }
            return nil
        }

        // ⌃⌥M → direct markdown transform
        if keyCode == Self.markdownKey.keyCode && activeModifiers == Self.markdownKey.modifiers {
            DispatchQueue.main.async {
                self.directTransform("markdown")
            }
            return nil
        }

        return Unmanaged.passUnretained(event)
    }

    private func directTransform(_ transform: String) {
        // Move clipboard snapshot (including RTF→HTML conversion) off the main thread
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            let clipboard = ClipboardService.shared.snapshot()

            guard !clipboard.isEmpty else {
                DispatchQueue.main.async {
                    self?.statusBarController?.flashIcon(state: .empty)
                }
                return
            }

            let result = TransformBridge.shared.transformSync(
                name: transform,
                content: clipboard.content,
                contentType: clipboard.contentType
            )

            DispatchQueue.main.async {
                switch result {
                case .success(let text):
                    ClipboardService.shared.write(text)
                    AutoPasteService.shared.paste()
                    self?.statusBarController?.flashIcon(state: .success)
                case .failure:
                    self?.statusBarController?.flashIcon(state: .error)
                }
            }
        }
    }
}
