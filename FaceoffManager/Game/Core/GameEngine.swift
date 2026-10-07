import Foundation

/// Die komplette Spiellogik ohne Oberfläche. Sie verändert nur den übergebenen GameState
/// und lässt sich deshalb ohne iPhone testen (siehe Tests/FaceoffCoreTests).
final class GameEngine {
    static let playerTeamId = "player"

    let config: GameConfig
    private var rng: SeededGenerator
    private let calendar: Calendar

    init(config: GameConfig, seed: UInt64 = UInt64.random(in: 0...UInt64.max), calendar: Calendar = .current) {
        self.config = config
        self.rng = SeededGenerator(seed: seed)
        self.calendar = calendar
    }

    // MARK: - Neues Spiel

    func newGame(now: Date) -> GameState {
        var players: [Player] = []
        for position in Position.allCases {
            for _ in 0..<position.starterSlots {
                players.append(makePlayer(position: position, rarity: .common))
            }
        }
        var state = GameState(
            clubName: config.start.clubName,
            coins: config.start.coins,
            pucks: config.start.pucks,
            trainingCards: config.start.cards,
            facilityLevels: [config.facilities[0].id: 1],
            players: players,
            starters: players.map(\.id),
            season: makeSeason(tier: 1),
            nextMatchDate: now.addingTimeInterval(config.league(1).matchIntervalSeconds),
            lastActive: now,
            firstLaunch: now
        )
        rolloverDayIfNeeded(&state, now: now)
        return state
    }

    // MARK: - Wirtschaft

    /// Kosten, um eine Einrichtung von `level` auf `level + 1` zu bringen.
    func upgradeCost(_ facility: FacilityConfig, level: Int) -> Double {
        facility.baseCost * pow(config.costGrowth, Double(level))
    }

    /// Verdopplung bei jedem erreichten Meilenstein (z. B. Stufe 25, 50, 100).
    func milestoneMultiplier(level: Int) -> Double {
        pow(2, Double(config.milestoneLevels.filter { level >= $0 }.count))
    }

    func nextMilestone(after level: Int) -> Int? {
        config.milestoneLevels.first { $0 > level }
    }

    func baseIncome(_ facility: FacilityConfig, level: Int) -> Double {
        guard level > 0 else { return 0 }
        return facility.baseIncome * Double(level) * milestoneMultiplier(level: level)
    }

    func isUnlocked(_ facility: FacilityConfig, in state: GameState) -> Bool {
        state.season.tier >= facility.unlockTier
    }

    func prestigeMultiplier(_ state: GameState) -> Double {
        1 + Double(state.legendPoints) * config.prestige.multiplierPerPoint
    }

    func facilityBonus(_ state: GameState, kind: FacilityKind) -> Double {
        config.facilities
            .filter { $0.kind == kind }
            .reduce(0) { $0 + $1.effectPerLevel * Double(state.level($1.id)) }
    }

    func isBoostActive(_ state: GameState, now: Date) -> Bool {
        guard let until = state.boostUntil else { return false }
        return until > now
    }

    func incomeMultiplier(_ state: GameState, now: Date, includeBoost: Bool) -> Double {
        var multiplier = 1 + Double(state.fans) * config.fanIncomeFactor
        multiplier *= prestigeMultiplier(state)
        multiplier *= 1 + facilityBonus(state, kind: .multiplier)
        if state.adFree {
            multiplier *= 1 + config.shop.adFreeIncomeBonus
        }
        if includeBoost && isBoostActive(state, now: now) {
            multiplier *= 2
        }
        return multiplier
    }

    /// Münzen pro Sekunde. `managedOnly`: nur Einrichtungen mit Manager (gilt offline).
    func incomePerSecond(_ state: GameState, now: Date, managedOnly: Bool = false, includeBoost: Bool = true) -> Double {
        let base = config.facilities.reduce(0.0) { sum, facility in
            if managedOnly && !state.managers.contains(facility.id) { return sum }
            return sum + baseIncome(facility, level: state.level(facility.id))
        }
        return base * incomeMultiplier(state, now: now, includeBoost: includeBoost)
    }

    func earn(_ state: inout GameState, _ amount: Double) {
        guard amount > 0 else { return }
        state.coins += amount
        state.runEarnings += amount
        state.totalEarnings += amount
    }

