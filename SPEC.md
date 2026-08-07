# choosepaste — Safe Paste for AI Power Users

## What Is This

A macOS menu bar utility that transforms clipboard content before pasting. Copy text from Claude Code, ChatGPT, or a browser — paste it as clean Plain Text or Markdown into Codex, VS Code, or any editor. No app window, just a hotkey and a cursor-anchored popover.

The narrowest wedge: preserve prompt integrity and formatting intent when moving text between AI-heavy tools.

## Why This Matters

* 9to5Mac published "Here's one Microsoft PowerToys feature I really hope Apple copies" (Nov 2025)
* macOS Tahoe added clipboard history to Spotlight but zero transformation
* Maccy, Paste, CopyClip — all clipboard managers, none transform content
* Keyboard Maestro can do it but costs $36 and requires building each workflow manually
* Apple Shortcuts can do it but is janky, slow, and non-discoverable

The specific pain: a software engineer copies a response from Claude Code, pastes it into Codex, and the whole prompt breaks due to poor copy/paste formatting handling. This happens 20+ times per day.

## Target User

A software engineer who frequently copies text from Claude Code, ChatGPT, browsers, or docs and pastes it into Codex, VS Code, or another AI prompt/editor surface.

What they care about: preserving readability, preserving intended structure, reducing manual cleanup, staying in flow.

## Core Experience

```
User copies text → hits ⌘⌥V → cursor-anchored popover appears → picks transform → transformed text replaces clipboard + auto-pastes → done
```

Direct hotkeys bypass the popover entirely:
* `⌃⌥P` → transform to plain text, replace clipboard, auto-paste
* `⌃⌥M` → transform to Markdown, replace clipboard, auto-paste
* `⌘⌥V` → open popover with transform options

All hotkeys user-configurable (post-V1). Note: ⌘⌥V conflicts with Finder's "Move Item Here." CGEvent tap must consume (not pass through) registered hotkeys to prevent dual-action in the active app.

## V1 Scope

**In scope:**
* Plain Text transform (strip HTML/RTF to clean plain text)
* Markdown transform (HTML/rich text to clean Markdown)
* That's it. Two transforms.

**Explicitly NOT in V1:**
* JSON formatting, URL encode/decode, trim/clean, code block
* AI transforms (summarize, translate, fix grammar)
* OCR / image text extraction
* Clipboard history
* Custom actions / prompt templates
* Chain transforms
* Raycast extension
* Settings UI (hotkeys are hardcoded for V1)
* Pricing / Pro tier
* Mac App Store distribution

## Architecture

```
┌─────────────────────────────────────────────┐
│  macOS Menu Bar App (Swift/SwiftUI)         │
│  - Global hotkey listener (CGEvent tap)     │
│  - Cursor-anchored popover (SwiftUI)        │
│  - Clipboard read/write (NSPasteboard)      │
│  - RTF→HTML pre-conversion (NSAttributedString) │
│  - Menu bar icon with state feedback        │
│  - First-run onboarding flow                │
└──────────────┬──────────────────────────────┘
               │ stdin/stdout JSON bridge
┌──────────────▼──────────────────────────────┐
│  Transform Engine (Go binary, invoked CLI)  │
│  - Plain text stripper                      │
│  - HTML → Markdown                          │
└─────────────────────────────────────────────┘
```

### Swift + Go Hybrid

* **Swift** for the native shell: menu bar presence, hotkey registration, pasteboard access, popover UI, system permissions, auto-paste via Accessibility API. ~500 lines of SwiftUI.
* **Go** for the transform engine: portable, testable, pure functions. Shipped as an embedded binary in the app bundle.
* **Communication:** Swift shells out to the Go binary with clipboard content on stdin as JSON, gets transformed content on stdout as JSON. Simple, debuggable.

### Go Engine CLI Interface

```bash
# JSON bridge: structured input/output
echo '{"transform":"markdown","content":"<h1>Hello</h1><p>World</p>","content_type":"html"}' | choosepaste-engine
# Output: {"result":"# Hello\n\nWorld","success":true}

echo '{"transform":"plaintext","content":"<b>Bold</b> and <i>italic</i>","content_type":"html"}' | choosepaste-engine
# Output: {"result":"Bold and italic","success":true}

# RTF input: pre-convert to HTML internally, then transform
echo '{"transform":"markdown","content":"{\\rtf1\\ansi...}","content_type":"rtf"}' | choosepaste-engine
# Output: {"result":"# Heading\n\nParagraph text","success":true}

# Error case
echo '{"transform":"unknown","content":"test","content_type":"text"}' | choosepaste-engine
# Output: {"result":"","success":false,"error":"unknown transform: unknown"}

# List available transforms
choosepaste-engine --list
# Output: plaintext, markdown
```

