# Repository Guidelines

## Project Structure & Module Organization
- `Package.swift` defines the single `ValidatedTextField` library target and iOS minimums.
- Runtime code lives in `Sources/ValidatedTextField/` and is split by concern (formatters, validators, style engine, main view).
- Generated build artifacts sit under `.build/`; treat it as disposable and avoid committing files from that folder.
- No `Tests/` directory ships yet—create it when adding XCTest targets to keep the tree consistent with SwiftPM conventions.

## Build, Test, and Development Commands
- `swift build` compiles the library locally; run after major changes to catch compiler issues.
- `swift test` executes XCTest targets once they exist; CI and PR checks should rely on it.
- `xcodebuild -scheme ValidatedTextField -destination 'platform=iOS Simulator,name=iPhone 15' build` validates integration inside Xcode-style workflows when needed.

## Coding Style & Naming Conventions
- Follow Swift API Design Guidelines: `UpperCamelCase` for types, `lowerCamelCase` for methods, properties, and case names.
- Indent with four spaces, keep braces on the same line as declarations, and prefer explicit access control (`public`, `internal`, `private`).
- Favor immutable `let` declarations, and group related MARK sections (e.g., `// MARK: - Validation`).
- Use doc comments (`///`) for public APIs that ship outside this package.

## Testing Guidelines
- Add XCTest cases under `Tests/ValidatedTextFieldTests/`; mirror source file names for clarity (e.g., `StyleEngineTests.swift`).
- Name tests descriptively using the `test_state_expectedResult` pattern.
- Stub UIKit dependencies with lightweight fakes where possible to keep tests deterministic.
- Run `swift test --parallel` before pushing to confirm everything passes across configurations.

## Commit & Pull Request Guidelines
- Commit messages should be short, present-tense imperatives (e.g., `Refactor formatters to use String.Index ranges`).
- Group related changes per commit; avoid mixing formatting-only updates with behavioural changes.
- Pull requests must include: a concise summary, testing notes (`swift build`, `swift test`), and screenshots or GIFs for UI-facing adjustments.
- Link issues or tracking tickets in the PR description and request review from at least one maintainer before merge.