    private func accrueCards(_ state: inout GameState, seconds: Double, managedOnly: Bool) {
        let perHour = config.facilities
            .filter { $0.kind == .cards && (!managedOnly || state.managers.contains($0.id)) }
            .reduce(0.0) { $0 + $1.effectPerLevel * Double(state.level($1.id)) }
        guard perHour > 0 else { return }
        state.fractionalCards += perHour * seconds / 3600
        let whole = Int(state.fractionalCards)
        if whole > 0 {
            state.trainingCards += whole
            state.fractionalCards -= Double(whole)
        }
    }

    @discardableResult
    func upgradeFacility(_ state: inout GameState, id: String) -> Bool {
        guard let facility = config.facility(id), isUnlocked(facility, in: state) else { return false }
        let level = state.level(id)
        let cost = upgradeCost(facility, level: level)
        guard state.coins >= cost else { return false }
        state.coins -= cost
        state.facilityLevels[id] = level + 1
        progressQuests(&state, kind: .upgradeFacility)
        return true
    }

    func canHireManager(_ state: GameState, id: String) -> Bool {
        guard let facility = config.facility(id) else { return false }
        return !state.managers.contains(id)
            && state.level(id) >= facility.managerLevel
            && state.coins >= facility.managerCost
    }

    @discardableResult
    func hireManager(_ state: inout GameState, id: String) -> Bool {
        guard canHireManager(state, id: id), let facility = config.facility(id) else { return false }
        state.coins -= facility.managerCost
        state.managers.insert(id)
        return true
    }

    // MARK: - Zeit: Vordergrund und Offline

    /// Wird etwa jede Sekunde aufgerufen, solange die App offen ist. Alle Einrichtungen verdienen.
    func tick(_ state: inout GameState, now: Date) -> [GameEvent] {
        let elapsed = now.timeIntervalSince(state.lastActive)
        if elapsed < 0 {
            // Geräteuhr wurde zurückgestellt: nichts gutschreiben, nur neu ansetzen.
            state.lastActive = now
            return []
        }
        // Große Lücken (App war im Hintergrund) behandelt applyOffline, nicht der Tick.
        let step = min(elapsed, 5)
        earn(&state, incomePerSecond(state, now: now) * step)
        accrueCards(&state, seconds: step, managedOnly: false)
        state.lastActive = now
        rolloverDayIfNeeded(&state, now: now)
        return processDueMatches(&state, now: now, interactive: true)
    }

    func offlineCapSeconds(_ state: GameState) -> Double {
        let hours = state.offlineCapLevel == 0
            ? config.offline.baseCapHours
            : config.offline.upgrades[min(state.offlineCapLevel, config.offline.upgrades.count) - 1].hours
        return hours * 3600
    }

    /// Wird aufgerufen, wenn die App wieder in den Vordergrund kommt.
    /// Gibt einen Bericht zurück, wenn mindestens eine Minute vergangen ist.
    func applyOffline(_ state: inout GameState, now: Date) -> OfflineReport? {
        let raw = now.timeIntervalSince(state.lastActive)
        if raw < 0 {
            state.lastActive = now
            return nil
        }
        guard raw > 5 else { return nil }
        let seconds = min(raw, offlineCapSeconds(state))
        let coins = incomePerSecond(state, now: now, managedOnly: true, includeBoost: false) * seconds
        earn(&state, coins)
        accrueCards(&state, seconds: seconds, managedOnly: true)
        state.lastActive = now
        rolloverDayIfNeeded(&state, now: now)

        let events = processDueMatches(&state, now: now, interactive: false)
        var matches = 0
        var wins = 0
        for case .matchPlayed(let result) in events where result.home == Self.playerTeamId || result.away == Self.playerTeamId {
            matches += 1
            if didPlayerWin(result) { wins += 1 }
        }
        guard raw >= 60 else { return nil }
        return OfflineReport(seconds: seconds, coins: coins, matchesPlayed: matches, wins: wins)
    }

    // MARK: - Team

    func makePlayer(position: Position, rarity: Rarity) -> Player {
        let rarityConfig = config.rarity(rarity)
        let range = rarityConfig.statMin...rarityConfig.statMax
        return Player(
            id: UUID(),
            firstName: config.names.firstNames.randomElement(using: &rng) ?? "Max",
            lastName: config.names.lastNames.randomElement(using: &rng) ?? "Puck",
            position: position,
            rarity: rarity,
            attack: Int.random(in: range, using: &rng),
            defense: Int.random(in: range, using: &rng),
            speed: Int.random(in: range, using: &rng),
            level: 1
        )
    }

