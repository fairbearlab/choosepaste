import Cocoa

class AutoPasteService {
    static let shared = AutoPasteService()

    private init() {}

    /// Simulate ⌘V via CGEvent to auto-paste.
    /// Requires Accessibility permission.
    func paste() {
        // Small delay to ensure clipboard write has propagated
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
            self.simulatePaste()
        }
    }

    private func simulatePaste() {
        let source = CGEventSource(stateID: .hidSystemState)

        // Key down: ⌘V
        guard let keyDown = CGEvent(keyboardEventSource: source, virtualKey: 0x09, keyDown: true) else { return }
        keyDown.flags = .maskCommand

        // Key up: ⌘V
        guard let keyUp = CGEvent(keyboardEventSource: source, virtualKey: 0x09, keyDown: false) else { return }
        keyUp.flags = .maskCommand

        keyDown.post(tap: .cghidEventTap)
        keyUp.post(tap: .cghidEventTap)
    }
}