### TransformBridge Error Handling

The Swift side must handle three failure modes from the Go process:

| Failure Mode | Detection | Response |
|-------------|-----------|----------|
| **Exit non-zero + valid JSON** | `Process.terminationStatus != 0` AND stdout parses as JSON with `success: false` | Show error message from `error` field. Preserve original clipboard. |
| **Invalid/garbled JSON** | stdout doesn't parse as valid JSON | Show "Transform failed. Original clipboard preserved." Log raw output for debugging. |
| **Timeout/hang** | Process doesn't complete within 2 seconds | Kill process. Show "Transform timed out. Original clipboard preserved." |

In ALL failure cases: the original clipboard content must be preserved. Never leave the user with a corrupted or empty clipboard.

## UI Design

### Popover

The popover is cursor-anchored (appears near the text cursor, not the menu bar) because this is a paste utility and the user is looking at the insertion point.

```
┌─────────────────────────────────────┐
│  choosepaste              [header]  │  16pt SF Pro Semibold
│  Clipboard: HTML          [context] │  13pt SF Pro Regular, 50% opacity
│ ┌─────────────────────────────────┐ │
│ │ <h1>API Response</h1><p>Th...   │ │  12pt SF Pro Mono, clipboard preview
│ └─────────────────────────────────┘ │  first ~60 chars, truncated
│─────────────────────────────────────│
│  [T] Plain Text            ⌃⌥P     │  13pt SF Pro Regular, full-width row
│  [M] Markdown              ⌃⌥M     │  Shortcut: 12pt, 50% opacity
└─────────────────────────────────────┘
         ▼ (caret points to cursor)
```

* Width: ~250px
* Row height: 36px
* Padding: 12px
* Icon boxes: 20x20px, 4px corner radius, monochrome
* Background: macOS system dark grouped background
* Spacing: 8px grid
* First row focused on open (arrow keys move selection)

### Keyboard Navigation

* `↑↓` — move selection between rows
* `↵` — execute selected transform
* `⎋` — dismiss popover without action
* `1` — execute Plain Text (row 1)
* `2` — execute Markdown (row 2)
* `Tab` — cycle focus (wraps)

### Menu Bar Icon States

* **At rest:** SF Symbol `doc.on.clipboard` (18x18px, monochrome). Custom icon later.
* **Transform in progress:** Brief spinner or pulse animation
* **Success:** Checkmark shape for 0.5s, return to rest
* **Error:** Exclamation for 2s, return to rest
* **Reduced Motion:** Shape change only, no animation

### Clipboard Handling

* Clipboard content is snapshotted when the popover opens (or when a direct hotkey is pressed)
* Transform operates on the snapshot, immune to clipboard changes during the popover session
* On success: transformed text replaces clipboard content
* Auto-paste: attempt to simulate ⌘V via Accessibility API after replacing clipboard
* Auto-paste fallback: if synthetic paste fails, clipboard still has transformed content. Menu bar shows checkmark. Optionally show brief toast "Copied. Press ⌘V to paste."

### Success Feedback

**Popover path:** Selected row flashes green for 300ms, then popover closes. Menu bar icon shows checkmark for 0.5s.

**Direct hotkey path:** Menu bar icon shows checkmark for 0.5s, then returns to rest. No popover appears.

### Interaction States

| State | Popover Behavior | Direct Hotkey Behavior |
|-------|-----------------|----------------------|
| **Happy path** | Row flashes green (300ms), popover closes, auto-paste | Menu bar checkmark (0.5s), auto-paste |
| **Empty clipboard** | "Nothing on your clipboard. Copy something first." | Menu bar shows "?" briefly |
| **Unsupported type** | Both options dimmed, "Text content only" | Menu bar shows "?" briefly |
| **Transform error** | "Transform failed. Original clipboard preserved." + Retry | Menu bar exclamation (2s) |
| **Loading** | Subtle pulse on selected row (~200ms for local transforms) | Menu bar brief spinner |
| **Auto-paste failed** | Checkmark + "Copied. Press ⌘V to paste." | Checkmark + brief toast near cursor |