    func rating(_ player: Player) -> Double {
        let base = Double(player.attack + player.defense + player.speed) / 3
        return base * (1 + config.training.ratingGainPerLevel * Double(player.level - 1))
    }

    func starters(_ state: GameState) -> [Player] {
        state.players.filter { state.starters.contains($0.id) }
    }

    func teamStrength(_ state: GameState) -> Double {
        let base = starters(state).reduce(0) { $0 + rating($1) }
        return base * (1 + facilityBonus(state, kind: .strength))
    }

    private func randomRarity() -> Rarity {
        let total = config.scouting.rarities.reduce(0) { $0 + $1.weight }
        var roll = Double.random(in: 0..<total, using: &rng)
        for entry in config.scouting.rarities {
            if roll < entry.weight { return entry.rarity }
            roll -= entry.weight
        }
        return .common
    }

    private func randomPosition() -> Position {
        // Verteilung wie im Kader: 1 Torhüter, 2 Verteidiger, 3 Stürmer.
        let roll = Int.random(in: 0..<6, using: &rng)
        if roll == 0 { return .goalie }
        if roll < 3 { return .defense }
        return .forward
    }

    func rosterIsFull(_ state: GameState) -> Bool {
        state.players.count >= config.scouting.maxRoster
    }

    /// Scouting-Paket öffnen. `paid`: kostet Pucks, sonst gratis (Video, Belohnung).
    func scout(_ state: inout GameState, paid: Bool, rarity: Rarity? = nil) -> Player? {
        guard !rosterIsFull(state) else { return nil }
        if paid {
            guard state.pucks >= config.scouting.costPucks else { return nil }
            state.pucks -= config.scouting.costPucks
        }
        let player = makePlayer(position: randomPosition(), rarity: rarity ?? randomRarity())
        state.players.append(player)
        progressQuests(&state, kind: .scoutPlayer)
        return player
    }

    func trainingCost(_ player: Player) -> Int {
        player.level * config.training.cardsPerLevel
    }

    @discardableResult
    func train(_ state: inout GameState, playerId: UUID) -> Bool {
        guard let index = state.players.firstIndex(where: { $0.id == playerId }) else { return false }
        let player = state.players[index]
        let cost = trainingCost(player)
        guard player.level < config.training.maxLevel, state.trainingCards >= cost else { return false }
        state.trainingCards -= cost
        state.players[index].level += 1
        progressQuests(&state, kind: .trainPlayer)
        return true
    }

    /// Spieler entlassen und dafür Trainingskarten erhalten. Stammspieler können nicht entlassen werden.
    @discardableResult
    func release(_ state: inout GameState, playerId: UUID) -> Bool {
        guard !state.starters.contains(playerId),
              let index = state.players.firstIndex(where: { $0.id == playerId }) else { return false }
        let player = state.players.remove(at: index)
        state.trainingCards += config.rarity(player.rarity).releaseCards
        return true
    }

    /// Setzt einen Spieler in die Aufstellung und ersetzt den schwächsten Stammspieler derselben Position.
    @discardableResult
    func makeStarter(_ state: inout GameState, playerId: UUID) -> Bool {
        guard !state.starters.contains(playerId),
              let player = state.players.first(where: { $0.id == playerId }) else { return false }
        let samePosition = starters(state).filter { $0.position == player.position }
        guard let weakest = samePosition.min(by: { rating($0) < rating($1) }),
              let slot = state.starters.firstIndex(of: weakest.id) else { return false }
        state.starters[slot] = playerId
        return true
    }

    /// Stellt automatisch die stärksten Spieler pro Position auf.
    func autoLineup(_ state: inout GameState) {
        var lineup: [UUID] = []
        for position in Position.allCases {
            let best = state.players
                .filter { $0.position == position }
                .sorted { rating($0) > rating($1) }
                .prefix(position.starterSlots)
            lineup.append(contentsOf: best.map(\.id))
        }
        state.starters = lineup
    }

    // MARK: - Liga und Spiele

