import Cocoa

struct ClipboardSnapshot {
    let content: String
    let contentType: String // "html", "rtf", "text"
    let preview: String     // first ~60 chars for display

    static let empty = ClipboardSnapshot(content: "", contentType: "text", preview: "")

    var isEmpty: Bool { content.isEmpty }
    var typeLabel: String {
        switch contentType {
        case "html": return "HTML"
        case "rtf": return "RTF"
        default: return "Plain Text"
        }
    }
}

class ClipboardService {
    static let shared = ClipboardService()

    private init() {}

    func snapshot() -> ClipboardSnapshot {
        let pasteboard = NSPasteboard.general

        // Try HTML first
        if let html = pasteboard.string(forType: .html) {
            return ClipboardSnapshot(
                content: html,
                contentType: "html",
                preview: makePreview(from: stripTagsForPreview(html))
            )
        }

        // Try RTF: convert to HTML via NSAttributedString
        if let rtfData = pasteboard.data(forType: .rtf) {
            if let attributed = NSAttributedString(rtf: rtfData, documentAttributes: nil) {
                // Convert to HTML for the engine
                if let htmlData = try? attributed.data(
                    from: NSRange(location: 0, length: attributed.length),
                    documentAttributes: [.documentType: NSAttributedString.DocumentType.html]
                ), let html = String(data: htmlData, encoding: .utf8) {
                    return ClipboardSnapshot(
                        content: html,
                        contentType: "html",
                        preview: makePreview(from: attributed.string)
                    )
                }

                // Fallback: use plain string from attributed
                return ClipboardSnapshot(
                    content: attributed.string,
                    contentType: "text",
                    preview: makePreview(from: attributed.string)
                )
            }
        }

        // Plain text
        if let text = pasteboard.string(forType: .string) {
            return ClipboardSnapshot(
                content: text,
                contentType: "text",
                preview: makePreview(from: text)
            )
        }

        return .empty
    }

    func write(_ text: String) {
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setString(text, forType: .string)
    }

    private func makePreview(from text: String) -> String {
        let cleaned = text
            .replacingOccurrences(of: "\n", with: " ")
            .replacingOccurrences(of: "\r", with: " ")
            .trimmingCharacters(in: .whitespacesAndNewlines)

        if cleaned.count <= 60 {
            return cleaned
        }
        return String(cleaned.prefix(57)) + "..."
    }

    private func stripTagsForPreview(_ html: String) -> String {
        // Quick tag strip for preview only (engine does the real transform)
        html.replacingOccurrences(
            of: "<[^>]+>",
            with: "",
            options: .regularExpression
        )
    }
}
