import SwiftUI

struct ExchangeCodeRow: View {
    let code:   ExchangeCode
    let isSeen: Bool
    let onCopy: () -> Void

    @State private var copied = false

    var body: some View {
        HStack(spacing: 14) {
            // New / seen indicator dot
            Circle()
                .fill(isSeen ? Color.hoyoNavy.opacity(0.18) : Color.hoyoPink)
                .frame(width: 9, height: 9)
                .padding(.leading, 4)

            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 8) {
                    Text(code.code)
                        .font(.system(size: 17, weight: .bold, design: .monospaced))
                        .foregroundStyle(Color.hoyoNavy)

                    if !code.isActive {
                        Text("已失效")
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundStyle(Color.hoyoNavy.opacity(0.40))
                            .padding(.horizontal, 7)
                            .padding(.vertical, 3)
                            .background(Color.hoyoNavy.opacity(0.08), in: Capsule())
                    }
                }

                Text(code.rewardsText)
                    .font(.system(size: 12))
                    .foregroundStyle(Color.hoyoNavy.opacity(0.38))
                    .lineLimit(1)
            }

            Spacer()

            // Copy button
            Button {
                onCopy()
                withAnimation { copied = true }
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                    withAnimation { copied = false }
                }
            } label: {
                HStack(spacing: 4) {
                    Image(systemName: copied ? "checkmark" : "doc.on.doc")
                        .font(.system(size: 11, weight: .semibold))
                    Text(copied ? "已复制" : "复制")
                        .font(.system(size: 12, weight: .semibold))
                }
                .foregroundStyle(copied ? Color.hoyoMint : Color.hoyoNavy.opacity(0.65))
                .padding(.horizontal, 12)
                .padding(.vertical, 7)
                .background(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(copied ? Color.hoyoMint.opacity(0.50) : Color.hoyoNavy.opacity(0.18), lineWidth: 1.5)
                )
            }
            .buttonStyle(.plain)

            // Redeem button
            if let url = code.redemptionURL {
                Link(destination: url) {
                    Text("兑换")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 13)
                        .padding(.vertical, 7)
                        .background(
                            LinearGradient(colors: [Color.hoyoPink, Color(hex: "FF4DA6")],
                                           startPoint: .leading, endPoint: .trailing),
                            in: RoundedRectangle(cornerRadius: 10)
                        )
                        .shadow(color: Color.hoyoPink.opacity(0.30), radius: 4, x: 0, y: 2)
                }
            }
        }
        .opacity(code.isActive ? 1 : 0.45)
        .padding(.vertical, 14)
        .padding(.horizontal, 16)
    }
}