    func makeSeason(tier: Int) -> Season {
        let league = config.league(tier)
        let opponents = config.teams
            .shuffled(using: &rng)
            .prefix(config.teamsPerLeague - 1)
            .map { team in
                Opponent(id: team.id, strength: Double.random(in: league.opponentStrengthMin...league.opponentStrengthMax, using: &rng))
            }
        let ids = [Self.playerTeamId] + opponents.map(\.id)
        return Season(
            tier: tier,
            opponents: opponents,
            fixtures: roundRobin(ids, rounds: config.seasonLength),
            round: 0,
            standings: ids.map { Standing(teamId: $0) },
            results: []
        )
    }

    /// Spielplan nach dem Kreisverfahren: In jeder Runde spielt jedes Team genau einmal.
    /// Nach n-1 Runden werden Heim und Gast getauscht (Rückrunde).
    func roundRobin(_ ids: [String], rounds: Int) -> [Fixture] {
        var rotation = ids
        if rotation.count % 2 == 1 { rotation.append("bye") }
        let count = rotation.count
        var fixtures: [Fixture] = []
        for round in 0..<rounds {
            let secondLeg = (round / (count - 1)) % 2 == 1
            for i in 0..<(count / 2) {
                let a = rotation[i]
                let b = rotation[count - 1 - i]
                if a == "bye" || b == "bye" { continue }
                fixtures.append(secondLeg
                    ? Fixture(round: round, home: b, away: a)
                    : Fixture(round: round, home: a, away: b))
            }
            let last = rotation.removeLast()
            rotation.insert(last, at: 1)
        }
        return fixtures
    }

    func matchInterval(_ state: GameState) -> Double {
        config.league(state.season.tier).matchIntervalSeconds
    }

    func strength(of teamId: String, in state: GameState) -> Double {
        if teamId == Self.playerTeamId { return teamStrength(state) }
        return state.season.opponents.first { $0.id == teamId }?.strength ?? 1
    }

    /// Siegwahrscheinlichkeit von A gegen B ohne Unentschieden.
    func winProbability(_ a: Double, _ b: Double) -> Double {
        let ratio = a / max(b, 1)
        return 1 / (1 + exp(-config.match.steepness * (ratio - 1)))
    }

    func didPlayerWin(_ result: MatchResult) -> Bool {
        result.home == Self.playerTeamId ? result.homeWon : !result.homeWon
    }

    func processDueMatches(_ state: inout GameState, now: Date, interactive: Bool) -> [GameEvent] {
        var events: [GameEvent] = []
        var played = 0
        while state.nextMatchDate <= now {
            if played >= config.match.maxCatchUpMatches {
                state.nextMatchDate = now.addingTimeInterval(matchInterval(state))
                break
            }
            if state.pendingShootout != nil {
                events += resolvePendingShootoutAutomatically(&state)
            }
            events += playRound(&state, interactive: interactive)
            played += 1
            state.nextMatchDate = state.nextMatchDate.addingTimeInterval(matchInterval(state))
        }
        return events
    }

    private func playRound(_ state: inout GameState, interactive: Bool) -> [GameEvent] {
        var events: [GameEvent] = []
        let round = state.season.round
        state.replayableResultId = nil
        for fixture in state.season.fixtures where fixture.round == round {
            let homeStrength = strength(of: fixture.home, in: state)
            let awayStrength = strength(of: fixture.away, in: state)
            let involvesPlayer = fixture.involves(Self.playerTeamId)

            if Double.random(in: 0..<1, using: &rng) < config.match.drawChance {
                let goals = Int.random(in: 1...3, using: &rng)
                if involvesPlayer && interactive {
                    state.pendingShootout = PendingShootout(fixture: fixture, regulationGoals: goals)
                    events.append(.shootoutPending)
                    continue
                }
                let homeWins = Double.random(in: 0..<1, using: &rng) < winProbability(homeStrength, awayStrength)
                let result = MatchResult(
                    id: UUID(), round: round, home: fixture.home, away: fixture.away,
                    homeGoals: goals + (homeWins ? 1 : 0), awayGoals: goals + (homeWins ? 0 : 1), shootout: true
                )
                record(&state, result, rewardFactor: involvesPlayer ? config.match.skipRewardFactor : 1)
                events.append(.matchPlayed(result))
            } else {
                let result = simulateRegulation(fixture: fixture, round: round, homeStrength: homeStrength, awayStrength: awayStrength)
                record(&state, result, rewardFactor: 1)
                events.append(.matchPlayed(result))
            }
        }
        if state.pendingShootout == nil {
            events += finishRound(&state)
        }
        return events
    }

