import Foundation
import SwiftUI

/// Was gerade als Blatt (Sheet) angezeigt wird. Mehrere Meldungen werden nacheinander gezeigt.
enum ActiveSheet: Identifiable {
    case offline(OfflineReport)
    case season(SeasonSummary)
    case scouted(Player)
    case shootout(ShootoutOutcome)
    case practice(PracticeReward)

    var id: String {
        switch self {
        case .offline(let report): return "offline-\(report.id)"
        case .season(let summary): return "season-\(summary.id)"
        case .scouted(let player): return "scouted-\(player.id)"
        case .shootout(let outcome): return "shootout-\(outcome.playerGoals)-\(outcome.opponentGoals)-\(outcome.won)"
        case .practice(let reward): return "practice-\(reward.goals)-\(reward.coins)"
        }
    }
}

struct PenaltySession: Identifiable {
    enum Mode {
        case match
        case practice
    }

    let id = UUID()
    let mode: Mode
    let shots: Int
    let goalWidth: Double
    let goalieSpeed: Double
}

/// Verbindet Spiellogik, Speicherung, Käufe und Werbung mit der Oberfläche.
@MainActor
final class GameStore: ObservableObject {
    @Published private(set) var state: GameState
    @Published var sheet: ActiveSheet?
    @Published var penaltySession: PenaltySession?
    @Published var message: String?
    @Published private(set) var now = Date()

    let engine: GameEngine
    let purchases: PurchaseManager
    let ads: SimulatedAdProvider

    private let persistence = Persistence()
    private var queuedSheets: [ActiveSheet] = []
    private var secondsSinceSave = 0
    private var messageTask: Task<Void, Never>?

    var config: GameConfig { engine.config }

    init() {
        let config = GameStore.loadConfig()
        let engine = GameEngine(config: config)
        let start = Date()
        self.engine = engine
        self.state = Persistence().load() ?? engine.newGame(now: start)
        self.purchases = PurchaseManager(productIDs: config.products.allIDs)
        self.ads = SimulatedAdProvider()
        purchases.onPurchased = { [weak self] productId in
            self?.applyPurchase(productId)
        }
    }

    private static func loadConfig() -> GameConfig {
        guard let url = Bundle.main.url(forResource: "GameConfig", withExtension: "json") else {
            fatalError("GameConfig.json fehlt im App-Bundle. Ist der Ordner Resources im Xcode-Projekt eingebunden?")
        }
        do {
            return try GameConfig.load(from: url)
        } catch {
            fatalError("GameConfig.json ist fehlerhaft: \(error)")
        }
    }

    // MARK: - Anzeige-Hilfen

    var clubDisplayName: String {
        state.clubName.isEmpty ? L("club.defaultName") : state.clubName
    }

    func teamName(_ teamId: String) -> String {
        if teamId == GameEngine.playerTeamId { return clubDisplayName }
        return config.teamName(teamId) ?? teamId
    }

    func leagueName(_ tier: Int) -> String {
        L(config.league(tier).nameKey)
    }

    var incomePerSecond: Double {
        engine.incomePerSecond(state, now: now)
    }

    var teamStrength: Double {
        engine.teamStrength(state)
    }

    var boostSecondsLeft: Double {
        guard let until = state.boostUntil else { return 0 }
        return max(0, until.timeIntervalSince(now))
    }

    var secondsToNextMatch: Double {
        max(0, state.nextMatchDate.timeIntervalSince(now))
    }

    // MARK: - Zeit

    func tick(now date: Date) {
        now = date
        // Während das Minispiel läuft, wartet das nächste Ligaspiel.
        if penaltySession != nil && state.nextMatchDate <= date {
            state.nextMatchDate = date.addingTimeInterval(5)
        }
        let events = engine.tick(&state, now: date)
        handle(events)
        secondsSinceSave += 1
        if secondsSinceSave >= 10 {
            save()
        }
    }

    func becameActive() {
        let date = Date()
        now = date
        let previousSummary = state.lastSeasonSummary
        if let report = engine.applyOffline(&state, now: date), report.coins > 0 || report.matchesPlayed > 0 {
            present(.offline(report))
        }
        if let summary = state.lastSeasonSummary, summary != previousSummary {
            present(.season(summary))
        }
        save()
    }

