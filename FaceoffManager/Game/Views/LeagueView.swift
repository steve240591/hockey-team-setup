import SwiftUI

struct LeagueView: View {
    @EnvironmentObject var store: GameStore

    private var season: Season { store.state.season }

    var body: some View {
        NavigationStack {
            List {
                Section {
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(store.leagueName(season.tier)).font(.title3.bold())
                            Text(LF("league.round", Fmt.integer(min(season.round + 1, store.config.seasonLength)), Fmt.integer(store.config.seasonLength)))
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        Spacer()
                        VStack(alignment: .trailing, spacing: 2) {
                            Text(L("league.nextMatch")).font(.caption).foregroundStyle(.secondary)
                            Text(Fmt.countdown(store.secondsToNextMatch)).font(.title3.monospacedDigit().bold())
                        }
                    }
                }

                if let pending = store.state.pendingShootout {
                    Section {
                        VStack(alignment: .leading, spacing: 10) {
                            Label(L("league.shootoutTitle"), systemImage: "sportscourt.fill")
                                .font(.headline)
                                .foregroundStyle(.orange)
                            Text(LF("league.shootoutInfo",
                                    store.teamName(pending.fixture.home),
                                    store.teamName(pending.fixture.away),
                                    Fmt.integer(pending.regulationGoals)))
                                .font(.subheadline)
                            HStack {
                                Button(L("league.shootoutPlay")) { store.playPendingShootout() }
                                    .buttonStyle(.borderedProminent)
                                Button(L("league.shootoutSkip")) { store.skipPendingShootout() }
                                    .buttonStyle(.bordered)
                            }
                        }
                        .padding(.vertical, 4)
                    }
                }

                Section {
                    let left = store.engine.practiceAttemptsLeft(store.state)
                    if left > 0 {
                        Button {
                            store.startPractice()
                        } label: {
                            HStack {
                                Label(L("league.practice"), systemImage: "target")
                                Spacer()
                                Text(LF("league.practiceLeft", Fmt.integer(left)))
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    } else {
                        AdButton(title: L("league.practiceAd"), kind: .practiceExtra) {
                            store.startPractice()
                        }
                    }
                    if store.state.replayableResultId != nil {
                        AdButton(title: L("league.replay"), kind: .replay) {
                            store.replayLastLoss()
                        }
                    }
                } footer: {
                    Text(L("league.practiceInfo"))
                }

                Section {
                    StandingsTable()
                } header: {
                    Text(L("league.table"))
                } footer: {
                    Text(season.tier < store.config.maxLeagueTier
                         ? LF("league.promotionInfo", Fmt.integer(store.config.promotionSlots))
                         : L("league.topLeagueInfo"))
                }

                Section(L("league.results")) {
                    let ownResults = season.results.filter {
                        $0.home == GameEngine.playerTeamId || $0.away == GameEngine.playerTeamId
                    }
                    if ownResults.isEmpty {
                        Text(L("league.noResults")).foregroundStyle(.secondary)
                    }
                    ForEach(ownResults) { result in
                        ResultRow(result: result)
                    }
                }
            }
            .navigationTitle(L("tab.league"))
            .safeAreaInset(edge: .top, spacing: 0) { CurrencyBar() }
        }
    }
}

struct StandingsTable: View {
    @EnvironmentObject var store: GameStore

    var body: some View {
        let rows = store.engine.sortedStandings(store.state.season)
        Grid(alignment: .leading, horizontalSpacing: 10, verticalSpacing: 8) {
            GridRow {
                Text("#")
                Text(L("league.team"))
                Text(L("league.played")).gridColumnAlignment(.trailing)
                Text(L("league.goals")).gridColumnAlignment(.trailing)
                Text(L("league.points")).gridColumnAlignment(.trailing)
            }
            .font(.caption.bold())
            .foregroundStyle(.secondary)
            ForEach(Array(rows.enumerated()), id: \.element.teamId) { index, row in
                let isPlayer = row.teamId == GameEngine.playerTeamId
                GridRow {
                    Text("\(index + 1)")
                        .foregroundStyle(index < store.config.promotionSlots ? Color.green : Color.secondary)
                    Text(store.teamName(row.teamId)).lineLimit(1)
                    Text("\(row.played)")
                    Text("\(row.goalsFor):\(row.goalsAgainst)")
                    Text("\(row.points)").bold()
                }
                .font(.subheadline.monospacedDigit())
                .fontWeight(isPlayer ? .bold : .regular)
            }
        }
        .padding(.vertical, 4)
    }
}

struct ResultRow: View {
    @EnvironmentObject var store: GameStore
    let result: MatchResult

    var body: some View {
        let won = store.engine.didPlayerWin(result)
        HStack {
            Image(systemName: won ? "checkmark.circle.fill" : "xmark.circle.fill")
                .foregroundStyle(won ? Color.green : Color.red)
            Text(store.teamName(result.home)).lineLimit(1)
            Spacer()
            Text("\(result.homeGoals):\(result.awayGoals)\(result.shootout ? " " + L("league.shootoutShort") : "")")
                .font(.subheadline.monospacedDigit().bold())
            Spacer()
            Text(store.teamName(result.away)).lineLimit(1)
        }
        .font(.subheadline)
    }
}