    private func simulateRegulation(fixture: Fixture, round: Int, homeStrength: Double, awayStrength: Double) -> MatchResult {
        let homeWins = Double.random(in: 0..<1, using: &rng) < winProbability(homeStrength, awayStrength)
        let winnerGoals = Int.random(in: 2...5, using: &rng)
        let loserGoals = Int.random(in: 0..<winnerGoals, using: &rng)
        return MatchResult(
            id: UUID(), round: round, home: fixture.home, away: fixture.away,
            homeGoals: homeWins ? winnerGoals : loserGoals,
            awayGoals: homeWins ? loserGoals : winnerGoals,
            shootout: false
        )
    }

    /// Trägt ein Ergebnis in die Tabelle ein. `sign` = -1 nimmt es wieder heraus (für „Spiel wiederholen“).
    private func applyToStandings(_ season: inout Season, _ result: MatchResult, sign: Int) {
        let homeWon = result.homeWon
        for (teamId, isHome) in [(result.home, true), (result.away, false)] {
            guard let index = season.standings.firstIndex(where: { $0.teamId == teamId }) else { continue }
            let won = isHome ? homeWon : !homeWon
            season.standings[index].played += sign
            season.standings[index].goalsFor += sign * (isHome ? result.homeGoals : result.awayGoals)
            season.standings[index].goalsAgainst += sign * (isHome ? result.awayGoals : result.homeGoals)
            switch (won, result.shootout) {
            case (true, false):
                season.standings[index].wins += sign
                season.standings[index].points += sign * 3
            case (true, true):
                season.standings[index].shootoutWins += sign
                season.standings[index].points += sign * 2
            case (false, true):
                season.standings[index].shootoutLosses += sign
                season.standings[index].points += sign * 1
            case (false, false):
                season.standings[index].losses += sign
            }
        }
    }

    private func record(_ state: inout GameState, _ result: MatchResult, rewardFactor: Double) {
        applyToStandings(&state.season, result, sign: 1)
        state.season.results.insert(result, at: 0)

        guard result.home == Self.playerTeamId || result.away == Self.playerTeamId else { return }
        let income = incomePerSecond(state, now: state.lastActive, includeBoost: false)
        if didPlayerWin(result) {
            earn(&state, income * config.match.winRewardIncomeSeconds * rewardFactor)
            state.fans += Int(Double(config.league(state.season.tier).fansPerWin) * rewardFactor)
            progressQuests(&state, kind: .winMatches)
        } else {
            earn(&state, income * config.match.lossRewardIncomeSeconds * rewardFactor)
            state.replayableResultId = result.id
        }
    }

    private func finishRound(_ state: inout GameState) -> [GameEvent] {
        state.season.round += 1
        guard state.season.round >= config.seasonLength else { return [] }
        let summary = endSeason(&state)
        return [.seasonEnded(summary)]
    }

    func sortedStandings(_ season: Season) -> [Standing] {
        season.standings.sorted {
            if $0.points != $1.points { return $0.points > $1.points }
            if $0.goalDifference != $1.goalDifference { return $0.goalDifference > $1.goalDifference }
            if $0.goalsFor != $1.goalsFor { return $0.goalsFor > $1.goalsFor }
            // Bei völligem Gleichstand liegt der eigene Verein vorn.
            return $0.teamId == Self.playerTeamId
        }
    }

    func playerRank(_ season: Season) -> Int {
        (sortedStandings(season).firstIndex { $0.teamId == Self.playerTeamId } ?? 0) + 1
    }

