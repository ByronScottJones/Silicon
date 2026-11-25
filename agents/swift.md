---
title: "Swift"
description: "Open this file only when writing or modifying Swift code."
applies_to: ["*.swift", "Package.swift"]
---

# Swift

Open this file only when writing or modifying Swift code. General rules stay in the root `AGENTS.md`. Load [`swiftui.md`](swiftui.md) as well when the code builds SwiftUI views.

## Toolchain & Project Setup

- Target the Swift 6 language mode for new code (`swiftLanguageModes: [.v6]` in `Package.swift`, or `SWIFT_VERSION = 6` in Xcode). Do not downgrade an existing project's language mode to silence errors.
- Use the latest stable Xcode and Swift toolchain unless the project pins one. Record a pin in `.swift-version` or the CI configuration.
- Prefer Swift Package Manager for libraries, command-line tools, and modularizing app code into local packages. Keep the Xcode project thin.
- Declare the minimum platform versions explicitly in `Package.swift` (`platforms:`) and keep them consistent with the app target.
- Commit `Package.resolved` for apps and executables. Do not commit it for libraries.
- Pin dependencies with `.upToNextMinor(from:)` or `.upToNextMajor(from:)` from a known release. Never depend on a branch in a shipping product.

## Configuration

- Use `FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)` for app data and `.cachesDirectory` for regenerable data. Never hard-code `~/Library` paths.
- Use `UserDefaults` only for small, non-sensitive preferences. Store secrets in the Keychain, never in `UserDefaults`, plists, or source.
- Read build-time configuration from `.xcconfig` files and `Info.plist` keys rather than `#if DEBUG` branches scattered through code.

## Formatting & Linting

- Formatter: `swift-format` (bundled with the toolchain as `swift format`), or the project's configured formatter. It is authoritative; never suggest conflicting style.
- Linter: `SwiftLint` when the project uses it. Fix violations rather than adding `// swiftlint:disable` without a justification on the same line.
- Validate with `swift build`, `swift test`, and `swift format lint --strict --recursive .`. For Xcode projects, use `xcodebuild build test` with an explicit `-scheme` and `-destination`.
- Treat warnings as errors in CI (`-warnings-as-errors` or `SWIFT_TREAT_WARNINGS_AS_ERRORS = YES`), including concurrency warnings.

## Language Conventions

- Follow the [Swift API Design Guidelines](https://www.swift.org/documentation/api-design-guidelines/): clarity at the point of use, fluent argument labels, `lowerCamelCase` for values, `UpperCamelCase` for types.
- Prefer `let` over `var`, and value types (`struct`, `enum`) over classes. Use a class only when identity or reference semantics is required, and mark it `final` unless it is designed for subclassing.
- Use the narrowest access level that works. Default to `internal`; use `private` or `fileprivate` for implementation details, and `public` only for a deliberate module API.
- Prefer protocols with associated types or generics (`some Protocol`) over existential types (`any Protocol`). Write `any` explicitly when an existential is intended.
- Model finite states with `enum`s and associated values instead of optional flags or stringly typed values.
- Use `guard` for early exits. Keep the happy path unindented.
- Never force unwrap (`!`), force cast (`as!`), or force try (`try!`) outside tests and provably safe literals such as `URL(string: "https://example.com")!`. Use `guard let`, `if let`, or `??` instead.
- Avoid implicitly unwrapped optionals except for `@IBOutlet` in legacy UIKit code.
- Use `[weak self]` in escaping closures that a long-lived object stores. Do not add it reflexively to non-escaping closures.
- Use `Codable` for serialization, with explicit `CodingKeys` when wire names differ from property names.
- Document public symbols with `///` DocC comments, including `- Parameters:`, `- Returns:`, and `- Throws:` where relevant.

## Concurrency

- Use structured concurrency (`async`/`await`, `async let`, `TaskGroup`) by default. Create unstructured `Task { }` only at boundaries such as UI event handlers, and keep a handle when the work must be cancelled.
- Avoid `Task.detached` unless the work must not inherit actor isolation or priority.
- Isolate UI-facing state to `@MainActor`. Protect shared mutable state with an `actor` rather than locks or dispatch queues.
- Make types crossing isolation boundaries `Sendable`. Do not use `@unchecked Sendable` or `nonisolated(unsafe)` without a comment explaining the invariant that makes it safe.
- Do not mix `DispatchQueue` with Swift concurrency in new code. Wrap callback APIs with `withCheckedThrowingContinuation`, and resume the continuation exactly once.
- Check `Task.isCancelled` or call `try Task.checkCancellation()` in long-running loops.
- Use `AsyncSequence` / `AsyncStream` for event streams instead of Combine in new code, unless the project already standardizes on Combine.

## Error Handling

- Define domain errors as `enum`s conforming to `Error` (and `LocalizedError` when messages reach users).
- Use typed throws (`throws(MyError)`) when a function has a closed, stable set of failures that callers handle exhaustively. Use untyped `throws` otherwise.
- Never swallow errors with an empty `catch` or with `try?` when the failure matters. Log or propagate with context.
- Use `Result` only when storing or passing an outcome; prefer `throws` for control flow.
- Reserve `fatalError` and `precondition` for programmer errors and unrecoverable invariants, never for input validation or I/O failures.

## Logging

- Use `os.Logger` (Apple platforms) or `swift-log` (server and cross-platform) instead of `print`.
- Create loggers with a `subsystem` (bundle identifier) and a `category` per feature.
- Mark dynamic values with privacy levels: `\(value, privacy: .private)` for user data. Never log secrets.

## Testing

- Use Swift Testing (`import Testing`, `@Test`, `#expect`, `#require`) for new tests. Keep XCTest for UI tests (`XCUIApplication`), performance tests, and existing XCTest suites.
- Use parameterized tests (`@Test(arguments:)`) instead of loops over cases.
- Use `#require` for preconditions that make the rest of the test meaningless, and `#expect` for ordinary assertions.
- Test `async` code directly with `async` test functions. Do not use sleeps or expectations with long timeouts to wait for results.
- Inject dependencies through protocols or closures so tests can supply fakes. Do not test against live network services in unit tests.
- Tests live in a `Tests/<ModuleName>Tests` target that mirrors the source module.

## Security

- Use `CryptoKit` for hashing, signing, and encryption. Never implement cryptography by hand.
- Keep App Transport Security enabled. Add domain-specific exceptions only with a documented reason.
- Store credentials and tokens in the Keychain with the most restrictive accessibility class that works (for example `kSecAttrAccessibleWhenUnlockedThisDeviceOnly`).
- Declare required-reason APIs and data collection in `PrivacyInfo.xcprivacy` for App Store targets.

## Code Generation Defaults

- Include the needed `import` statements and DocC comments on public symbols.
- Generate code that compiles cleanly in Swift 6 language mode with complete concurrency checking.
- Prefer Foundation and the standard library over third-party packages for common tasks such as networking (`URLSession`), JSON (`JSONDecoder`), and dates (`Date.FormatStyle`).
