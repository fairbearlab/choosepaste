# choosepaste Design System

Minimal native spec. choosepaste should look like a macOS system utility, not a branded app. The brand lives in the product behavior (fast, reliable, trustworthy), not in custom typography or color.

## Typography

All SF Pro (macOS system font). No custom fonts.

| Element | Font | Size | Weight | Opacity |
|---------|------|------|--------|---------|
| Popover header ("choosepaste") | SF Pro | 16pt | Semibold | 100% |
| Clipboard type ("Clipboard: HTML") | SF Pro | 13pt | Regular | 50% |
| Clipboard preview snippet | SF Mono | 12pt | Regular | 70% |
| Transform label ("Plain Text") | SF Pro | 13pt | Regular | 100% |
| Keyboard shortcut ("⌃⌥P") | SF Pro | 12pt | Regular | 50% |

## Colors

Use macOS system semantic colors. No custom hex values. This ensures automatic support for light/dark mode, high contrast, and accessibility settings.

| Element | Color Token |
|---------|------------|
| Popover background | `NSColor.controlBackgroundColor` (grouped) |
| Row hover/focus | `NSColor.selectedContentBackgroundColor` |
| Row text | `NSColor.labelColor` |
| Secondary text | `NSColor.secondaryLabelColor` |
| Success flash | `NSColor.systemGreen` at 30% opacity |
| Error text | `NSColor.systemRed` |
| Separator | `NSColor.separatorColor` |
| Icon box background | `NSColor.quaternaryLabelColor` |
| Icon box text (T/M) | `NSColor.labelColor` |

## Spacing

8px base grid.

| Element | Value |
|---------|-------|
| Popover width | 250px |
| Popover padding | 12px |
| Row height | 36px |
| Row horizontal padding | 8px |
| Gap between rows | 2px |
| Clipboard preview height | ~40px (2 lines max) |
| Header to content gap | 4px |
| Content to separator gap | 8px |
| Separator to rows gap | 4px |

## Corner Radius

| Element | Radius |
|---------|--------|
| Popover | System default (~10px, managed by NSPopover) |
| Icon boxes (T/M) | 4px |
| Clipboard preview box | 4px |
| Row focus highlight | 4px |

## Icons

### Transform Icons

Boxed single-letter icons in small rounded squares (20x20px, 4px radius).

| Transform | Icon | Style |
|-----------|------|-------|
| Plain Text | **T** | 13pt SF Pro Semibold, centered in box |
| Markdown | **M** | 13pt SF Pro Semibold, centered in box |

### Menu Bar Icon

| State | Icon | Duration |
|-------|------|----------|
| At rest | SF Symbol: `doc.on.clipboard` | Persistent |
| Transform in progress | SF Symbol: `doc.on.clipboard` with subtle pulse | Until complete |
| Success | SF Symbol: `checkmark` | 0.5s, then return to rest |
| Error | SF Symbol: `exclamationmark.triangle` | 2s, then return to rest |
| Empty clipboard | SF Symbol: `questionmark` | 1s, then return to rest |
| Disabled (no permission) | SF Symbol: `doc.on.clipboard` at 50% opacity | Until permission granted |

**Reduced Motion:** When `NSWorkspace.shared.accessibilityDisplayShouldReduceMotion` is true, skip the pulse animation. Use instant icon swap instead.

## Popover Behavior

| Property | Value |
|----------|-------|
| Anchor | Cursor position (NSEvent.mouseLocation) |
| Offset | 12px above cursor |
| Edge avoidance | Reposition if within 20px of screen edge |
| Arrow | Points downward toward cursor |
| Dismiss | Click outside, Escape key, or after successful transform |

## Success Feedback

| Path | Visual | Duration |
|------|--------|----------|
| Popover transform | Selected row background flashes `systemGreen` at 30% | 300ms, then popover closes |
| Direct hotkey | Menu bar icon swaps to checkmark | 500ms, then returns to rest |
| Auto-paste failed | Menu bar checkmark + brief text near cursor: "Copied. Press ⌘V" | 2s |

## Keyboard Navigation

| Key | Action |
|-----|--------|
| `↑` `↓` | Move selection between rows |
| `↵` (Return) | Execute selected transform |
| `⎋` (Escape) | Dismiss popover, no action |
| `1` | Execute Plain Text (row 1) |
| `2` | Execute Markdown (row 2) |
| `Tab` | Cycle focus (wraps) |

First row is focused when popover opens.

## VoiceOver

Each transform row announces: "[Transform name], option [N] of [total], keyboard shortcut [shortcut description]"

Example: "Plain Text, option 1 of 2, keyboard shortcut Control Option P"

## Design Decisions Log

| Decision | Choice | Rationale |
|----------|--------|-----------|
| Font | SF Pro system | Native feel, no brand overhead for a utility |
| Colors | System semantic | Automatic dark/light, high contrast, accessibility |
| Popover anchor | Cursor | User is looking at insertion point, not menu bar |
| Success feedback | Icon flash (no notification) | Too frequent for notifications (20x/day) |
| Preview | Inline snippet (60 chars) | Builds trust before committing to transform |
| Auto-paste | Default on, fallback to clipboard | Seamless experience with reliable fallback |
| First-run | Demo-first | Show value before asking for permission |
| Custom brand | Deferred | Ship with system icons, design brand after product-market fit |