    private func endSeason(_ state: inout GameState) -> SeasonSummary {
        let tier = state.season.tier
        let rank = playerRank(state.season)
        let league = config.league(tier)
        let promoted = rank <= config.promotionSlots && tier < config.maxLeagueTier
        let teams = Double(config.teamsPerLeague)
        let rankFactor = (teams - Double(rank) + 1) / teams
        let rewardCoins = incomePerSecond(state, now: state.lastActive, includeBoost: false) *
            config.match.seasonRewardIncomeSeconds * rankFactor
        let rewardPucks = league.seasonRewardPucks.indices.contains(rank - 1) ? league.seasonRewardPucks[rank - 1] : 0

        earn(&state, rewardCoins)
        state.pucks += rewardPucks
        let summary = SeasonSummary(tier: tier, rank: rank, promoted: promoted, rewardCoins: rewardCoins, rewardPucks: rewardPucks)
        state.season = makeSeason(tier: promoted ? tier + 1 : tier)
        state.lastSeasonSummary = summary
        state.replayableResultId = nil
        return summary
    }

    // MARK: - Penalty-Schießen

    /// Torbreite (Anteil der Bildschirmbreite) und Torwart-Tempo (Bildschirmbreiten pro Sekunde).
    func penaltyParameters(_ state: GameState) -> (goalWidth: Double, goalieSpeed: Double) {
        let forwards = starters(state).filter { $0.position == .forward }
        let attack = forwards.isEmpty ? 10 : forwards.reduce(0) { $0 + rating($1) } / Double(forwards.count)
        let goalWidth = min(0.75, 0.45 + attack * 0.006)
        let goalieSpeed = 0.55 + 0.1 * Double(state.season.tier)
        return (goalWidth, goalieSpeed)
    }

    /// Ergebnis des Minispiels für ein Ligaspiel. Die Gegnertore werden simuliert.
    func resolvePendingShootout(_ state: inout GameState, playerGoals: Int) -> (ShootoutOutcome, [GameEvent])? {
        guard let pending = state.pendingShootout else { return nil }
        let opponentId = pending.fixture.home == Self.playerTeamId ? pending.fixture.away : pending.fixture.home
        let ratio = strength(of: opponentId, in: state) / max(teamStrength(state), 1)
        let opponentChance = min(0.7, max(0.2, 0.4 * ratio))
        var opponentGoals = 0
        for _ in 0..<config.match.shootoutShots where Double.random(in: 0..<1, using: &rng) < opponentChance {
            opponentGoals += 1
        }
        let won = playerGoals == opponentGoals
            ? Bool.random(using: &rng)
            : playerGoals > opponentGoals
        let outcome = ShootoutOutcome(playerGoals: playerGoals, opponentGoals: opponentGoals, won: won)
        let events = finishShootout(&state, pending: pending, playerWon: won, rewardFactor: 1)
        progressQuests(&state, kind: .playShootout)
        return (outcome, events)
    }

    /// Penalty-Schießen übersprungen oder verpasst: automatisch entscheiden, mit geringerer Belohnung.
    func resolvePendingShootoutAutomatically(_ state: inout GameState) -> [GameEvent] {
        guard let pending = state.pendingShootout else { return [] }
        let opponentId = pending.fixture.home == Self.playerTeamId ? pending.fixture.away : pending.fixture.home
        let won = Double.random(in: 0..<1, using: &rng) < winProbability(teamStrength(state), strength(of: opponentId, in: state))
        return finishShootout(&state, pending: pending, playerWon: won, rewardFactor: config.match.skipRewardFactor)
    }

    private func finishShootout(_ state: inout GameState, pending: PendingShootout, playerWon: Bool, rewardFactor: Double) -> [GameEvent] {
        let playerIsHome = pending.fixture.home == Self.playerTeamId
        let homeWins = playerIsHome == playerWon
        let goals = pending.regulationGoals
        let result = MatchResult(
            id: UUID(), round: pending.fixture.round, home: pending.fixture.home, away: pending.fixture.away,
            homeGoals: goals + (homeWins ? 1 : 0), awayGoals: goals + (homeWins ? 0 : 1), shootout: true
        )
        state.pendingShootout = nil
        record(&state, result, rewardFactor: rewardFactor)
        return [.matchPlayed(result)] + finishRound(&state)
    }

    // MARK: - Spiel wiederholen (Belohnungsvideo)

    /// Nimmt die letzte Niederlage aus der Tabelle und spielt die Partie neu.
    func replayLastLoss(_ state: inout GameState) -> MatchResult? {
        guard let id = state.replayableResultId,
              let index = state.season.results.firstIndex(where: { $0.id == id }) else { return nil }
        let old = state.season.results.remove(at: index)
        applyToStandings(&state.season, old, sign: -1)
        state.replayableResultId = nil

        let fixture = Fixture(round: old.round, home: old.home, away: old.away)
        let result = simulateRegulation(
            fixture: fixture, round: old.round,
            homeStrength: strength(of: old.home, in: state),
            awayStrength: strength(of: old.away, in: state)
        )
        record(&state, result, rewardFactor: 1)
        return result
    }