### First-Run Onboarding

Demo-first, then permission. Show value before asking for Accessibility access.

1. On first launch, menu bar icon appears
2. Popover opens automatically with demo clipboard content (sample HTML: `<h1>API Response</h1><p>The endpoint returns a JSON object...</p>`)
3. User clicks "Plain Text" to see the transform work
4. Shows result: "API Response — The endpoint returns a JSON object..."
5. "Nice! Enable hotkeys so you can do this with ⌃⌥P from any app."
6. Opens System Settings > Privacy > Accessibility
7. On permission granted: "You're set. Try ⌃⌥P now." with a demo clipboard to test
8. On permission deferred: Menu bar icon shows disabled state. Click menu bar icon to re-prompt.

## Accessibility

* VoiceOver: Each transform row announces "Plain Text, option 1 of 2, keyboard shortcut Control Option P"
* Reduced Motion: `NSWorkspace.shared.accessibilityDisplayShouldReduceMotion` — icon changes shape instead of animating
* Contrast: System dark mode colors meet WCAG AA
* Click targets: Full row width, not just text
* Edge avoidance: Popover repositions if cursor is near screen edge

## Project Structure

```
choosepaste/
├── ChoosePaste/                    # Swift/SwiftUI app
│   ├── App/
│   │   ├── ChoosePasteApp.swift    # @main entry, menu bar setup
│   │   ├── AppDelegate.swift       # CGEvent tap, hotkey registration
│   │   └── StatusBarController.swift # Menu bar icon + state management
│   ├── Views/
│   │   ├── TransformPopover.swift  # Cursor-anchored popover
│   │   ├── TransformRow.swift      # Individual transform option
│   │   └── OnboardingView.swift    # First-run flow
│   ├── Services/
│   │   ├── ClipboardService.swift  # NSPasteboard wrapper + snapshot
│   │   ├── HotkeyService.swift     # Global hotkey management
│   │   ├── TransformBridge.swift   # Calls Go binary via Process()
│   │   └── AutoPasteService.swift  # Synthetic ⌘V via Accessibility
│   └── Resources/
│       └── choosepaste-engine      # Embedded Go binary
├── engine/                         # Go transform engine
│   ├── cmd/
│   │   └── choosepaste-engine/
│   │       └── main.go             # CLI entry: JSON stdin → transform → JSON stdout
│   ├── transforms/
│   │   ├── plaintext.go
│   │   ├── plaintext_test.go
│   │   ├── markdown.go
│   │   └── markdown_test.go
│   └── go.mod
├── scripts/
│   ├── build.sh                    # Build Go binary + Swift app
│   └── package.sh                  # Create DMG
├── Makefile
├── SPEC.md                         # This file
├── DESIGN.md                       # Design system (to be written)
├── TODOS.md
└── README.md
```

## Tech Stack

| Layer | Technology | Notes |
|-------|-----------|-------|
| Menu bar + UI | Swift 5.9+ / SwiftUI | macOS 14+ target. Menu bar only (LSUIElement) |
| Hotkeys | CGEvent tap | Requires Accessibility permission |
| Clipboard | NSPasteboard | Read all types (HTML, RTF, plain), snapshot on trigger |
| Popover anchor | AXBoundsForRange (text caret) with NSEvent.mouseLocation fallback + invisible NSWindow | Cursor-anchored via Accessibility API for text caret position, falls back to mouse location, uses borderless positioning window, edge-avoidance |
| Transform engine | Go 1.22+ | Compiled binary, embedded in app bundle |
| HTML→Markdown | `github.com/JohannesKaufmann/html-to-markdown` | Best Go lib for this |
| Distribution | DMG + Homebrew cask (later) | Notarized, signed |

## User Permissions Required

* **Accessibility** — for global hotkey capture (CGEvent tap) and auto-paste (synthetic ⌘V)
* **Paste permission** — macOS 14+ may prompt for clipboard access

## Success Criteria for V1

