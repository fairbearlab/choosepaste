# Release Notes v2.4.0

This release includes several improvements and bug fixes.

## New Features

- Added **dark mode** support across all views
- New `--watch` flag for the CLI ([#123](https://github.com/example/repo/pull/123))
- Keyboard shortcut `⌘K` now opens the command palette

## Bug Fixes

1. Fixed crash when clipboard is empty ([#456](https://github.com/example/repo/issues/456))
2. Resolved memory leak in `TransformBridge` on repeated invocations
3. Fixed incorrect *RTF-to-HTML* conversion for nested bold/italic

## Breaking Changes

> **Warning:** The `--format` flag has been renamed to `--output-format`. Update your scripts accordingly.

## Migration Guide

Update your configuration file:

```yaml
output:
  format: markdown    # was: format
  destination: stdout
```

For questions, see the [migration docs](https://docs.example.com/migration) or open an [issue](https://github.com/example/repo/issues).
