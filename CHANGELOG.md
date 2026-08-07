# Changelog

All notable changes to this project will be documented in this file.

## [0.1.0.0] - 2026-04-08

### Added
- macOS menu bar app with cursor-anchored popover for clipboard transforms
- Global hotkeys: Cmd+Opt+V (popover), Ctrl+Opt+P (plain text), Ctrl+Opt+M (markdown)
- Go transform engine with HTML-to-Markdown (via html-to-markdown library) and HTML-to-plain-text
- RTF clipboard content auto-converted to HTML before transform
- Inline Swift fallback transforms when the Go engine binary is unavailable
- Auto-paste via simulated Cmd+V after transform completes
- Fixture-based test suite with real-world HTML samples (Claude Code, ChatGPT, browser articles)

### Fixed
- Engine binary path resolution now checks Contents/MacOS/ (sibling of main executable), not just Resources/
- Pipe deadlock on large clipboard payloads: stdout is read before waitUntilExit
- Memory leak from unbalanced Unmanaged.passRetained in hotkey event tap
- Clipboard snapshot (RTF conversion) moved off main thread to prevent UI stalls
- Inline regex compilation hoisted to package-level vars for performance
