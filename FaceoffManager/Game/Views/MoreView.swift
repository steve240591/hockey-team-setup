import SwiftUI

struct MoreView: View {
    @EnvironmentObject var store: GameStore
    @State private var clubName = ""
    @State private var confirmPrestige = false
    @State private var confirmReset = false

    var body: some View {
        NavigationStack {
            List {
                loginSection
                questSection
                prestigeSection

                Section(L("more.settings")) {
                    TextField(L("more.clubName"), text: $clubName)
                        .onSubmit { store.renameClub(clubName) }
                        .submitLabel(.done)
                    #if DEBUG
                    Button(L("more.reset"), role: .destructive) { confirmReset = true }
                    #endif
                }

                Section {
                    Text(L("more.disclaimer"))
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
            }
            .navigationTitle(L("tab.more"))
            .safeAreaInset(edge: .top, spacing: 0) { CurrencyBar() }
            .onAppear { clubName = store.state.clubName }
            .confirmationDialog(L("prestige.confirmTitle"), isPresented: $confirmPrestige, titleVisibility: .visible) {
                Button(LF("prestige.confirmButton", Fmt.integer(store.engine.prestigePointsAvailable(store.state))), role: .destructive) {
                    store.prestige()
                }
            } message: {
                Text(L("prestige.confirmInfo"))
            }
            #if DEBUG
            .confirmationDialog(L("more.resetTitle"), isPresented: $confirmReset, titleVisibility: .visible) {
                Button(L("more.reset"), role: .destructive) {
                    store.resetGame()
                    clubName = ""
                }
            }
            #endif
        }
    }

    private var loginSection: some View {
        Section {
            let rewards = store.config.loginRewardPucks
            let current = store.engine.loginCalendarIndex(store.state)
            let canClaim = store.engine.canClaimLogin(store.state)
            HStack(spacing: 6) {
                ForEach(rewards.indices, id: \.self) { day in
                    let done = day < current || (day == current && !canClaim)
                    VStack(spacing: 4) {
                        Text(LF("more.day", Fmt.integer(day + 1))).font(.caption2)
                        Image(systemName: done ? "checkmark.circle.fill" : "circle.circle.fill")
                            .foregroundStyle(done ? Color.green : (day == current ? Color.accentColor : Color.secondary))
                        Text(Fmt.integer(rewards[day])).font(.caption2.bold())
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 6)
                    .background(day == current && canClaim ? Color.accentColor.opacity(0.15) : Color.clear,
                                in: RoundedRectangle(cornerRadius: 8))
                }
            }
            Button(canClaim ? L("more.claimLogin") : L("more.claimedLogin")) {
                store.claimLogin()
            }
            .disabled(!canClaim)
        } header: {
            Text(L("more.loginTitle"))
        } footer: {
            Text(L("more.loginInfo"))
        }
    }

    private var questSection: some View {
        Section(L("more.questsTitle")) {
            ForEach(store.state.daily.quests) { quest in
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(LF("quest.\(quest.kind.rawValue)", Fmt.integer(quest.target)))
                            .font(.subheadline)
                        ProgressView(value: Double(quest.progress), total: Double(quest.target))
                    }
                    Spacer(minLength: 16)
                    if quest.claimed {
                        Image(systemName: "checkmark.circle.fill").foregroundStyle(.green)
                    } else {
                        Button(LF("reward.pucks", Fmt.integer(quest.rewardPucks))) {
                            store.claimQuest(quest.id)
                        }
                        .buttonStyle(.borderedProminent)
                        .disabled(!quest.isComplete)
                    }
                }
            }
        }
    }

    private var prestigeSection: some View {
        Section {
            HStack {
                Text(L("prestige.points"))
                Spacer()
                Text(Fmt.integer(store.state.legendPoints)).bold()
            }
            HStack {
                Text(L("prestige.multiplier"))
                Spacer()
                Text("×" + Fmt.number(store.engine.prestigeMultiplier(store.state))).bold()
            }
            if store.engine.canPrestige(store.state) {
                Button(LF("prestige.sell", Fmt.integer(store.engine.prestigePointsAvailable(store.state)))) {
                    confirmPrestige = true
                }
                .buttonStyle(.borderedProminent)
            } else {
                Text(LF("prestige.locked", store.leagueName(store.config.prestige.minTier)))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        } header: {
            Text(L("prestige.title"))
        } footer: {
            Text(L("prestige.info"))
        }
    }
}
