import Observation

// AppKit before macOS 26 and UIKit before iOS 26 do not track Observable
// reads themselves, so their views re-run their updates through this.
@MainActor
func observeChanges(_ apply: @escaping @MainActor () -> Void) {
    withObservationTracking(apply) {
        // onChange fires before the new value is stored, so the re-run waits
        // for the mutation to finish.
        Task { @MainActor in
            observeChanges(apply)
        }
    }
}
