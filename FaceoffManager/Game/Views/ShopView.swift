import StoreKit
import SwiftUI

struct ShopView: View {
    @EnvironmentObject var store: GameStore
    @ObservedObject var purchases: PurchaseManager

    private var products: ProductConfig { store.config.products }

    var body: some View {
        NavigationStack {
            List {
                if store.engine.isStarterPackAvailable(store.state, now: store.now) {
                    Section {
                        productRow(
                            id: products.starterPack,
                            title: L("shop.starterTitle"),
                            detail: LF("shop.starterDetail", Fmt.integer(store.config.starter.pucks), Fmt.integer(Int(store.config.starter.boostHours))),
                            symbol: "gift.fill"
                        )
                        let left = store.state.firstLaunch.addingTimeInterval(store.config.starter.windowHours * 3600).timeIntervalSince(store.now)
                        Text(LF("shop.starterEnds", Fmt.duration(left)))
                            .font(.caption)
                            .foregroundStyle(.orange)
                    } header: {
                        Text(L("shop.offer"))
                    }
                }

                Section {
                    if store.state.adFree {
                        Label(L("shop.adFreeOwned"), systemImage: "checkmark.seal.fill")
                            .foregroundStyle(.green)
                    } else {
                        productRow(
                            id: products.adFree,
                            title: L("shop.adFreeTitle"),
                            detail: LF("shop.adFreeDetail", Fmt.percent(store.config.shop.adFreeIncomeBonus)),
                            symbol: "nosign"
                        )
                    }
                }

                Section(L("shop.pucks")) {
                    ForEach(products.pucks, id: \.id) { pack in
                        productRow(
                            id: pack.id,
                            title: LF("shop.pucksAmount", Fmt.integer(pack.pucks)),
                            detail: nil,
                            symbol: "circle.circle.fill"
                        )
                    }
                }

                Section(L("shop.spendPucks")) {
                    Button {
                        store.buyTimeSkip()
                    } label: {
                        shopLine(
                            title: LF("shop.timeSkip", Fmt.integer(Int(store.config.shop.timeSkipHours))),
                            detail: LF("shop.timeSkipDetail", Fmt.number(store.engine.timeSkipCoins(store.state, now: store.now))),
                            price: LF("shop.pucksPrice", Fmt.integer(store.config.shop.timeSkipPucks)),
                            symbol: "forward.fill"
                        )
                    }
                    .disabled(store.state.pucks < store.config.shop.timeSkipPucks)

                    if let upgrade = store.engine.nextOfflineUpgrade(store.state) {
                        Button {
                            store.buyOfflineUpgrade()
                        } label: {
                            shopLine(
                                title: LF("shop.offlineUpgrade", Fmt.integer(Int(upgrade.hours))),
                                detail: LF("shop.offlineCurrent", Fmt.duration(store.engine.offlineCapSeconds(store.state))),
                                price: LF("shop.pucksPrice", Fmt.integer(upgrade.pucks)),
                                symbol: "moon.zzz.fill"
                            )
                        }
                        .disabled(store.state.pucks < upgrade.pucks)
                    } else {
                        Label(LF("shop.offlineMax", Fmt.duration(store.engine.offlineCapSeconds(store.state))), systemImage: "moon.zzz.fill")
                    }
                }

                Section {
                    Button(L("shop.restore")) {
                        Task { await purchases.restore() }
                    }
                } footer: {
                    if purchases.products.isEmpty && !purchases.isLoading {
                        Text(L("shop.productsMissing"))
                    }
                }

                #if DEBUG
                Section {
                    ForEach(products.allIDs, id: \.self) { id in
                        Button(LF("shop.debugBuy", id)) { store.simulatePurchase(id) }
                    }
                } header: {
                    Text(L("shop.debugTitle"))
                } footer: {
                    Text(L("shop.debugInfo"))
                }
                #endif
            }
            .navigationTitle(L("tab.shop"))
            .safeAreaInset(edge: .top, spacing: 0) { CurrencyBar() }
            .disabled(purchases.isPurchasing)
        }
    }

    @ViewBuilder
    private func productRow(id: String, title: String, detail: String?, symbol: String) -> some View {
        let product = purchases.product(id)
        Button {
            if let product {
                Task { await purchases.buy(product) }
            }
        } label: {
            shopLine(title: title, detail: detail, price: product?.displayPrice ?? "–", symbol: symbol)
        }
        .disabled(product == nil)
    }

    private func shopLine(title: String, detail: String?, price: String, symbol: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: symbol)
                .font(.title2)
                .foregroundStyle(Color.accentColor)
                .frame(width: 36)
            VStack(alignment: .leading, spacing: 2) {
                Text(title).font(.headline).foregroundStyle(.primary)
                if let detail {
                    Text(detail).font(.caption).foregroundStyle(.secondary)
                }
            }
            Spacer()
            Text(price)
                .font(.subheadline.bold())
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(Color.accentColor.opacity(0.15), in: Capsule())
        }
    }
}
