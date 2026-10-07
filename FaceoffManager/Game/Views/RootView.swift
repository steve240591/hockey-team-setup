import SwiftUI

struct RootView: View {
    @EnvironmentObject var store: GameStore
    @Environment(\.scenePhase) private var scenePhase
    @State private var tab = 0

    private let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    var body: some View {
        TabView(selection: $tab) {
            ClubView()
                .tabItem { Label(L("tab.club"), systemImage: "building.2") }
                .tag(0)
            TeamView()
                .tabItem { Label(L("tab.team"), systemImage: "person.3") }
                .tag(1)
            LeagueView()
                .tabItem { Label(L("tab.league"), systemImage: "trophy") }
                .badge(store.state.pendingShootout == nil ? 0 : 1)
                .tag(2)
            ShopView(purchases: store.purchases)
                .tabItem { Label(L("tab.shop"), systemImage: "cart") }
                .tag(3)
            MoreView()
                .tabItem { Label(L("tab.more"), systemImage: "calendar") }
                .badge(store.engine.canClaimLogin(store.state) ? 1 : 0)
                .tag(4)
        }
        .onReceive(timer) { date in
            store.tick(now: date)
        }
        .onChange(of: scenePhase) { _, phase in
            switch phase {
            case .active:
                store.becameActive()
            case .inactive, .background:
                store.save()
            @unknown default:
                break
            }
        }
        .sheet(item: $store.sheet, onDismiss: { store.sheetDismissed() }) { sheet in
            ResultSheet(sheet: sheet)
                .presentationDetents([.medium, .large])
        }
        .fullScreenCover(item: $store.penaltySession) { session in
            PenaltyGameView(session: session) { goals in
                store.finishPenalty(session, goals: goals)
            }
        }
        .overlay {
            SimulatedAdOverlay(ads: store.ads)
        }
        .overlay(alignment: .top) {
            if let message = store.message {
                MessageBanner(text: message)
            }
        }
        .animation(.easeInOut, value: store.message)
    }
}

/// Testvideo, solange noch kein echtes Werbe-SDK eingebunden ist.
struct SimulatedAdOverlay: View {
    @ObservedObject var ads: SimulatedAdProvider
    private let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    var body: some View {
        if ads.isShowing {
            ZStack {
                Color.black.opacity(0.9).ignoresSafeArea()
                VStack(spacing: 20) {
                    Image(systemName: "play.rectangle.fill")
                        .font(.system(size: 60))
                    Text(L("ad.simulatedTitle")).font(.title2.bold())
                    Text(L("ad.simulatedInfo"))
                        .font(.footnote)
                        .multilineTextAlignment(.center)
                        .foregroundStyle(.secondary)
                    if ads.secondsLeft > 0 {
                        Text("\(ads.secondsLeft)")
                            .font(.largeTitle.monospacedDigit().bold())
                    } else {
                        Button(L("ad.collect")) { ads.finish(watched: true) }
                            .buttonStyle(.borderedProminent)
                    }
                    Button(L("ad.cancel")) { ads.finish(watched: false) }
                        .foregroundStyle(.secondary)
                }
                .foregroundStyle(.white)
                .padding(32)
            }
            .onReceive(timer) { _ in ads.countdown() }
        }
    }
}
