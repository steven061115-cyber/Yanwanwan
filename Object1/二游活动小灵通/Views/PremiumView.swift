import SwiftUI
import StoreKit

struct PremiumView: View {
    @Environment(PurchaseService.self) private var purchaseService
    @Environment(\.dismiss) private var dismiss
    @State private var isPurchasing = false
    @State private var isRestoring = false

    var body: some View {
        NavigationStack {
            ZStack {
                Color.hoyoBg.ignoresSafeArea()

                ScrollView {
                    VStack(alignment: .leading, spacing: 18) {
                        header
                        planComparison
                        purchaseSection
                    }
                    .padding(18)
                    .padding(.bottom, 28)
                }
            }
            .navigationTitle("会员")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("关闭") { dismiss() }
                }
            }
        }
        .task {
            await purchaseService.loadProducts()
            await purchaseService.refreshEntitlements()
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("解锁更多自定义游戏")
                .font(.system(size: 26, weight: .black, design: .rounded))
                .foregroundStyle(Color.hoyoNavy)
            Text("会员可添加 10 个自定义游戏，每日提取 5 次。")
                .font(.subheadline)
                .foregroundStyle(Color.hoyoNavy.opacity(0.58))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(18)
        .background(Color.hoyoCardBg, in: RoundedRectangle(cornerRadius: 18))
        .overlay(RoundedRectangle(cornerRadius: 18).stroke(Color.hoyoNavy.opacity(0.12), lineWidth: 1.5))
    }

    private var planComparison: some View {
        VStack(spacing: 10) {
            planRow(title: "免费版", customGames: 1, dailyQueries: 2, tint: Color.hoyoNavy.opacity(0.45))
            planRow(title: "会员", customGames: 10, dailyQueries: 5, tint: Color.hoyoPink)
        }
    }

    private func planRow(title: String, customGames: Int, dailyQueries: Int, tint: Color) -> some View {
        HStack(spacing: 12) {
            Image(systemName: title == "会员" ? "crown.fill" : "person.fill")
                .font(.system(size: 15, weight: .black))
                .foregroundStyle(.white)
                .frame(width: 34, height: 34)
                .background(tint, in: RoundedRectangle(cornerRadius: 9))

            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.system(size: 16, weight: .black, design: .rounded))
                    .foregroundStyle(Color.hoyoNavy)
                Text("自定义游戏 \(customGames) 个 · 每日提取 \(dailyQueries) 次")
                    .font(.caption)
                    .foregroundStyle(Color.hoyoNavy.opacity(0.48))
            }
            Spacer()
        }
        .padding(14)
        .background(Color.hoyoCardBg, in: RoundedRectangle(cornerRadius: 16))
        .overlay(RoundedRectangle(cornerRadius: 16).stroke(tint.opacity(0.24), lineWidth: 1.3))
    }

    private var purchaseSection: some View {
        VStack(spacing: 12) {
            if purchaseService.isPremium {
                Label("当前已是会员", systemImage: "checkmark.seal.fill")
                    .font(.system(size: 15, weight: .bold, design: .rounded))
                    .foregroundStyle(Color.hoyoMint)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(Color.hoyoMint.opacity(0.12), in: RoundedRectangle(cornerRadius: 14))
            } else if let product = purchaseService.premiumProduct {
                Button {
                    Task {
                        isPurchasing = true
                        let purchased = await purchaseService.purchasePremium()
                        isPurchasing = false
                        if purchased { dismiss() }
                    }
                } label: {
                    HStack {
                        Spacer()
                        if isPurchasing {
                            ProgressView().tint(.white)
                        } else {
                            Text("开通会员 \(product.displayPrice)")
                                .font(.system(size: 16, weight: .black, design: .rounded))
                        }
                        Spacer()
                    }
                    .foregroundStyle(.white)
                    .padding(.vertical, 15)
                    .background(Color.hoyoPink, in: RoundedRectangle(cornerRadius: 16))
                }
                .buttonStyle(.plain)
                .disabled(isPurchasing)
            } else {
                VStack(spacing: 8) {
                    Text("会员商品暂不可用")
                        .font(.system(size: 15, weight: .bold, design: .rounded))
                        .foregroundStyle(Color.hoyoNavy)
                    Text("请确认 App Store Connect 中已创建产品 ID：\(PurchaseService.premiumProductID)")
                        .font(.caption)
                        .foregroundStyle(Color.hoyoNavy.opacity(0.45))
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity)
                .padding(14)
                .background(Color.hoyoCardBg, in: RoundedRectangle(cornerRadius: 16))
            }

            Button {
                Task {
                    isRestoring = true
                    await purchaseService.restorePurchases()
                    isRestoring = false
                }
            } label: {
                if isRestoring {
                    ProgressView().scaleEffect(0.82)
                } else {
                    Text("恢复购买")
                        .font(.system(size: 14, weight: .bold, design: .rounded))
                }
            }
            .buttonStyle(.plain)
            .foregroundStyle(Color.hoyoPink)

            if let message = purchaseService.errorMessage {
                Text(message)
                    .font(.caption)
                    .foregroundStyle(.orange)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
    }
}