* [ ] Menu bar icon with cursor-anchored popover showing Plain Text and Markdown
* [ ] Clipboard content preview in popover (first ~60 chars)
* [ ] Global hotkey ⌘⌥V opens popover near cursor
* [ ] Direct hotkeys ⌃⌥P (plain text) and ⌃⌥M (Markdown) work without popover
* [ ] Auto-paste after transform with fallback to clipboard-only
* [ ] Menu bar icon feedback (checkmark on success, exclamation on error)
* [ ] Keyboard navigation in popover (arrow keys, Return, Escape, 1/2)
* [ ] First-run onboarding with demo-first, then permission request
* [ ] VoiceOver and Reduced Motion support
* [ ] Transforms work on: HTML, RTF, plain text clipboard content
* [ ] Go engine passes all transform unit tests
* [ ] Builds as single .app bundle with embedded Go binary
* [ ] Works on macOS 14 Sonoma and later

## Implementation Order

1. **Swift shell first.** Minimal menu bar app with hardcoded inline transforms (strip HTML tags, basic HTML-to-Markdown). Prove macOS integration: CGEvent tap hotkeys register, popover appears at text caret position, clipboard read/write works, auto-paste via Accessibility API works, code signing passes. This de-risks the hard part.
2. **Popover UI.** Cursor-anchored SwiftUI popover with clipboard preview, keyboard navigation. RTF-to-HTML pre-conversion via NSAttributedString.
3. **Go engine.** Extract transforms into Go binary. Build and test Plain Text and Markdown as pure functions. JSON stdin/stdout bridge. Comprehensive tests. Wire TransformBridge to replace inline transforms.
4. **Auto-paste refinement.** Synthetic ⌘V with fallback toast. Test across target apps (VS Code, Codex, Chrome).
5. **First-run onboarding.** Demo-first flow with permission request.
6. **Build pipeline.** Makefile that builds Go binary for arm64+amd64, embeds in Swift app bundle, produces DMG.

## Markdown Quality Bar

The Go engine tests must include a real-world fixture corpus: HTML samples copied from Claude Code, ChatGPT, browser pages, and rich text editors, paired with expected Markdown output. At minimum, fixtures must cover:

* Headings (h1-h4), paragraphs, line breaks
* Ordered and unordered lists, nested lists
* Inline code and fenced code blocks (with language hints)
* Links (inline and reference), images
* Bold, italic, strikethrough, inline formatting
* Tables (from ChatGPT, Claude Code)
* Blockquotes (nested)
* Mixed content (code blocks inside lists, links inside headings)

Each fixture is a `.html` input file and a `.md` expected output file in `engine/testdata/fixtures/`. Tests compare actual output against expected. This IS the acceptance criteria for "clean Markdown."

## Known V1 Limitations

* **Clipboard replacement is destructive.** After a successful transform, the original clipboard content is replaced. Users who want the original back must re-copy from the source. Clipboard restoration after paste is deferred to post-V1 based on alpha feedback.

## Distribution Plan

1. **GitHub Releases** — signed macOS app for early alpha testers
2. **Direct DMG** from choosepaste.dev — signed + notarized
3. **Homebrew Cask** — after install demand is proven

## Latency Budget

The app is a hotkey utility. Users feel latency immediately.

* **Target:** < 100ms from hotkey press to clipboard replacement (local transforms)
* **Measurement:** Instrument in alpha build, track P50/P95
* **Escalation:** If Process() invocation consistently exceeds 50ms, evaluate persistent Go helper process (see TODOS.md)

## Open Questions (Resolved)

* ~~Pure Swift vs Swift+Go hybrid?~~ → Hybrid. Go for testable transforms, Swift for native shell.
* ~~Should the popover show a preview?~~ → Yes. Inline clipboard snippet, first ~60 chars.
* ~~Accessibility permission UX?~~ → Demo-first onboarding. Show value before asking.
* ~~Popover vs direct hotkeys vs both?~~ → Both. Popover for discovery, direct hotkeys for speed.
* ~~Where does the popover appear?~~ → Cursor-anchored, not menu bar.
* ~~Auto-paste or clipboard-only?~~ → Auto-paste by default, fallback to clipboard-only.
* ~~Success feedback for direct hotkeys?~~ → Menu bar icon checkmark flash (0.5s).

## Approved Mockups

| Screen | Description | Notes |
|--------|------|-------|
| Popover (final) | Cursor-anchored popover, dark mode, clipboard preview | Cursor-anchored, dark mode, clipboard preview, boxed T/M icons. Modifier glyphs need ⌃⌥ in implementation. |
