import SwiftUI

class TransformPopoverViewModel: ObservableObject {
    let clipboard: ClipboardSnapshot
    let dismiss: () -> Void

    @Published var selectedIndex: Int = 0
    @Published var flashIndex: Int? = nil

    let transforms: [(name: String, label: String, icon: String, shortcut: String)] = [
        (name: "plaintext", label: "Plain Text", icon: "T", shortcut: "⌃⌥P"),
        (name: "markdown", label: "Markdown", icon: "M", shortcut: "⌃⌥M"),
    ]

    init(clipboard: ClipboardSnapshot, dismiss: @escaping () -> Void) {
        self.clipboard = clipboard
        self.dismiss = dismiss
    }

    func execute(at index: Int) {
        guard index >= 0, index < transforms.count else { return }
        let transform = transforms[index]

        guard !clipboard.isEmpty else { return }

        TransformBridge.shared.transform(
            name: transform.name,
            content: clipboard.content,
            contentType: clipboard.contentType
        ) { [weak self] result in
            DispatchQueue.main.async {
                switch result {
                case .success(let text):
                    ClipboardService.shared.write(text)
                    self?.flashIndex = index
                    AutoPasteService.shared.paste()

                    // Flash green then dismiss
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                        self?.dismiss()
                    }
                case .failure:
                    // Keep popover open on error
                    break
                }
            }
        }
    }

    func moveUp() {
        selectedIndex = max(0, selectedIndex - 1)
    }

    func moveDown() {
        selectedIndex = min(transforms.count - 1, selectedIndex + 1)
    }
}

struct TransformPopoverView: View {
    @ObservedObject var viewModel: TransformPopoverViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header
            VStack(alignment: .leading, spacing: 4) {
                Text("choosepaste")
                    .font(.system(size: 16, weight: .semibold))

                Text("Clipboard: \(viewModel.clipboard.typeLabel)")
                    .font(.system(size: 13))
                    .foregroundColor(.secondary)
            }
            .padding(.horizontal, 12)
            .padding(.top, 12)
            .padding(.bottom, 4)

            // Clipboard preview
            if !viewModel.clipboard.isEmpty {
                Text(viewModel.clipboard.preview)
                    .font(.system(size: 12, design: .monospaced))
                    .foregroundColor(.primary.opacity(0.7))
                    .lineLimit(2)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(8)
                    .background(Color.primary.opacity(0.05))
                    .cornerRadius(4)
                    .padding(.horizontal, 12)
                    .padding(.bottom, 8)
            }

            Divider()
                .padding(.horizontal, 12)
                .padding(.bottom, 4)

            // Transform rows
            ForEach(Array(viewModel.transforms.enumerated()), id: \.offset) { index, transform in
                TransformRow(
                    icon: transform.icon,
                    label: transform.label,
                    shortcut: transform.shortcut,
                    isSelected: viewModel.selectedIndex == index,
                    isFlashing: viewModel.flashIndex == index
                )
                .contentShape(Rectangle())
                .onTapGesture {
                    viewModel.execute(at: index)
                }
                .accessibilityElement(children: .combine)
                .accessibilityLabel("\(transform.label), option \(index + 1) of \(viewModel.transforms.count), keyboard shortcut \(accessibilityShortcut(transform.shortcut))")
            }
            .padding(.horizontal, 4)
            .padding(.bottom, 8)
        }
        .frame(width: 250)
        .background(KeyEventHandlingView(viewModel: viewModel))
    }

    private func accessibilityShortcut(_ shortcut: String) -> String {
        shortcut
            .replacingOccurrences(of: "⌃", with: "Control ")
            .replacingOccurrences(of: "⌥", with: "Option ")
            .replacingOccurrences(of: "⌘", with: "Command ")
    }
}

struct KeyEventHandlingView: NSViewRepresentable {
    let viewModel: TransformPopoverViewModel

    func makeNSView(context: Context) -> KeyCaptureView {
        let view = KeyCaptureView()
        view.onKeyDown = { event in
            handleKey(event)
        }
        return view
    }

    func updateNSView(_ nsView: KeyCaptureView, context: Context) {}

    private func handleKey(_ event: NSEvent) {
        switch event.keyCode {
        case 126: // up arrow
            viewModel.moveUp()
        case 125: // down arrow
            viewModel.moveDown()
        case 36: // return
            viewModel.execute(at: viewModel.selectedIndex)
        case 53: // escape
            viewModel.dismiss()
        case 48: // tab
            viewModel.moveDown()
            if viewModel.selectedIndex >= viewModel.transforms.count - 1 {
                viewModel.selectedIndex = 0
            }
        default:
            // Number keys 1-2 for direct selection
            if let chars = event.characters, let num = Int(chars), num >= 1, num <= viewModel.transforms.count {
                viewModel.execute(at: num - 1)
            }
        }
    }
}

class KeyCaptureView: NSView {
    var onKeyDown: ((NSEvent) -> Void)?

    override var acceptsFirstResponder: Bool { true }

    override func viewDidMoveToWindow() {
        super.viewDidMoveToWindow()
        window?.makeFirstResponder(self)
    }

    override func keyDown(with event: NSEvent) {
        onKeyDown?(event)
    }
}
