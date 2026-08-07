import Foundation

class TransformBridge {
    static let shared = TransformBridge()

    private let enginePath: String

    private init() {
        // Engine binary lives alongside the main executable in Contents/MacOS/
        if let execURL = Bundle.main.executableURL {
            let siblingPath = execURL.deletingLastPathComponent()
                .appendingPathComponent("choosepaste-engine").path
            if FileManager.default.isExecutableFile(atPath: siblingPath) {
                enginePath = siblingPath
                return
            }
        }

        // Also check Resources/ in case the bundle layout changes
        if let resourcePath = Bundle.main.path(forResource: "choosepaste-engine", ofType: nil) {
            enginePath = resourcePath
            return
        }

        #if DEBUG
        // Development fallback: look in build directory relative to the project
        let devPath = FileManager.default.currentDirectoryPath + "/build/choosepaste-engine"
        if FileManager.default.fileExists(atPath: devPath) {
            enginePath = devPath
            return
        }
        #endif

        enginePath = "" // Engine not found; will fall back to inline transforms
    }

    struct Request: Codable {
        let transform: String
        let content: String
        let contentType: String

        enum CodingKeys: String, CodingKey {
            case transform
            case content
            case contentType = "content_type"
        }
    }

    struct Response: Codable {
        let result: String
        let success: Bool
        let error: String?
    }

    func transform(name: String, content: String, contentType: String,
                   completion: @escaping (Result<String, Error>) -> Void) {
        DispatchQueue.global(qos: .userInitiated).async { [self] in
            let result = self.transformSync(name: name, content: content, contentType: contentType)
            completion(result)
        }
    }

    func transformSync(name: String, content: String, contentType: String) -> Result<String, Error> {
        // Try external engine first, fall back to inline transforms
        if FileManager.default.isExecutableFile(atPath: enginePath) {
            return callEngine(name: name, content: content, contentType: contentType)
        }
        return inlineTransform(name: name, content: content, contentType: contentType)
    }

    private func callEngine(name: String, content: String, contentType: String) -> Result<String, Error> {
        let request = Request(transform: name, content: content, contentType: contentType)

        guard let inputData = try? JSONEncoder().encode(request) else {
            return .failure(TransformError.encodingFailed)
        }

        let process = Process()
        process.executableURL = URL(fileURLWithPath: enginePath)

        let stdin = Pipe()
        let stdout = Pipe()
        let stderr = Pipe()
        process.standardInput = stdin
        process.standardOutput = stdout
        process.standardError = stderr

        do {
            try process.run()
        } catch {
            // Engine not available, use inline fallback
            return inlineTransform(name: name, content: content, contentType: contentType)
        }

        stdin.fileHandleForWriting.write(inputData)
        stdin.fileHandleForWriting.closeFile()

        // Timeout: kill after 2 seconds
        let timer = DispatchSource.makeTimerSource()
        timer.schedule(deadline: .now() + 2.0)
        timer.setEventHandler { process.terminate() }
        timer.resume()

        // Read stdout BEFORE waitUntilExit to prevent pipe deadlock:
        // if the child's output exceeds pipe buffer capacity, the child blocks
        // on write while the parent blocks on exit, causing a deadlock.
        let outputData = stdout.fileHandleForReading.readDataToEndOfFile()

        process.waitUntilExit()
        timer.cancel()

        guard let response = try? JSONDecoder().decode(Response.self, from: outputData) else {
            return .failure(TransformError.invalidResponse)
        }

        if response.success {
            return .success(response.result)
        } else {
            return .failure(TransformError.engineError(response.error ?? "unknown error"))
        }
    }

    // Hardcoded inline transforms for when the Go engine isn't available.
    // These are intentionally simple - the real transforms live in the Go engine.
    private func inlineTransform(name: String, content: String, contentType: String) -> Result<String, Error> {
        switch name {
        case "plaintext":
            return .success(inlinePlainText(content, contentType: contentType))
        case "markdown":
            // Without the Go engine, just strip HTML as a basic fallback
            return .success(inlinePlainText(content, contentType: contentType))
        default:
            return .failure(TransformError.unknownTransform(name))
        }
    }

    private func inlinePlainText(_ content: String, contentType: String) -> String {
        guard contentType == "html" else { return content.trimmingCharacters(in: .whitespacesAndNewlines) }

        // Basic HTML tag stripping
        var text = content

        // Block elements to newlines
        let blockPattern = try! NSRegularExpression(pattern: "</?(p|div|h[1-6]|li|tr|blockquote)\\b[^>]*>", options: .caseInsensitive)
        text = blockPattern.stringByReplacingMatches(in: text, range: NSRange(text.startIndex..., in: text), withTemplate: "\n")

        // <br> to newline
        let brPattern = try! NSRegularExpression(pattern: "<br\\s*/?>", options: .caseInsensitive)
        text = brPattern.stringByReplacingMatches(in: text, range: NSRange(text.startIndex..., in: text), withTemplate: "\n")

        // Strip remaining tags
        let tagPattern = try! NSRegularExpression(pattern: "<[^>]+>")
        text = tagPattern.stringByReplacingMatches(in: text, range: NSRange(text.startIndex..., in: text), withTemplate: "")

        // Decode common entities
        text = text
            .replacingOccurrences(of: "&amp;", with: "&")
            .replacingOccurrences(of: "&lt;", with: "<")
            .replacingOccurrences(of: "&gt;", with: ">")
            .replacingOccurrences(of: "&quot;", with: "\"")
            .replacingOccurrences(of: "&#39;", with: "'")
            .replacingOccurrences(of: "&nbsp;", with: " ")

        // Collapse whitespace
        let wsPattern = try! NSRegularExpression(pattern: "[ \\t]+")
        text = wsPattern.stringByReplacingMatches(in: text, range: NSRange(text.startIndex..., in: text), withTemplate: " ")

        // Collapse blank lines
        let blankPattern = try! NSRegularExpression(pattern: "\\n{3,}")
        text = blankPattern.stringByReplacingMatches(in: text, range: NSRange(text.startIndex..., in: text), withTemplate: "\n\n")

        // Trim each line
        text = text.split(separator: "\n", omittingEmptySubsequences: false)
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .joined(separator: "\n")

        return text.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}

enum TransformError: LocalizedError {
    case encodingFailed
    case invalidResponse
    case engineError(String)
    case unknownTransform(String)
    var errorDescription: String? {
        switch self {
        case .encodingFailed: return "Failed to encode transform request"
        case .invalidResponse: return "Transform failed. Original clipboard preserved."
        case .engineError(let msg): return msg
        case .unknownTransform(let name): return "Unknown transform: \(name)"
        }
    }
}
