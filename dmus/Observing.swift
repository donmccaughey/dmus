import Observation

// AppKit does not track Observable reads itself before macOS 26, so AppKit
// views re-run their updates through this.
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
