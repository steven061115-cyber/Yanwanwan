import SwiftUI

struct SplashView: View {
    let onDismiss: @MainActor @Sendable () -> Void
    var body: some View { SplashDoorView(onDismiss: onDismiss) }
}

// MARK: - 老板突然推门

private struct SplashDoorView: View { // still private — only SplashView uses it
    let onDismiss: @MainActor @Sendable () -> Void

    @State private var doorX:       CGFloat = -420
    @State private var eyesShowing  = false
    @State private var shakeX:      CGFloat = 0
    @State private var rootOpacity: Double  = 1
    @State private var floatY:      CGFloat = 0

    private let slackTexts = ["候着中…", "清点活动中", "翻公告中", "守着兑换码", "等您吩咐中"]

    var body: some View {
        ZStack {
            Color.hoyoBg.ignoresSafeArea()

            // 漂浮的摸鱼字
            VStack(spacing: 28) {
                ForEach(Array(slackTexts.enumerated()), id: \.offset) { i, text in
                    Text(text)
                        .font(.subheadline).fontWeight(.semibold)
                        .foregroundStyle(Color.hoyoPink.opacity(0.25))
                        .offset(x: [CGFloat(-70), 50, -30, 90, -55][i])
                }
            }
            .offset(y: floatY)

            // 门体
            ZStack {
                // 门板
                RoundedRectangle(cornerRadius: 10)
                    .fill(Color(hex: "8B5E3C"))
                    .frame(width: 130, height: 210)

                // 门框线条
                RoundedRectangle(cornerRadius: 8)
                    .stroke(Color(hex: "5C3A1E"), lineWidth: 5)
                    .frame(width: 118, height: 198)

                // 门板中线
                Rectangle()
                    .fill(Color(hex: "5C3A1E").opacity(0.5))
                    .frame(width: 3, height: 200)

                // 门把手
                Circle()
                    .fill(Color.hoyoYellow)
                    .frame(width: 14, height: 14)
                    .shadow(color: .yellow.opacity(0.5), radius: 4)
                    .offset(x: 44, y: 0)

                // 眼睛
                if eyesShowing {
                    HStack(spacing: 14) {
                        eyeView
                        eyeView
                    }
                    .offset(y: -55)
                    .transition(.scale.combined(with: .opacity))
                }
            }
            .offset(x: doorX + shakeX)

            // 皇上来了！提示（配合震动）
            if eyesShowing {
                Text("👀  主子驾到，小的候着！")
                    .font(.headline).fontWeight(.black)
                    .foregroundStyle(Color.hoyoPink)
                    .offset(y: 160)
                    .transition(.opacity.combined(with: .move(edge: .bottom)))
            }
        }
        .opacity(rootOpacity)
        .onAppear {
            // 摸鱼字漂浮
            withAnimation(.easeInOut(duration: 2.5).repeatForever(autoreverses: true)) {
                floatY = 18
            }

            // 门从左边冲进来
            after(0.4) {
                withAnimation(.spring(response: 0.45, dampingFraction: 0.58)) { doorX = 0 }
                UIImpactFeedbackGenerator(style: .heavy).impactOccurred()
            }

            // 眼睛出现
            after(1.0) {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) { eyesShowing = true }
            }

            // 屏幕震动
            after(1.25) {
                UINotificationFeedbackGenerator().notificationOccurred(.warning)
                shake()
            }

            // 退出
            after(2.5) {
                withAnimation(.easeOut(duration: 0.35)) { rootOpacity = 0 }
                after(0.35) { onDismiss() }
            }
        }
    }

    private var eyeView: some View {
        ZStack {
            Ellipse()
                .fill(.white)
                .frame(width: 26, height: 20)
                .shadow(color: .black.opacity(0.15), radius: 2)
            Circle()
                .fill(Color.black)
                .frame(width: 11, height: 11)
            // 高光
            Circle()
                .fill(.white)
                .frame(width: 4, height: 4)
                .offset(x: 3, y: -3)
        }
    }

    private func shake() {
        let steps: [(CGFloat, Double)] = [(10,0), (-10,0.06), (8,0.12), (-8,0.18), (4,0.24), (-4,0.30), (0,0.36)]
        for (offset, delay) in steps {
            after(delay) {
                withAnimation(.linear(duration: 0.05)) { shakeX = offset }
            }
        }
    }
}

// MARK: - Helper

@MainActor
private func after(_ seconds: Double, action: @escaping @MainActor @Sendable () -> Void) {
    let nanoseconds = UInt64(max(0, seconds) * 1_000_000_000)
    Task { @MainActor in
        try? await Task.sleep(nanoseconds: nanoseconds)
        action()
    }
}
