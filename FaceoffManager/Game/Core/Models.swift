import Foundation

enum Position: String, Codable, CaseIterable {
    case goalie
    case defense
    case forward

    /// Anzahl der Startplätze pro Position (1 Torhüter, 2 Verteidiger, 3 Stürmer).
    var starterSlots: Int {
        switch self {
        case .goalie: return 1
        case .defense: return 2
        case .forward: return 3
        }
    }
}

enum Rarity: String, Codable, CaseIterable {
    case common
    case rare
    case epic
    case legendary
}

struct Player: Codable, Identifiable, Equatable {
    var id: UUID
    var firstName: String
    var lastName: String
    var position: Position
    var rarity: Rarity
    var attack: Int
    var defense: Int
    var speed: Int
    var level: Int

    var fullName: String { "\(firstName) \(lastName)" }
}

/// Ein Gegner in der aktuellen Saison. Der eigene Verein hat die id "player".
struct Opponent: Codable, Identifiable, Equatable {
    let id: String
    let strength: Double
}

struct Fixture: Codable, Equatable {
    let round: Int
    let home: String
    let away: String

    func involves(_ teamId: String) -> Bool { home == teamId || away == teamId }
}

struct MatchResult: Codable, Identifiable, Equatable {
    let id: UUID
    let round: Int
    let home: String
    let away: String
    let homeGoals: Int
    let awayGoals: Int
    let shootout: Bool

    var homeWon: Bool { homeGoals > awayGoals }
}

struct Standing: Codable, Equatable {
    let teamId: String
    var played = 0
    var wins = 0
    var shootoutWins = 0
    var shootoutLosses = 0
    var losses = 0
    var goalsFor = 0
    var goalsAgainst = 0
    var points = 0

    var goalDifference: Int { goalsFor - goalsAgainst }
}

struct Season: Codable, Equatable {
    var tier: Int
    var opponents: [Opponent]
    var fixtures: [Fixture]
    /// Nächste zu spielende Runde (0-basiert).
    var round: Int
    var standings: [Standing]
    /// Neueste Ergebnisse zuerst, begrenzt auf die laufende Saison.
    var results: [MatchResult]
}

/// Ein Unentschieden des eigenen Teams, das noch per Penalty-Schießen entschieden werden muss.
struct PendingShootout: Codable, Equatable {
    let fixture: Fixture
    let regulationGoals: Int
}

struct SeasonSummary: Codable, Equatable, Identifiable {
    var id: String { "\(tier)-\(rank)-\(rewardPucks)-\(rewardCoins)" }
    let tier: Int
    let rank: Int
    let promoted: Bool
    let rewardCoins: Double
    let rewardPucks: Int
}

struct QuestProgress: Codable, Identifiable, Equatable {
    let id: String
    let kind: QuestKind
    let target: Int
    let rewardPucks: Int
    var progress: Int
    var claimed: Bool

    var isComplete: Bool { progress >= target }
}

struct DailyState: Codable, Equatable {
    var dayKey: String = ""
    var loginStreak: Int = 0
    var lastLoginClaimDay: String = ""
    var rewardedUses: [String: Int] = [:]
    var practiceUsed: Int = 0
    var quests: [QuestProgress] = []
}

struct GameState: Codable, Equatable {
    var version: Int = 1
    var clubName: String
    var coins: Double
    var pucks: Int
    var trainingCards: Int
    var fractionalCards: Double = 0
    var legendPoints: Int = 0
    var prestigeCount: Int = 0
    var runEarnings: Double = 0
    var totalEarnings: Double = 0
    var fans: Int = 0
    var facilityLevels: [String: Int]
    var managers: Set<String> = []
    var players: [Player]
    var starters: [UUID]
    var season: Season
    var nextMatchDate: Date
    var pendingShootout: PendingShootout?
    /// Zuletzt verlorenes Spiel, das per Video wiederholt werden darf.
    var replayableResultId: UUID?
    var lastSeasonSummary: SeasonSummary?
    var boostUntil: Date?
    var offlineCapLevel: Int = 0
    var lastActive: Date
    var firstLaunch: Date
    var adFree: Bool = false
    var starterPackBought: Bool = false
    var daily = DailyState()

    func level(_ facilityId: String) -> Int { facilityLevels[facilityId] ?? 0 }
}

enum GameEvent: Equatable {
    case matchPlayed(MatchResult)
    case shootoutPending
    case seasonEnded(SeasonSummary)
}

struct OfflineReport: Equatable, Identifiable {
    let id = UUID()
    let seconds: Double
    let coins: Double
    let matchesPlayed: Int
    let wins: Int
}

struct ShootoutOutcome: Equatable {
    let playerGoals: Int
    let opponentGoals: Int
    let won: Bool
}

struct PracticeReward: Equatable {
    let goals: Int
    let coins: Double
    let cards: Int
    let bonusPlayer: Player?
}
