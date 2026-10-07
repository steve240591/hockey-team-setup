import SwiftUI

/// Ergebnisfenster: Offline-Einnahmen, Saisonende, neuer Spieler, Penalty-Ergebnisse.
struct ResultSheet: View {
    @EnvironmentObject var store: GameStore
    @Environment(\.dismiss) private var dismiss
    let sheet: ActiveSheet

    var body: some View {
        VStack(spacing: 18) {
            content
            Button(L("common.ok")) { dismiss() }
                .buttonStyle(.bordered)
        }
        .padding(28)
        .multilineTextAlignment(.center)
    }

    @ViewBuilder
    private var content: some View {
        switch sheet {
        case .offline(let report):
            Image(systemName: "moon.stars.fill").font(.system(size: 48)).foregroundStyle(.indigo)
            Text(L("offline.title")).font(.title2.bold())
            Text(LF("offline.info", Fmt.duration(report.seconds))).foregroundStyle(.secondary)
            Text("+ " + Fmt.number(report.coins)).font(.largeTitle.monospacedDigit().bold())
            if report.matchesPlayed > 0 {
                Text(LF("offline.matches", Fmt.integer(report.matchesPlayed), Fmt.integer(report.wins)))
                    .font(.subheadline)
            }
            if report.coins > 0 {
                Button {
                    store.doubleOffline(report)
                    dismiss()
                } label: {
                    Label(L("offline.double"), systemImage: store.state.adFree ? "gift.fill" : "play.rectangle.fill")
                }
                .buttonStyle(.borderedProminent)
            }

        case .season(let summary):
            Image(systemName: summary.promoted ? "trophy.fill" : "flag.checkered")
                .font(.system(size: 48))
                .foregroundStyle(summary.promoted ? Color.yellow : Color.accentColor)
            Text(L("season.title")).font(.title2.bold())
            Text(LF("season.rank", store.leagueName(summary.tier), Fmt.integer(summary.rank)))
            if summary.promoted {
                Text(LF("season.promoted", store.leagueName(summary.tier + 1)))
                    .font(.headline)
                    .foregroundStyle(.green)
            } else if summary.tier >= store.config.maxLeagueTier {
                Text(L("season.topLeague")).font(.subheadline)
            } else {
                Text(L("season.stay")).font(.subheadline)
            }
            Text(LF("season.rewards", Fmt.number(summary.rewardCoins), Fmt.integer(summary.rewardPucks)))
                .font(.headline)

        case .scouted(let player):
            GameImage(name: "player_\(player.position.rawValue)", fallbackSymbol: "figure.hockey", size: 80, tint: player.rarity.color)
            Text(L("scout.title")).font(.title2.bold())
            Text(player.fullName).font(.title3.bold())
            RarityBadge(rarity: player.rarity)
            Text(L("position.\(player.position.rawValue)"))
            Text(LF("team.stats", Fmt.integer(player.attack), Fmt.integer(player.defense), Fmt.integer(player.speed)))
                .font(.subheadline.monospacedDigit())
            Button(L("team.makeStarter")) {
                store.makeStarter(player.id)
                dismiss()
            }
            .buttonStyle(.borderedProminent)

        case .shootout(let outcome):
            Image(systemName: outcome.won ? "hand.thumbsup.fill" : "hand.thumbsdown.fill")
                .font(.system(size: 48))
                .foregroundStyle(outcome.won ? Color.green : Color.red)
            Text(outcome.won ? L("shootout.won") : L("shootout.lost")).font(.title2.bold())
            Text(LF("shootout.score", Fmt.integer(outcome.playerGoals), Fmt.integer(outcome.opponentGoals)))
                .font(.title3.monospacedDigit())
            if outcome.playerGoals == outcome.opponentGoals {
                Text(L("shootout.suddenDeath")).font(.caption).foregroundStyle(.secondary)
            }

        case .practice(let reward):
            Image(systemName: "target").font(.system(size: 48)).foregroundStyle(Color.accentColor)
            Text(L("practice.title")).font(.title2.bold())
            Text(LF("practice.goals", Fmt.integer(reward.goals), Fmt.integer(store.config.match.shootoutShots)))
                .font(.title3)
            Text(LF("practice.rewards", Fmt.number(reward.coins), Fmt.integer(reward.cards)))
            if let player = reward.bonusPlayer {
                Text(LF("practice.bonusPlayer", player.fullName))
                    .font(.headline)
                    .foregroundStyle(player.rarity.color)
            }
        }
    }
}
