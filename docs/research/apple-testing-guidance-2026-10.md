# Apple's Current Guidance on Unit and UI Testing for a Swift/SwiftUI Multiplatform App

*As of October 2026 (Xcode 27, Swift 6.4)*

Apple's current guidance splits testing across two frameworks, and the split maps directly onto the two kinds of tests: isolated unit tests and functional (UI) tests.

## Which framework for which tests

### Unit tests: Swift Testing

Swift Testing became the default for new test code in Xcode 26 / Swift 6.2, and Apple's WWDC26 session "Migrate to Swift Testing" reaffirmed that direction: use Swift Testing for new tests while keeping existing XCTests in place, and replace XCTest API gradually. The framework is designed for in-process logic tests. It uses `@Test` functions and `#expect`/`#require` macros, works natively with async/await, and runs tests in parallel by default, which pushes you toward tests that don't share mutable state. Apple recommends using a struct for suites unless you need a `deinit` for cleanup, so each test gets a fresh instance.

### UI tests: XCTest / XCUIAutomation

`XCUIApplication`, `XCUIElement`, `XCUIElementQuery`, and the rest of the UI testing API are XCTest-only; Swift Testing provides no replacement. UI automation and performance-testing APIs remain in XCTest, so a UI test target still subclasses `XCTestCase`. Apple's WWDC25 session "Record, replay, and review: UI automation with Xcode" is the current reference. It covers recording, running, and maintaining XCUIAutomation tests, and notes that accessibility is the underlying framework that powers UI automation, so assigning accessibility identifiers to SwiftUI views is what makes them addressable from tests.

### Mixing the two is now supported

Xcode 27 enables test-framework interoperability by default: XCTest assertion failures are reported as test issues when called from Swift Testing, and Swift Testing APIs like `#expect` work when called from an `XCTestCase`. There are four modes (Limited, Complete, Strict, and None) configured in test plans and Swift packages; test plans created before Xcode 27 inherit Limited mode. For a new project this mostly means you can share helper code between unit and UI test targets without worrying about which framework the helper uses.

## Isolating unit tests from filesystem, network, and UI

Apple doesn't publish a single "isolation" document, but its guidance converges on one structural recommendation: **put your logic in a target with no UI dependency.** The WWDC25 session states that unit tests cover the app's logic and models, and with Swift Testing it's possible to run tests on frameworks and Swift packages that don't have a user interface at all. In practice:

1. **Move models, business logic, and view models into a local Swift package** (or framework) that imports only Foundation (and Observation/SwiftData if needed), never SwiftUI. The unit test target then tests the package, not the app, so no app process launches and no view code is linked.
2. **Define protocols for the filesystem and network** (for example a `FileStore` and an `APIClient` protocol), implement them with real `FileManager`/`URLSession` in the app, and inject fakes in tests. Swift Testing's parallel-by-default execution makes this close to mandatory, since tests sharing a real file path or network stub would race each other.
3. **Keep SwiftUI views thin.** State and transformations live in the package where they're testable; views only render. There is no Apple-supported way to unit test SwiftUI view bodies directly, and Apple's answer for that layer is XCUIAutomation.

A unit test target that doesn't need a host app is sometimes called a "logic test" bundle. Xcode's unit test template for a package or framework sets this up, and because the tests run directly on the Mac they're much faster than hosted tests that launch an app in a simulator.

## Target and scheme layout for a multiplatform app

For one app target with iOS and macOS destinations, a typical layout is:

- **`AppCore` (local Swift package)** — all platform-independent logic.
- **`AppCoreTests`** — Swift Testing suite inside the package; this is the isolated unit test target.
- **`AppUITests`** — XCTest UI test bundle attached to the app target. Use `launchArguments`/`launchEnvironment` on `XCUIApplication` to tell the app to swap in stub implementations of the same protocols, so UI tests don't hit real networks either.
- **A test plan** that includes both targets with separate configurations for the iOS Simulator and macOS destinations. Xcode 27 test plans also let you choose how the run responds if the app crashes during UI testing (off, warning, failure, or fatal failure), and the new launch test template opts into `runsForEachTargetApplicationUIConfiguration`, so the test runs across every orientation, localization, and appearance combination.

One known rough edge: a developer-forum thread reports that adding a Unit Test Bundle to a Multiplatform project caused Xcode to hang at "Testing..." in some versions, with the suggestion that the scheme must be set to run the app target that matches the one the test bundle is configured against. Putting unit tests in the package sidesteps this, since package tests don't depend on a host app.

## Where to read more

- WWDC24 "Meet Swift Testing" and "Go further with Swift Testing" — framework fundamentals.
- WWDC25 "Record, replay, and review: UI automation with Xcode" (session 344) — current UI testing guidance.
- WWDC26 "Migrate to Swift Testing" (session 267) and "What's new in Swift" (session 262) — interoperability and Xcode 27 defaults.
- Apple's Swift Testing landing page: https://developer.apple.com/xcode/swift-testing/

## Sources

- [Record, replay, and review: UI automation with Xcode – WWDC25](https://developer.apple.com/videos/play/wwdc2025/344/)
- [Migrate to Swift Testing – WWDC26](https://developer.apple.com/videos/play/wwdc2026/267/)
- [What's new in Swift – WWDC26](https://developer.apple.com/videos/play/wwdc2026/262/)
- [Swift Testing vs XCTest: The 2026 Migration Guide](https://theswiftk.it.com/blog/swift-testing-vs-xctest-migration-guide-2026)
- [Swift Testing Framework: A Guide for iOS Teams](https://www.drizz.dev/post/swift-testing-framework)
- [Xcode 27: Everything Developers Need to Know](https://dev.to/arshtechpro/xcode-27-everything-developers-need-to-know-6lh)
- [Struggling to add a test target to an existing project in Xcode – Apple Developer Forums](https://developer.apple.com/forums/thread/769654)
