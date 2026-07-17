import Foundation
import Observation
import StoreKit

#if DEBUG
enum DebugEntitlementOverride: String, Identifiable {
    case live
    case free
    case premium

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .live:    return "未覆盖"
        case .free:    return "免费版"
        case .premium: return "会员"
        }
    }

    var forcedTier: EntitlementTier? {
        switch self {
        case .live:    return nil
        case .free:    return .free
        case .premium: return .premium
        }
    }
}
#endif

@MainActor
@Observable
final class PurchaseService {
    static let premiumProductID = "ailesson.path.Object1.premium.monthly"

    var tier: EntitlementTier = .free
    var products: [Product] = []
    var isLoadingProducts = false
    var errorMessage: String? = nil

    #if DEBUG
    var debugEntitlementOverride: DebugEntitlementOverride = .live {
        didSet { applyEffectiveTier() }
    }
    #endif

    private var storeKitTier: EntitlementTier = .free
    private var didStart = false
    private var transactionUpdatesTask: Task<Void, Never>?

    var premiumProduct: Product? {
        products.first { $0.id == Self.premiumProductID }
    }

    var isPremium: Bool { tier == .premium }

    func start() {
        guard !didStart else { return }
        didStart = true

        transactionUpdatesTask = Task {
            for await result in Transaction.updates {
                guard let transaction = try? checkVerified(result) else { continue }
                await refreshEntitlements()
                await transaction.finish()
            }
        }

        Task {
            await loadProducts()
            await refreshEntitlements()
        }
    }

    func loadProducts() async {
        guard !isLoadingProducts else { return }
        isLoadingProducts = true
        errorMessage = nil
        defer { isLoadingProducts = false }

        do {
            products = try await Product.products(for: [Self.premiumProductID])
                .sorted { $0.displayName < $1.displayName }
        } catch {
            errorMessage = "会员商品加载失败：\(error.localizedDescription)"
        }
    }

    @discardableResult
    func purchasePremium() async -> Bool {
        if premiumProduct == nil {
            await loadProducts()
        }

        guard let product = premiumProduct else {
            errorMessage = "会员商品暂不可用，请稍后再试"
            return false
        }

        do {
            let result = try await product.purchase()
            switch result {
            case .success(let verification):
                let transaction = try checkVerified(verification)
                await refreshEntitlements()
                await transaction.finish()
                return storeKitTier == .premium
            case .userCancelled, .pending:
                return false
            @unknown default:
                return false
            }
        } catch {
            errorMessage = "购买失败：\(error.localizedDescription)"
            return false
        }
    }

    func restorePurchases() async {
        do {
            try await AppStore.sync()
            await refreshEntitlements()
        } catch {
            errorMessage = "恢复购买失败：\(error.localizedDescription)"
        }
    }

    func refreshEntitlements() async {
        var hasPremium = false

        for await result in Transaction.currentEntitlements {
            guard let transaction = try? checkVerified(result) else { continue }
            guard transaction.productID == Self.premiumProductID else { continue }
            guard transaction.revocationDate == nil else { continue }
            hasPremium = true
        }

        storeKitTier = hasPremium ? .premium : .free
        applyEffectiveTier()
    }

    private func applyEffectiveTier() {
        #if DEBUG
        if let forcedTier = debugEntitlementOverride.forcedTier {
            tier = forcedTier
            return
        }
        #endif

        tier = storeKitTier
    }

    private func checkVerified<T>(_ result: VerificationResult<T>) throws -> T {
        switch result {
        case .unverified:
            throw StoreError.failedVerification
        case .verified(let signedType):
            return signedType
        }
    }

    private enum StoreError: Error {
        case failedVerification
    }
}