    func save() {
        secondsSinceSave = 0
        persistence.save(state)
    }

    private func handle(_ events: [GameEvent]) {
        for event in events {
            if case .seasonEnded(let summary) = event {
                present(.season(summary))
            }
        }
    }

    // MARK: - Meldungen

    func present(_ newSheet: ActiveSheet) {
        if sheet == nil {
            sheet = newSheet
        } else {
            queuedSheets.append(newSheet)
        }
    }

    /// Wartet, bis das Vollbild-Minispiel geschlossen ist, und zeigt dann das Ergebnis.
    private func presentAfterCover(_ newSheet: ActiveSheet) {
        Task {
            try? await Task.sleep(nanoseconds: 600_000_000)
            present(newSheet)
        }
    }

    func sheetDismissed() {
        guard !queuedSheets.isEmpty else { return }
        let next = queuedSheets.removeFirst()
        Task {
            try? await Task.sleep(nanoseconds: 400_000_000)
            sheet = next
        }
    }

    func show(_ text: String) {
        message = text
        messageTask?.cancel()
        messageTask = Task {
            try? await Task.sleep(nanoseconds: 2_500_000_000)
            if !Task.isCancelled { message = nil }
        }
    }

    // MARK: - Verein

    func upgrade(_ facilityId: String) {
        if engine.upgradeFacility(&state, id: facilityId) {
            Haptics.tap()
        }
    }

    func hireManager(_ facilityId: String) {
        if engine.hireManager(&state, id: facilityId) {
            Haptics.success()
            show(L("club.managerHired"))
        }
    }

    func renameClub(_ name: String) {
        state.clubName = String(name.trimmingCharacters(in: .whitespacesAndNewlines).prefix(30))
    }

    // MARK: - Belohnungsvideos

    /// Spielt ein Video (oder gibt die Belohnung direkt, wenn „Werbefrei“ gekauft wurde).
    func watchAd(_ kind: RewardedKind, reward: @escaping () -> Void) {
        guard engine.canUseRewarded(state, kind: kind) else {
            show(L("ad.limitReached"))
            return
        }
        let grant: () -> Void = { [weak self] in
            guard let self else { return }
            self.engine.registerRewarded(&self.state, kind: kind)
            reward()
        }
        if state.adFree {
            grant()
            return
        }
        ads.show { watched in
            if watched { grant() }
        }
    }

    func watchBoostAd() {
        watchAd(.boost) { [weak self] in
            guard let self else { return }
            self.engine.applyBoost(&self.state, now: Date(), hours: self.config.rewarded.boostHours)
            self.show(L("boost.started"))
        }
    }

    func doubleOffline(_ report: OfflineReport) {
        watchAd(.offlineDouble) { [weak self] in
            guard let self else { return }
            self.engine.earn(&self.state, report.coins)
            self.show(LF("offline.doubled", Fmt.number(report.coins)))
        }
    }

    // MARK: - Team

    func scoutWithPucks() {
        guard !engine.rosterIsFull(state) else {
            show(L("team.rosterFull"))
            return
        }
        guard state.pucks >= config.scouting.costPucks else {
            show(L("common.notEnoughPucks"))
            return
        }
        if let player = engine.scout(&state, paid: true) {
            present(.scouted(player))
        }
    }

    func scoutWithAd() {
        guard !engine.rosterIsFull(state) else {
            show(L("team.rosterFull"))
            return
        }
        watchAd(.freeScout) { [weak self] in
            guard let self else { return }
            if let player = self.engine.scout(&self.state, paid: false) {
                self.present(.scouted(player))
            }
        }
    }

    func train(_ playerId: UUID) {
        if engine.train(&state, playerId: playerId) {
            Haptics.success()
        } else {
            show(L("team.notEnoughCards"))
        }
    }

    func release(_ playerId: UUID) {
        engine.release(&state, playerId: playerId)
    }

    func makeStarter(_ playerId: UUID) {
        engine.makeStarter(&state, playerId: playerId)
    }

