import Observation
import Testing

@Observable
private final class Counter {
    var value = 0
}

struct ObservingTests {
    @Test func rerunsWhenAnObservedPropertyChanges() async {
        let counter = Counter()
        var seen: [Int] = []
        observeChanges { seen.append(counter.value) }

        counter.value = 1
        await waitUntil { seen.count == 2 }

        #expect(seen == [0, 1])
    }

    @Test func keepsObservingAfterEachChange() async {
        let counter = Counter()
        var seen: [Int] = []
        observeChanges { seen.append(counter.value) }

        counter.value = 1
        await waitUntil { seen.count == 2 }
        counter.value = 2
        await waitUntil { seen.count == 3 }

        #expect(seen == [0, 1, 2])
    }

    @Test func runsOnceWhenNothingIsObserved() async {
        let counter = Counter()
        var runs = 0
        observeChanges { runs += 1 }

        counter.value = 1
        await waitUntil { false }

        #expect(runs == 1)
    }

    // The re-run and the test continuation both queue on the main actor in
    // no guaranteed order, so yield until the condition holds or give up.
    private func waitUntil(_ condition: () -> Bool) async {
        for _ in 0..<20 where !condition() {
            await Task.yield()
        }
    }
}