    // MARK: - Penalty-Training

    func practiceAttemptsLeft(_ state: GameState) -> Int {
        max(0, config.practice.freePerDay - state.daily.practiceUsed)
    }

    /// Verbraucht einen kostenlosen Trainingsversuch. false, wenn heute keiner mehr übrig ist.
    @discardableResult
    func usePracticeAttempt(_ state: inout GameState) -> Bool {
        guard practiceAttemptsLeft(state) > 0 else { return false }
        state.daily.practiceUsed += 1
        return true
    }

    func applyPracticeResult(_ state: inout GameState, goals: Int, now: Date) -> PracticeReward {
        let coins = incomePerSecond(state, now: now, includeBoost: false) * config.practice.coinsPerGoalIncomeSeconds * Double(goals)
        let cards = goals * config.practice.cardsPerGoal
        earn(&state, coins)
        state.trainingCards += cards
        var bonus: Player?
        if goals >= config.match.shootoutShots {
            bonus = scout(&state, paid: false)
        }
        progressQuests(&state, kind: .playShootout)
        return PracticeReward(goals: goals, coins: coins, cards: cards, bonusPlayer: bonus)
    }

    // MARK: - Prestige

    func prestigePointsAvailable(_ state: GameState) -> Int {
        Int(floor(sqrt(max(0, state.runEarnings) / config.prestige.earningsDivisor)))
    }

    func canPrestige(_ state: GameState) -> Bool {
        state.season.tier >= config.prestige.minTier && prestigePointsAvailable(state) > 0
    }

    /// Verein verkaufen: Einrichtungen, Münzen, Fans und Liga starten neu.
    /// Spieler, Pucks, Karten, Käufe und Legendenpunkte bleiben erhalten.
    @discardableResult
    func prestige(_ state: inout GameState, now: Date) -> Int {
        guard canPrestige(state) else { return 0 }
        let points = prestigePointsAvailable(state)
        state.legendPoints += points
        state.prestigeCount += 1
        state.coins = config.start.coins
        state.runEarnings = 0
        state.fans = 0
        state.facilityLevels = [config.facilities[0].id: 1]
        state.managers = []
        state.season = makeSeason(tier: 1)
        state.pendingShootout = nil
        state.replayableResultId = nil
        state.lastSeasonSummary = nil
        state.nextMatchDate = now.addingTimeInterval(config.league(1).matchIntervalSeconds)
        return points
    }

    // MARK: - Tageslogik: Login-Kalender, Aufgaben, Limits

    func dayKey(_ date: Date) -> String {
        let parts = calendar.dateComponents([.year, .month, .day], from: date)
        return String(format: "%04d-%02d-%02d", parts.year ?? 0, parts.month ?? 0, parts.day ?? 0)
    }

    func rolloverDayIfNeeded(_ state: inout GameState, now: Date) {
        let today = dayKey(now)
        guard state.daily.dayKey != today else { return }
        let yesterday = calendar.date(byAdding: .day, value: -1, to: now).map { dayKey($0) } ?? ""
        if state.daily.lastLoginClaimDay != yesterday && state.daily.lastLoginClaimDay != today {
            state.daily.loginStreak = 0
        }
        state.daily.dayKey = today
        state.daily.rewardedUses = [:]
        state.daily.practiceUsed = 0
        state.daily.quests = config.quests
            .shuffled(using: &rng)
            .prefix(config.dailyQuestCount)
            .map { QuestProgress(id: $0.id, kind: $0.kind, target: $0.target, rewardPucks: $0.rewardPucks, progress: 0, claimed: false) }
    }

    func canClaimLogin(_ state: GameState) -> Bool {
        state.daily.lastLoginClaimDay != state.daily.dayKey
    }

    /// Tag im 7-Tage-Kalender (0 bis 6), der als Nächstes abgeholt wird.
    func loginCalendarIndex(_ state: GameState) -> Int {
        state.daily.loginStreak % config.loginRewardPucks.count
    }