    func autoLineup() {
        engine.autoLineup(&state)
        show(L("team.lineupUpdated"))
    }

    // MARK: - Penalty-Schießen

    private func makeSession(_ mode: PenaltySession.Mode) -> PenaltySession {
        let parameters = engine.penaltyParameters(state)
        return PenaltySession(
            mode: mode,
            shots: config.match.shootoutShots,
            goalWidth: parameters.goalWidth,
            goalieSpeed: parameters.goalieSpeed
        )
    }

    func playPendingShootout() {
        guard state.pendingShootout != nil else { return }
        penaltySession = makeSession(.match)
    }

    func skipPendingShootout() {
        let events = engine.resolvePendingShootoutAutomatically(&state)
        handle(events)
        show(L("league.shootoutSkipped"))
    }

    func startPractice() {
        if engine.usePracticeAttempt(&state) {
            penaltySession = makeSession(.practice)
            return
        }
        watchAd(.practiceExtra) { [weak self] in
            guard let self else { return }
            self.penaltySession = self.makeSession(.practice)
        }
    }

    /// Minispiel beendet. `goals` = nil bedeutet: abgebrochen.
    func finishPenalty(_ session: PenaltySession, goals: Int?) {
        penaltySession = nil
        switch session.mode {
        case .match:
            guard let goals else {
                let events = engine.resolvePendingShootoutAutomatically(&state)
                for case .seasonEnded(let summary) in events {
                    presentAfterCover(.season(summary))
                }
                show(L("league.shootoutSkipped"))
                return
            }
            if case let (outcome, events)? = engine.resolvePendingShootout(&state, playerGoals: goals) {
                presentAfterCover(.shootout(outcome))
                for case .seasonEnded(let summary) in events {
                    presentAfterCover(.season(summary))
                }
            }
        case .practice:
            guard let goals else { return }
            let reward = engine.applyPracticeResult(&state, goals: goals, now: Date())
            presentAfterCover(.practice(reward))
        }
        save()
    }

    func replayLastLoss() {
        watchAd(.replay) { [weak self] in
            guard let self else { return }
            if let result = self.engine.replayLastLoss(&self.state) {
                let won = self.engine.didPlayerWin(result)
                self.show(won ? L("league.replayWon") : L("league.replayLost"))
            }
        }
    }

    // MARK: - Tagesbelohnungen und Prestige

    func claimLogin() {
        let pucks = engine.claimLogin(&state)
        if pucks > 0 {
            Haptics.success()
            show(LF("reward.pucks", Fmt.integer(pucks)))
        }
    }

    func claimQuest(_ id: String) {
        let pucks = engine.claimQuest(&state, id: id)
        if pucks > 0 {
            Haptics.success()
            show(LF("reward.pucks", Fmt.integer(pucks)))
        }
    }

    func prestige() {
        let points = engine.prestige(&state, now: Date())
        if points > 0 {
            Haptics.success()
            show(LF("prestige.done", Fmt.integer(points)))
            save()
        }
    }

    // MARK: - Shop

    func buyOfflineUpgrade() {
        if engine.buyOfflineUpgrade(&state) {
            Haptics.success()
        } else {
            show(L("common.notEnoughPucks"))
        }
    }

    func buyTimeSkip() {
        let coins = engine.buyTimeSkip(&state, now: Date())
        if coins > 0 {
            Haptics.success()
            show(LF("shop.timeSkipDone", Fmt.number(coins)))
        } else {
            show(L("common.notEnoughPucks"))
        }
    }

    func applyPurchase(_ productId: String) {
        if engine.applyPurchase(&state, productId: productId, now: Date()) {
            Haptics.success()
            show(L("shop.thanks"))
            save()
        }
    }

    #if DEBUG
    /// Nur in Testversionen: setzt den Spielstand zurück.
    func resetGame() {
        persistence.delete()
        state = engine.newGame(now: Date())
        queuedSheets = []
        sheet = nil
        save()
    }

    /// Nur in Testversionen: schreibt einen Kauf gut, ohne StoreKit.
    func simulatePurchase(_ productId: String) {
        applyPurchase(productId)
    }
    #endif
}
