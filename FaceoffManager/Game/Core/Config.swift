import Foundation

// Alle Spielwerte stehen in Resources/GameConfig.json.
// Diese Typen spiegeln die Datei 1:1 wider. Neue Felder immer in beiden ergänzen.

enum FacilityKind: String, Codable {
    /// Bringt nur Münzen.
    case income
    /// Bringt Münzen und erhöht die Teamstärke um effectPerLevel pro Stufe (0.02 = 2 %).
    case strength
    /// Erhöht alle Einnahmen um effectPerLevel pro Stufe.
    case multiplier
    /// Bringt Münzen und effectPerLevel Trainingskarten pro Stunde und Stufe.
    case cards
}

struct FacilityConfig: Codable, Identifiable {
    let id: String
    let unlockTier: Int
    let baseCost: Double
    let baseIncome: Double
    let kind: FacilityKind
    let effectPerLevel: Double
    let managerLevel: Int
    let managerCost: Double
    let symbol: String
}

struct LeagueConfig: Codable {
    let tier: Int
    let nameKey: String
    let matchIntervalSeconds: Double
    let opponentStrengthMin: Double
    let opponentStrengthMax: Double
    let fansPerWin: Int
    /// Pucks nach Tabellenplatz (Index 0 = Platz 1).
    let seasonRewardPucks: [Int]
}

struct MatchConfig: Codable {
    let drawChance: Double
    let steepness: Double
    let winRewardIncomeSeconds: Double
    let lossRewardIncomeSeconds: Double
    let seasonRewardIncomeSeconds: Double
    /// Belohnungsfaktor, wenn ein Penalty-Schießen übersprungen oder automatisch entschieden wird.
    let skipRewardFactor: Double
    let maxCatchUpMatches: Int
    let shootoutShots: Int
}

struct OfflineCapUpgrade: Codable {
    let hours: Double
    let pucks: Int
}

struct OfflineConfig: Codable {
    let baseCapHours: Double
    let upgrades: [OfflineCapUpgrade]
}

enum RewardedKind: String, Codable, CaseIterable {
    case boost
    case offlineDouble
    case practiceExtra
    case freeScout
    case replay
}

struct RewardedConfig: Codable {
    let boostHours: Double
    let boostMaxHours: Double
    /// Tageslimit pro Belohnungsart. Fehlt ein Eintrag, gibt es kein Limit.
    let dailyLimits: [String: Int]
}

struct RarityConfig: Codable {
    let rarity: Rarity
    let weight: Double
    let statMin: Int
    let statMax: Int
    let releaseCards: Int
}

struct ScoutingConfig: Codable {
    let costPucks: Int
    let rarities: [RarityConfig]
    let maxRoster: Int
}

struct TrainingConfig: Codable {
    let cardsPerLevel: Int
    let maxLevel: Int
    let ratingGainPerLevel: Double
}

struct PracticeConfig: Codable {
    let freePerDay: Int
    let coinsPerGoalIncomeSeconds: Double
    let cardsPerGoal: Int
}

struct PrestigeConfig: Codable {
    let minTier: Int
    let earningsDivisor: Double
    let multiplierPerPoint: Double
}

enum QuestKind: String, Codable {
    case winMatches
    case upgradeFacility
    case playShootout
    case watchAd
    case scoutPlayer
    case trainPlayer
}

struct QuestConfig: Codable {
    let id: String
    let kind: QuestKind
    let target: Int
    let rewardPucks: Int
}

struct StarterConfig: Codable {
    let windowHours: Double
    let pucks: Int
    let boostHours: Double
    let rarity: Rarity
}

struct ShopConfig: Codable {
    let timeSkipHours: Double
    let timeSkipPucks: Int
    let adFreeIncomeBonus: Double
}

struct PuckProduct: Codable {
    let id: String
    let pucks: Int
}

struct ProductConfig: Codable {
    let starterPack: String
    let adFree: String
    let pucks: [PuckProduct]

    var allIDs: [String] { [starterPack, adFree] + pucks.map(\.id) }
}

struct TeamConfig: Codable {
    let id: String
    let name: String
}

struct NameConfig: Codable {
    let firstNames: [String]
    let lastNames: [String]
}

struct StartConfig: Codable {
    let coins: Double
    let pucks: Int
    let cards: Int
    let clubName: String
}

struct GameConfig: Codable {
    let costGrowth: Double
    let milestoneLevels: [Int]
    let fanIncomeFactor: Double
    let seasonLength: Int
    let teamsPerLeague: Int
    let promotionSlots: Int
    let maxLeagueTier: Int
    let start: StartConfig
    let facilities: [FacilityConfig]
    let leagues: [LeagueConfig]
    let match: MatchConfig
    let offline: OfflineConfig
    let rewarded: RewardedConfig
    let scouting: ScoutingConfig
    let training: TrainingConfig
    let practice: PracticeConfig
    let prestige: PrestigeConfig
    let loginRewardPucks: [Int]
    let dailyQuestCount: Int
    let quests: [QuestConfig]
    let starter: StarterConfig
    let shop: ShopConfig
    let products: ProductConfig
    let teams: [TeamConfig]
    let names: NameConfig

    func facility(_ id: String) -> FacilityConfig? {
        facilities.first { $0.id == id }
    }

    func league(_ tier: Int) -> LeagueConfig {
        leagues.first { $0.tier == tier } ?? leagues[0]
    }

    func rarity(_ rarity: Rarity) -> RarityConfig {
        scouting.rarities.first { $0.rarity == rarity } ?? scouting.rarities[0]
    }

    func teamName(_ id: String) -> String? {
        teams.first { $0.id == id }?.name
    }

    static func load(from url: URL) throws -> GameConfig {
        let data = try Data(contentsOf: url)
        return try JSONDecoder().decode(GameConfig.self, from: data)
    }
}