    @discardableResult
    func claimLogin(_ state: inout GameState) -> Int {
        guard canClaimLogin(state) else { return 0 }
        let reward = config.loginRewardPucks[loginCalendarIndex(state)]
        state.pucks += reward
        state.daily.loginStreak += 1
        state.daily.lastLoginClaimDay = state.daily.dayKey
        return reward
    }

    func progressQuests(_ state: inout GameState, kind: QuestKind, amount: Int = 1) {
        for index in state.daily.quests.indices where state.daily.quests[index].kind == kind && !state.daily.quests[index].claimed {
            state.daily.quests[index].progress = min(state.daily.quests[index].target, state.daily.quests[index].progress + amount)
        }
    }

    @discardableResult
    func claimQuest(_ state: inout GameState, id: String) -> Int {
        guard let index = state.daily.quests.firstIndex(where: { $0.id == id }),
              state.daily.quests[index].isComplete, !state.daily.quests[index].claimed else { return 0 }
        state.daily.quests[index].claimed = true
        state.pucks += state.daily.quests[index].rewardPucks
        return state.daily.quests[index].rewardPucks
    }

    /// Verbleibende Videos heute; nil bedeutet: kein Limit.
    func rewardedRemaining(_ state: GameState, kind: RewardedKind) -> Int? {
        guard let limit = config.rewarded.dailyLimits[kind.rawValue] else { return nil }
        return max(0, limit - (state.daily.rewardedUses[kind.rawValue] ?? 0))
    }

    func canUseRewarded(_ state: GameState, kind: RewardedKind) -> Bool {
        (rewardedRemaining(state, kind: kind) ?? 1) > 0
    }

    func registerRewarded(_ state: inout GameState, kind: RewardedKind) {
        state.daily.rewardedUses[kind.rawValue, default: 0] += 1
        progressQuests(&state, kind: .watchAd)
    }

    func applyBoost(_ state: inout GameState, now: Date, hours: Double) {
        let start = max(now, state.boostUntil ?? now)
        let maxEnd = now.addingTimeInterval(config.rewarded.boostMaxHours * 3600)
        state.boostUntil = min(start.addingTimeInterval(hours * 3600), maxEnd)
    }

    // MARK: - Shop

    func nextOfflineUpgrade(_ state: GameState) -> OfflineCapUpgrade? {
        config.offline.upgrades.indices.contains(state.offlineCapLevel) ? config.offline.upgrades[state.offlineCapLevel] : nil
    }

    @discardableResult
    func buyOfflineUpgrade(_ state: inout GameState) -> Bool {
        guard let upgrade = nextOfflineUpgrade(state), state.pucks >= upgrade.pucks else { return false }
        state.pucks -= upgrade.pucks
        state.offlineCapLevel += 1
        return true
    }

    func timeSkipCoins(_ state: GameState, now: Date) -> Double {
        incomePerSecond(state, now: now, includeBoost: false) * config.shop.timeSkipHours * 3600
    }

    @discardableResult
    func buyTimeSkip(_ state: inout GameState, now: Date) -> Double {
        guard state.pucks >= config.shop.timeSkipPucks else { return 0 }
        state.pucks -= config.shop.timeSkipPucks
        let coins = timeSkipCoins(state, now: now)
        earn(&state, coins)
        return coins
    }

    func isStarterPackAvailable(_ state: GameState, now: Date) -> Bool {
        !state.starterPackBought && now < state.firstLaunch.addingTimeInterval(config.starter.windowHours * 3600)
    }

    /// Schreibt einen bestätigten In-App-Kauf gut. Einmalkäufe werden nie doppelt gutgeschrieben.
    @discardableResult
    func applyPurchase(_ state: inout GameState, productId: String, now: Date) -> Bool {
        let products = config.products
        if productId == products.starterPack {
            guard !state.starterPackBought else { return false }
            state.starterPackBought = true
            state.pucks += config.starter.pucks
            let player = makePlayer(position: randomPosition(), rarity: config.starter.rarity)
            state.players.append(player)
            applyBoost(&state, now: now, hours: config.starter.boostHours)
            return true
        }
        if productId == products.adFree {
            guard !state.adFree else { return false }
            state.adFree = true
            return true
        }
        if let pack = products.pucks.first(where: { $0.id == productId }) {
            state.pucks += pack.pucks
            return true
        }
        return false
    }
}
