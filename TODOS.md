# TODOS

## Engineering Review

### Re-evaluate Swift to Go bridge latency after alpha

**What:** Measure end-to-end transform latency in the alpha build and only promote the Swift to Go bridge from per-invocation `Process()` to a persistent helper if the hotkey path misses the agreed latency target.

**Why:** The current plan intentionally chooses the simpler architecture first. That is good for V1, but the app is a hotkey utility and users will feel latency immediately if the bridge is too slow.

**Context:** The eng review chose the boring path for V1: keep `Process()` and set an explicit latency budget rather than building a long-lived helper up front. This TODO is the guardrail that turns that decision into a measurable checkpoint instead of a vague future optimization. Capture real timings from the alpha flow, especially `Plain Text` and `Markdown` transforms from rich clipboard content, before deciding whether to introduce a persistent helper.

**Effort:** S
**Priority:** P1
**Depends on:** Alpha build available with benchmarkable transform flow

### Add GitHub Actions release workflow

**What:** Create `.github/workflows/release.yml` to build the universal Go engine binary and assemble the .app bundle on push to main or tag creation.

**Why:** Currently the Makefile handles local builds, but there's no CI/CD pipeline to produce release artifacts automatically. Users and contributors can't download a pre-built binary after merge.

**Context:** Deferred from /ship pre-flight check. The Makefile already handles the full build process (Go universal binary + Swift app + bundle assembly), so the workflow mainly needs to replicate those steps on GitHub-hosted macOS runners.

**Effort:** S
**Priority:** P2
**Depends on:** None

## Design Review

### Design first-run onboarding flow

**What:** Spec the first-run experience: demo-first, then permission request. Define the exact welcome state (popover opens automatically with demo clipboard content), demo clipboard content (sample HTML that demonstrates the transform), permission request copy ("Enable hotkeys to transform your clipboard instantly"), success confirmation ("You're set. Try ⌃⌥P now."), and what happens if the user defers permission (menu bar shows disabled state, click to re-prompt).

**Why:** First-run is where most utility apps lose users. The design review decided on demo-first to show value before asking for Accessibility permission. This flow needs concrete copy and states before implementation.

**Context:** macOS Accessibility permission is required for global hotkeys (CGEvent tap). Without it, the app can't function. The demo-first approach lets users experience a transform with sample content before granting permission, converting hesitation into "yes, take my permission."

**Effort:** S
**Priority:** P1
**Depends on:** DESIGN.md written

### Design custom menu bar icon

**What:** Design a custom menu bar icon to replace the SF Symbol placeholder (doc.on.clipboard). The icon should be recognizable at 18x18px, work in both light and dark menu bar contexts, and communicate "clipboard transformation" not just "clipboard."

**Why:** The SF Symbol is functional but generic. Every clipboard app uses it. A custom icon helps choosepaste stand out in a crowded menu bar and builds brand recognition.

**Context:** The design review decided to ship V1 with doc.on.clipboard and defer custom icon design until the product has real users and a clearer brand identity. Only worth doing after alpha feedback.

**Effort:** S
**Priority:** P2
**Depends on:** Alpha shipped with real users providing feedback

## Completed

### Create Markdown fixture corpus from real-world sources

**Completed:** v0.1.0 (2026-04-08), expanded 2026-09-26. 13 fixtures in engine/testdata/fixtures/ (hand-synthesized, no scraped page content): the original 5 (Claude Code, ChatGPT, browser articles, nested lists/tables, rich text mixed) plus Google Docs- and Word-style clipboard spans, images/captions, hr/strikethrough/sub/sup, definition lists, loose multi-paragraph list items, table colspan/alignment, and tracking-link/anchor edge cases. `TestMarkdown_Fixtures` in engine/transforms/markdown_test.go gained a `-update` flag to regenerate the golden .md files from current converter output. Several fixtures intentionally golden the engine's *current* (buggy) output rather than the ideal one — see suspected-bugs list in PR history for fairbearlab/choosepaste.

### Write the choosepaste implementation spec

Completed 2026-04-08. SPEC.md written with all design review and eng review decisions incorporated.

### Write DESIGN.md with minimal native spec

Completed 2026-04-08. DESIGN.md written with SF Pro typography, macOS system semantic colors, 8px spacing grid, popover dimensions, icon treatment, menu bar icon states, keyboard navigation model, and VoiceOver spec.
