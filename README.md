# choosepaste

[![CI](https://github.com/fairbearlab/choosepaste/actions/workflows/ci.yml/badge.svg)](https://github.com/fairbearlab/choosepaste/actions/workflows/ci.yml)
[![OpenSSF Scorecard](https://api.scorecard.dev/projects/github.com/fairbearlab/choosepaste/badge)](https://scorecard.dev/viewer/?uri=github.com/fairbearlab/choosepaste)
[![Release](https://img.shields.io/github/v/release/fairbearlab/choosepaste?sort=semver)](https://github.com/fairbearlab/choosepaste/releases)
[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)
[![Platform](https://img.shields.io/badge/platform-macOS-lightgrey)](#)

macOS menu bar utility that transforms clipboard content before pasting. Copy text from anywhere, paste it as clean Plain Text or Markdown into any editor.

## Install

```bash
make bundle
open build/ChoosePaste.app
```

Requires: Go 1.26+, Swift 5.9+, macOS 14+

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
make test      # Run Go engine tests (-race)
make lint      # golangci-lint on the Go engine
make ci        # Everything CI runs for the engine: vet, lint, test, vulncheck, build
make engine    # Build Go engine (universal binary)
make app       # Build Swift app
make bundle    # Build everything + assemble .app bundle
make run       # Build and launch
make clean     # Remove build artifacts
```

## License

MIT. Copyright 2026 Fair Bear Labs.
