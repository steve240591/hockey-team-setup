import SwiftUI

struct TeamView: View {
    @EnvironmentObject var store: GameStore
    @State private var playerToRelease: Player?

    private var starters: [Player] {
        Position.allCases.flatMap { position in
            store.engine.starters(store.state)
                .filter { $0.position == position }
                .sorted { store.engine.rating($0) > store.engine.rating($1) }
        }
    }

    private var bench: [Player] {
        store.state.players
            .filter { !store.state.starters.contains($0.id) }
            .sorted { store.engine.rating($0) > store.engine.rating($1) }
    }

    var body: some View {
        NavigationStack {
            List {
                Section {
                    HStack {
                        Label(L("team.strength"), systemImage: "bolt.shield.fill")
                        Spacer()
                        Text(Fmt.number(store.teamStrength)).font(.title3.monospacedDigit().bold())
                    }
                    Button(L("team.autoLineup")) { store.autoLineup() }
                }

                Section(L("team.lineup")) {
                    ForEach(starters) { player in
                        PlayerRow(player: player, isStarter: true, onRelease: nil)
                    }
                }

                Section {
                    Button {
                        store.scoutWithPucks()
                    } label: {
                        Label(LF("team.scoutPucks", Fmt.integer(store.config.scouting.costPucks)), systemImage: "magnifyingglass")
                    }
                    .disabled(store.state.pucks < store.config.scouting.costPucks)
                    AdButton(title: L("team.scoutFree"), kind: .freeScout) {
                        store.scoutWithAd()
                    }
                } header: {
                    Text(L("team.scouting"))
                } footer: {
                    Text(oddsText)
                }

                Section {
                    if bench.isEmpty {
                        Text(L("team.benchEmpty")).foregroundStyle(.secondary)
                    }
                    ForEach(bench) { player in
                        PlayerRow(player: player, isStarter: false) {
                            playerToRelease = player
                        }
                    }
                } header: {
                    Text(LF("team.bench", Fmt.integer(store.state.players.count), Fmt.integer(store.config.scouting.maxRoster)))
                }
            }
            .navigationTitle(L("tab.team"))
            .safeAreaInset(edge: .top, spacing: 0) { CurrencyBar() }
            .confirmationDialog(
                L("team.releaseTitle"),
                isPresented: Binding(get: { playerToRelease != nil }, set: { if !$0 { playerToRelease = nil } }),
                titleVisibility: .visible,
                presenting: playerToRelease
            ) { player in
                Button(LF("team.releaseConfirm", Fmt.integer(store.config.rarity(player.rarity).releaseCards)), role: .destructive) {
                    store.release(player.id)
                }
            } message: { player in
                Text(player.fullName)
            }
        }
    }

    /// Gewinnchancen werden immer angezeigt (Apple App Review Guideline 3.1.1).
    private var oddsText: String {
        let total = store.config.scouting.rarities.reduce(0) { $0 + $1.weight }
        let parts = store.config.scouting.rarities.map { entry in
            "\(L("rarity.\(entry.rarity.rawValue)")) \(Fmt.percent(entry.weight / total))"
        }
        return LF("team.odds", parts.joined(separator: " · "))
    }
}

struct PlayerRow: View {
    @EnvironmentObject var store: GameStore
    let player: Player
    let isStarter: Bool
    let onRelease: (() -> Void)?

    var body: some View {
        let cost = store.engine.trainingCost(player)
        let maxed = player.level >= store.config.training.maxLevel
        HStack(spacing: 12) {
            GameImage(name: "player_\(player.position.rawValue)", fallbackSymbol: positionSymbol, size: 40, tint: player.rarity.color)
            VStack(alignment: .leading, spacing: 3) {
                HStack(spacing: 6) {
                    Text(player.fullName).font(.headline)
                    RarityBadge(rarity: player.rarity)
                }
                Text("\(L("position.\(player.position.rawValue)")) · \(LF("team.level", Fmt.integer(player.level)))")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text(LF("team.stats", Fmt.integer(player.attack), Fmt.integer(player.defense), Fmt.integer(player.speed)))
                    .font(.caption2.monospacedDigit())
                    .foregroundStyle(.secondary)
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 4) {
                Text(Fmt.number(store.engine.rating(player)))
                    .font(.title3.monospacedDigit().bold())
                Menu {
                    Button {
                        store.train(player.id)
                    } label: {
                        Label(maxed ? L("team.maxLevel") : LF("team.train", Fmt.integer(cost)), systemImage: "arrow.up.circle")
                    }
                    .disabled(maxed || store.state.trainingCards < cost)
                    if !isStarter {
                        Button {
                            store.makeStarter(player.id)
                        } label: {
                            Label(L("team.makeStarter"), systemImage: "person.fill.checkmark")
                        }
                        if let onRelease {
                            Button(role: .destructive, action: onRelease) {
                                Label(L("team.release"), systemImage: "person.fill.xmark")
                            }
                        }
                    }
                } label: {
                    Image(systemName: "ellipsis.circle").font(.title3)
                }
            }
        }
        .padding(.vertical, 2)
    }

    private var positionSymbol: String {
        switch player.position {
        case .goalie: return "shield.lefthalf.filled"
        case .defense: return "figure.hockey"
        case .forward: return "figure.hockey"
        }
    }
}
