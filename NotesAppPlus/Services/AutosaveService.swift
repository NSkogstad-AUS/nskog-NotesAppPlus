import Foundation

// Debounces save calls so rapid edits don't thrash disk and SQLite.
final class AutosaveService {
    private var workItem: DispatchWorkItem?
    let delay: TimeInterval

    init(delay: TimeInterval = 0.5) {
        self.delay = delay
    }

    func schedule(action: @escaping () -> Void) {
        workItem?.cancel()
        let item = DispatchWorkItem(block: action)
        workItem = item
        DispatchQueue.main.asyncAfter(deadline: .now() + delay, execute: item)
    }

    func cancelPending() {
        workItem?.cancel()
        workItem = nil
    }
}
