import Foundation
import StoreKit

/// In-App-Käufe mit StoreKit 2.
/// Die Produkt-IDs stehen in GameConfig.json und müssen in App Store Connect
/// (oder in einer StoreKit-Konfigurationsdatei zum Testen) genauso angelegt sein.
@MainActor
final class PurchaseManager: ObservableObject {
    @Published private(set) var products: [Product] = []
    @Published private(set) var isLoading = false
    @Published private(set) var isPurchasing = false
    @Published var lastError: String?

    /// Wird für jeden bestätigten Kauf aufgerufen (auch bei Wiederherstellung).
    var onPurchased: ((String) -> Void)?

    private let productIDs: [String]
    private var updatesTask: Task<Void, Never>?

    init(productIDs: [String]) {
        self.productIDs = productIDs
        updatesTask = Task { [weak self] in
            for await update in Transaction.updates {
                await self?.handle(update)
            }
        }
        Task { await loadProducts() }
    }

    func loadProducts() async {
        isLoading = true
        defer { isLoading = false }
        do {
            let loaded = try await Product.products(for: productIDs)
            products = loaded.sorted { $0.price < $1.price }
        } catch {
            lastError = error.localizedDescription
        }
    }

    func product(_ id: String) -> Product? {
        products.first { $0.id == id }
    }

    func buy(_ product: Product) async {
        isPurchasing = true
        defer { isPurchasing = false }
        do {
            let result = try await product.purchase()
            switch result {
            case .success(let verification):
                await handle(verification)
            case .userCancelled, .pending:
                break
            @unknown default:
                break
            }
        } catch {
            lastError = error.localizedDescription
        }
    }

    /// Stellt Einmalkäufe (Werbefrei, Starterpaket) wieder her.
    func restore() async {
        do {
            try await AppStore.sync()
        } catch {
            lastError = error.localizedDescription
        }
        for await entitlement in Transaction.currentEntitlements {
            if case .verified(let transaction) = entitlement {
                onPurchased?(transaction.productID)
            }
        }
    }

    private func handle(_ verification: VerificationResult<Transaction>) async {
        guard case .verified(let transaction) = verification else { return }
        onPurchased?(transaction.productID)
        await transaction.finish()
    }
}
