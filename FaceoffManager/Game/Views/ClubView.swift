import SwiftUI

struct ClubView: View {
    @EnvironmentObject var store: GameStore

    var body: some View {
        NavigationStack {
            List {
                Section {
                    if store.boostSecondsLeft > 0 {
                        Label(LF("boost.active", Fmt.countdown(store.boostSecondsLeft)), systemImage: "bolt.fill")
                            .foregroundStyle(.orange)
                    }
                    AdButton(title: LF("boost.watch", Fmt.integer(Int(store.config.rewarded.boostHours))), kind: .boost) {
                        store.watchBoostAd()
                    }
                }

                Section {
                    ForEach(store.config.facilities) { facility in
                        FacilityRow(facility: facility)
                    }
                } header: {
                    Text(L("club.facilities"))
                } footer: {
                    Text(L("club.managerInfo"))
                }
            }
            .navigationTitle(store.clubDisplayName)
            .safeAreaInset(edge: .top, spacing: 0) { CurrencyBar() }
        }
    }
}

struct FacilityRow: View {
    @EnvironmentObject var store: GameStore
    let facility: FacilityConfig

    private var level: Int { store.state.level(facility.id) }
    private var unlocked: Bool { store.engine.isUnlocked(facility, in: store.state) }
    private var cost: Double { store.engine.upgradeCost(facility, level: level) }
    private var hasManager: Bool { store.state.managers.contains(facility.id) }

    private var income: Double {
        store.engine.baseIncome(facility, level: level) *
            store.engine.incomeMultiplier(store.state, now: store.now, includeBoost: true)
    }

    var body: some View {
        if unlocked {
            unlockedBody
        } else {
            HStack(spacing: 12) {
                GameImage(name: "facility_\(facility.id)", fallbackSymbol: "lock.fill", size: 40, tint: .gray)
                VStack(alignment: .leading) {
                    Text(L("facility.\(facility.id)")).font(.headline)
                    Text(LF("club.unlocksIn", store.leagueName(facility.unlockTier)))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .opacity(0.6)
        }
    }

    private var unlockedBody: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 12) {
                GameImage(name: "facility_\(facility.id)", fallbackSymbol: facility.symbol, size: 40)
                VStack(alignment: .leading, spacing: 2) {
                    HStack {
                        Text(L("facility.\(facility.id)")).font(.headline)
                        Text(LF("club.level", Fmt.integer(level)))
                            .font(.caption.bold())
                            .foregroundStyle(.secondary)
                    }
                    Text(effectText)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    if let milestone = store.engine.nextMilestone(after: level) {
                        ProgressView(value: Double(level), total: Double(milestone)) {
                            Text(LF("club.nextMilestone", Fmt.integer(milestone)))
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
                Spacer()
                Button {
                    store.upgrade(facility.id)
                } label: {
                    VStack(spacing: 0) {
                        Image(systemName: "arrow.up")
                        Text(Fmt.number(cost)).font(.caption.monospacedDigit().bold())
                    }
                    .frame(minWidth: 60)
                }
                .buttonStyle(.borderedProminent)
                .disabled(store.state.coins < cost)
            }
            managerRow
        }
        .padding(.vertical, 4)
    }

    private var effectText: String {
        var parts: [String] = []
        if income > 0 {
            parts.append(LF("common.perSecond", Fmt.number(income)))
        }
        switch facility.kind {
        case .income:
            break
        case .strength:
            parts.append(LF("club.effectStrength", Fmt.percent(facility.effectPerLevel * Double(level))))
        case .multiplier:
            parts.append(LF("club.effectMultiplier", Fmt.percent(facility.effectPerLevel * Double(level))))
        case .cards:
            parts.append(LF("club.effectCards", Fmt.number(facility.effectPerLevel * Double(level))))
        }
        return parts.joined(separator: " · ")
    }

    @ViewBuilder
    private var managerRow: some View {
        if hasManager {
            Label(L("club.managerActive"), systemImage: "person.badge.clock.fill")
                .font(.caption)
                .foregroundStyle(.green)
        } else if level >= facility.managerLevel {
            Button {
                store.hireManager(facility.id)
            } label: {
                Label(LF("club.hireManager", Fmt.number(facility.managerCost)), systemImage: "person.badge.plus")
                    .font(.caption.bold())
            }
            .buttonStyle(.bordered)
            .disabled(!store.engine.canHireManager(store.state, id: facility.id))
        } else {
            Text(LF("club.managerFrom", Fmt.integer(facility.managerLevel)))
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }
}
