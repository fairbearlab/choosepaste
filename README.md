# choosepaste

[![ci](https://github.com/fairbearlab/choosepaste/actions/workflows/ci.yml/badge.svg)](https://github.com/fairbearlab/choosepaste/actions/workflows/ci.yml)

macOS menu bar utility that transforms clipboard content before pasting. Copy text from Claude Code, ChatGPT, or a browser, paste it as clean Plain Text or Markdown into any editor.

## Install

```bash
make bundle
open build/ChoosePaste.app
```

Requires: Go 1.22+, Swift 5.9+, macOS 14+

## Usage

| Hotkey      | Action                              |
| ----------- | ----------------------------------- |
| Cmd+Opt+V   | Open popover with transform options |
| Ctrl+Opt+P  | Paste as plain text (direct)        |
| Ctrl+Opt+M  | Paste as Markdown (direct)          |

Accessibility permission is required for global hotkeys.

## Architecture

```text
Swift menu bar app (SwiftUI)
  |
  |-- Global hotkey listener (CGEvent tap)
  |-- Clipboard read/write (NSPasteboard)
  |-- Cursor-anchored popover
  |
  v
Go transform engine (stdin/stdout JSON)
  |-- HTML -> Markdown (html-to-markdown library)
  |-- HTML -> Plain text (tag stripping + entity decoding)
  |-- RTF -> HTML (pre-converted by Swift) -> transform
```

## Development

```bash
make test      # Run Go engine tests
make engine    # Build Go engine (universal binary)
make app       # Build Swift app
make bundle    # Build everything + assemble .app bundle
make run       # Build and launch
make clean     # Remove build artifacts
```

## License

MIT. Copyright 2026 Fair Bear Labs.
