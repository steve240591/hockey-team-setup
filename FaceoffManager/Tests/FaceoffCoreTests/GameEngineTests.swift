import XCTest
@testable import FaceoffCore

final class GameEngineTests: XCTestCase {
    private var config: GameConfig!
    private var engine: GameEngine!
    private let start = Date(timeIntervalSince1970: 1_800_000_000)

    override func setUpWithError() throws {
        let url = URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .appendingPathComponent("Game/Resources/GameConfig.json")
        config = try GameConfig.load(from: url)
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "UTC")!
        engine = GameEngine(config: config, seed: 42, calendar: calendar)
    }

    /// Macht das eigene Team unschlagbar, damit Saisonverläufe vorhersagbar sind.
    private func makeStrong(_ state: inout GameState) {
        for index in state.players.indices {
            state.players[index].attack = 1000
            state.players[index].defense = 1000
            state.players[index].speed = 1000
        }
    }

    func testNewGameHasValidLineup() {
        let state = engine.newGame(now: start)
        XCTAssertEqual(state.starters.count, 6)
        let starters = engine.starters(state)
        XCTAssertEqual(starters.filter { $0.position == .goalie }.count, 1)
        XCTAssertEqual(starters.filter { $0.position == .defense }.count, 2)
        XCTAssertEqual(starters.filter { $0.position == .forward }.count, 3)
        XCTAssertEqual(state.level("ticket"), 1)
        XCTAssertEqual(state.daily.quests.count, config.dailyQuestCount)
    }

    func testUpgradeCostGrowsBy15Percent() throws {
        let ticket = try XCTUnwrap(config.facility("ticket"))
        XCTAssertEqual(engine.upgradeCost(ticket, level: 10), 10 * pow(1.15, 10), accuracy: 0.0001)
        XCTAssertEqual(engine.upgradeCost(ticket, level: 50), 10_837, accuracy: 1)
    }

    func testMilestonesDoubleIncome() throws {
        let ticket = try XCTUnwrap(config.facility("ticket"))
        XCTAssertEqual(engine.baseIncome(ticket, level: 24), 0.5 * 24, accuracy: 0.0001)
        XCTAssertEqual(engine.baseIncome(ticket, level: 25), 0.5 * 25 * 2, accuracy: 0.0001)
        XCTAssertEqual(engine.baseIncome(ticket, level: 100), 0.5 * 100 * 8, accuracy: 0.0001)
    }

    func testUpgradeNeedsCoinsAndUnlockedLeague() {
        var state = engine.newGame(now: start)
        XCTAssertFalse(engine.upgradeFacility(&state, id: "ticket"), "Ohne Münzen kein Ausbau")
        state.coins = 1_000_000
        XCTAssertTrue(engine.upgradeFacility(&state, id: "ticket"))
        XCTAssertEqual(state.level("ticket"), 2)
        XCTAssertFalse(engine.upgradeFacility(&state, id: "shop"), "Fanshop erst ab Liga 2")
    }

    func testRoundRobinEveryTeamPlaysOncePerRound() {
        let ids = ["player", "a", "b", "c", "d", "e"]
        let fixtures = engine.roundRobin(ids, rounds: 10)
        for round in 0..<10 {
            let teams = fixtures.filter { $0.round == round }.flatMap { [$0.home, $0.away] }
            XCTAssertEqual(Set(teams).count, 6, "Runde \(round)")
            XCTAssertEqual(teams.count, 6)
        }
        let pairs = Set(fixtures.map { "\($0.home)-\($0.away)" })
        XCTAssertEqual(pairs.count, 30, "Jede Paarung genau einmal zu Hause und einmal auswärts")
    }

    func testStrongTeamIsPromotedAfterTenRounds() {
        var state = engine.newGame(now: start)
        makeStrong(&state)
        let interval = config.league(1).matchIntervalSeconds
        let events = engine.processDueMatches(&state, now: start.addingTimeInterval(interval * 10 + 1), interactive: false)

        let summaries = events.compactMap { event -> SeasonSummary? in
            if case .seasonEnded(let summary) = event { return summary }
            return nil
        }
        XCTAssertEqual(summaries.count, 1)
        XCTAssertEqual(summaries.first?.rank, 1)
        XCTAssertEqual(summaries.first?.promoted, true)
        XCTAssertEqual(state.season.tier, 2)
        XCTAssertEqual(state.season.round, 0)
    }

    func testInteractiveDrawWaitsForShootout() {
        var state = engine.newGame(now: start)
        let interval = config.league(1).matchIntervalSeconds
        var now = start
        // So lange spielen, bis ein Unentschieden des eigenen Teams eintritt.
        for _ in 0..<200 where state.pendingShootout == nil {
            now = now.addingTimeInterval(interval)
            _ = engine.processDueMatches(&state, now: now, interactive: true)
        }
        XCTAssertNotNil(state.pendingShootout, "Bei 12 % Unentschieden-Chance sollte das vorkommen")
        let round = state.season.round
        let result = engine.resolvePendingShootout(&state, playerGoals: 5)
        XCTAssertNotNil(result)
        XCTAssertNil(state.pendingShootout)
        XCTAssertTrue(state.season.round == round + 1 || state.season.round == 0, "Runde ist abgeschlossen")
    }

    func testOfflineIncomeIsCappedAndNeedsManager() {
        var state = engine.newGame(now: start)
        let later = start.addingTimeInterval(10 * 3600)

        // Spielprämien gibt es auch offline, die Einrichtungen verdienen aber nur mit Manager.
        var withoutManager = state
        let reportWithout = engine.applyOffline(&withoutManager, now: later)
        XCTAssertEqual(reportWithout?.coins ?? -1, 0, accuracy: 0.0001, "Ohne Manager keine Offline-Einnahmen")

        state.managers.insert("ticket")
        let report = engine.applyOffline(&state, now: later)
        XCTAssertEqual(report?.seconds, 2 * 3600, "Begrenzung auf 2 Stunden")
        XCTAssertEqual(report?.coins ?? 0, 0.5 * 2 * 3600, accuracy: 0.0001, "Ticketschalter Stufe 1: 0,5 Münzen pro Sekunde")
        XCTAssertEqual(report?.matchesPlayed, config.match.maxCatchUpMatches, "Verpasste Spiele werden begrenzt nachgeholt")
    }

    func testClockSetBackwardsGivesNothing() {
        var state = engine.newGame(now: start)
        state.managers.insert("ticket")
        let report = engine.applyOffline(&state, now: start.addingTimeInterval(-3600))
        XCTAssertNil(report)
        XCTAssertEqual(state.coins, 0, accuracy: 0.0001)
    }

    func testBoostIsCappedAtEightHours() {
        var state = engine.newGame(now: start)
        for _ in 0..<6 {
            engine.applyBoost(&state, now: start, hours: 2)
        }
        XCTAssertEqual(state.boostUntil, start.addingTimeInterval(8 * 3600))
    }

    func testRewardedDailyLimit() {
        var state = engine.newGame(now: start)
        for _ in 0..<4 {
            XCTAssertTrue(engine.canUseRewarded(state, kind: .boost))
            engine.registerRewarded(&state, kind: .boost)
        }
        XCTAssertFalse(engine.canUseRewarded(state, kind: .boost))
        XCTAssertNil(engine.rewardedRemaining(state, kind: .offlineDouble), "Verdoppeln hat kein Limit")
        engine.rolloverDayIfNeeded(&state, now: start.addingTimeInterval(86_400))
        XCTAssertTrue(engine.canUseRewarded(state, kind: .boost), "Neuer Tag, neues Limit")
    }

    func testLoginStreakResetsAfterMissedDay() {
        var state = engine.newGame(now: start)
        XCTAssertEqual(engine.claimLogin(&state), config.loginRewardPucks[0])
        XCTAssertEqual(engine.claimLogin(&state), 0, "Nur einmal pro Tag")

        engine.rolloverDayIfNeeded(&state, now: start.addingTimeInterval(86_400))
        XCTAssertEqual(engine.claimLogin(&state), config.loginRewardPucks[1])

        engine.rolloverDayIfNeeded(&state, now: start.addingTimeInterval(3 * 86_400))
        XCTAssertEqual(engine.claimLogin(&state), config.loginRewardPucks[0], "Tag ausgelassen: Kalender beginnt neu")
    }

    func testScoutingCostsPucksAndRespectsRosterLimit() {
        var state = engine.newGame(now: start)
        state.pucks = 100
        XCTAssertNotNil(engine.scout(&state, paid: true))
        XCTAssertEqual(state.pucks, 0)
        XCTAssertNil(engine.scout(&state, paid: true), "Keine Pucks mehr")

        while state.players.count < config.scouting.maxRoster {
            _ = engine.scout(&state, paid: false)
        }
        XCTAssertNil(engine.scout(&state, paid: false), "Kader voll")
    }

    func testTrainingUsesCards() throws {
        var state = engine.newGame(now: start)
        let player = try XCTUnwrap(state.players.first)
        state.trainingCards = 3
        XCTAssertTrue(engine.train(&state, playerId: player.id))
        XCTAssertEqual(state.trainingCards, 0)
        XCTAssertEqual(state.players.first?.level, 2)
        XCTAssertFalse(engine.train(&state, playerId: player.id), "Stufe 2 → 3 kostet 6 Karten")
    }

    func testStartersCannotBeReleased() throws {
        var state = engine.newGame(now: start)
        let starter = try XCTUnwrap(state.starters.first)
        XCTAssertFalse(engine.release(&state, playerId: starter))
        let bench = try XCTUnwrap(engine.scout(&state, paid: false))
        let cards = state.trainingCards
        XCTAssertTrue(engine.release(&state, playerId: bench.id))
        XCTAssertGreaterThan(state.trainingCards, cards)
    }

    func testPrestigeKeepsPlayersAndResetsEconomy() {
        var state = engine.newGame(now: start)
        state.season = engine.makeSeason(tier: 5)
        state.runEarnings = 100_000_000
        state.coins = 5_000
        state.facilityLevels["food"] = 30
        state.pucks = 77
        let players = state.players

        XCTAssertTrue(engine.canPrestige(state))
        let points = engine.prestige(&state, now: start)
        XCTAssertEqual(points, 10, "Wurzel aus 100 Mio. / 1 Mio.")
        XCTAssertEqual(state.legendPoints, 10)
        XCTAssertEqual(state.season.tier, 1)
        XCTAssertEqual(state.level("food"), 0)
        XCTAssertEqual(state.coins, config.start.coins)
        XCTAssertEqual(state.pucks, 77)
        XCTAssertEqual(state.players, players)
        XCTAssertEqual(engine.prestigeMultiplier(state), 2, accuracy: 0.0001)
    }

    func testOneTimePurchasesAreNotGrantedTwice() {
        var state = engine.newGame(now: start)
        let pucks = state.pucks
        XCTAssertTrue(engine.applyPurchase(&state, productId: config.products.starterPack, now: start))
        XCTAssertFalse(engine.applyPurchase(&state, productId: config.products.starterPack, now: start))
        XCTAssertEqual(state.pucks, pucks + config.starter.pucks)

        XCTAssertTrue(engine.applyPurchase(&state, productId: config.products.adFree, now: start))
        XCTAssertFalse(engine.applyPurchase(&state, productId: config.products.adFree, now: start))

        let pack = config.products.pucks[0]
        XCTAssertTrue(engine.applyPurchase(&state, productId: pack.id, now: start))
        XCTAssertTrue(engine.applyPurchase(&state, productId: pack.id, now: start), "Pucks sind verbrauchbar")
    }

    func testReplayKeepsStandingsConsistent() {
        var state = engine.newGame(now: start)
        let interval = config.league(1).matchIntervalSeconds
        var now = start
        for _ in 0..<9 where state.replayableResultId == nil {
            now = now.addingTimeInterval(interval)
            _ = engine.processDueMatches(&state, now: now, interactive: false)
        }
        guard state.replayableResultId != nil else {
            return // Kein verlorenes Spiel in diesem Zufallsverlauf.
        }
        let playedBefore = state.season.standings.reduce(0) { $0 + $1.played }
        XCTAssertNotNil(engine.replayLastLoss(&state))
        let playedAfter = state.season.standings.reduce(0) { $0 + $1.played }
        XCTAssertEqual(playedBefore, playedAfter)
    }

    func testStateSurvivesJSONRoundTrip() throws {
        let state = engine.newGame(now: start)
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let decoded = try decoder.decode(GameState.self, from: encoder.encode(state))
        XCTAssertEqual(decoded, state)
    }
}
