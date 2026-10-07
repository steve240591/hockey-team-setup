import Foundation

/// Schnittstelle für Belohnungsvideos. Im ersten Entwurf läuft ein simuliertes Video,
/// damit das Spiel ohne Werbe-SDK testbar ist. Google AdMob ersetzt später nur diese Klasse.
@MainActor
protocol RewardedAdProvider: AnyObject {
    func show(completion: @escaping (Bool) -> Void)
}

/// Zeigt ein 5-Sekunden-Testvideo (siehe SimulatedAdOverlay).
@MainActor
final class SimulatedAdProvider: ObservableObject, RewardedAdProvider {
    static let duration = 5

    @Published private(set) var isShowing = false
    @Published private(set) var secondsLeft = 0
    private var completion: ((Bool) -> Void)?

    func show(completion: @escaping (Bool) -> Void) {
        guard !isShowing else { return }
        self.completion = completion
        secondsLeft = Self.duration
        isShowing = true
    }

    /// Wird vom Overlay jede Sekunde aufgerufen.
    func countdown() {
        guard isShowing, secondsLeft > 0 else { return }
        secondsLeft -= 1
    }

    /// Video zu Ende geschaut (true) oder abgebrochen (false).
    func finish(watched: Bool) {
        isShowing = false
        let done = completion
        completion = nil
        done?(watched)
    }
}
