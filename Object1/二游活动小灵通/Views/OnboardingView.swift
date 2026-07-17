import SwiftUI
import SwiftData

struct OnboardingView: View {
    @Binding var isPresented: Bool
    @Query private var prefsQuery: [UserPreferences]
    private var prefs: UserPreferences? { prefsQuery.first }

    @State private var step = 0

    var body: some View {
        NavigationStack {
            Group {
                switch step {
                case 0:  welcomeStep
                case 1:  gameSelectStep
                default: doneStep
                }
            }
            .animation(.easeInOut(duration: 0.3), value: step)
        }
    }

    // MARK: - Step 0: Welcome

    private var welcomeStep: some View {
        VStack(spacing: 32) {
            Spacer()

            VStack(spacing: 16) {
                Image(systemName: "calendar.badge.clock")
                    .font(.system(size: 72))
                    .foregroundStyle(.teal)
                    .symbolEffect(.pulse)

                Text("小的替您盯活动")
                    .font(.largeTitle)
                    .fontWeight(.bold)

                Text("限时奖励不能白白错过。小的替您盯着活动，到点及时禀报。")
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
            }

            VStack(alignment: .leading, spacing: 20) {
                featureRow(icon: "calendar.badge.exclamationmark", color: .orange,
                           title: "活动倒计时", desc: "谁快到点，小的一眼呈上")
                featureRow(icon: "bell.badge.fill", color: .red,
                           title: "智能通知", desc: "每日清点，临期再来禀报")
                featureRow(icon: "giftcard.fill", color: .pink,
                           title: "前瞻兑换码", desc: "有新码时，小的替您收好")
            }
            .padding(.horizontal, 32)

            Spacer()

            Button {
                withAnimation { step = 1 }
            } label: {
                Text("让小的开工")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(.teal)
                    .foregroundStyle(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 14))
            }
            .padding(.horizontal, 32)
            .padding(.bottom, 40)
        }
    }

    // MARK: - Step 1: Game Selection

    private var gameSelectStep: some View {
        VStack(spacing: 0) {
            VStack(spacing: 12) {
                Image(systemName: "gamecontroller.fill")
                    .font(.system(size: 48))
                    .foregroundStyle(.purple)
                    .padding(.top, 48)

                Text("请点几款要盯的游戏")
                    .font(.title2)
                    .fontWeight(.bold)

                Text("小的可同时盯多款游戏，之后也能在设置中调整。")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
            }
            .padding(.bottom, 32)

            VStack(spacing: 12) {
                ForEach(HoYoGame.allCases) { game in
                    gameToggleCard(game)
                }
            }
            .padding(.horizontal, 24)

            Spacer()

            Button {
                withAnimation { step = 2 }
            } label: {
                Text("下一步")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(hasAnyGame ? Color.hoyoPink : Color.secondary.opacity(0.4))
                    .foregroundStyle(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 14))
            }
            .disabled(!hasAnyGame)
            .padding(.horizontal, 32)
            .padding(.bottom, 40)
        }
    }

    // MARK: - Step 2: Done

    private var doneStep: some View {
        VStack(spacing: 32) {
            Spacer()

            VStack(spacing: 16) {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 72))
                    .foregroundStyle(.green)
                    .symbolEffect(.pulse)

                Text("小的准备好了")
                    .font(.largeTitle)
                    .fontWeight(.bold)

                Text("小的会在后台为您拉取最新活动数据。\n建议开启通知权限，临期时才好及时禀报。")
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
            }

            Button {
                finishOnboarding()
            } label: {
                Text("开始使用")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(.green)
                    .foregroundStyle(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 14))
            }
            .padding(.horizontal, 32)

            Spacer()
        }
    }

    // MARK: - Helpers

    private var hasAnyGame: Bool {
        prefs?.followedGames.isEmpty == false
    }

    private func finishOnboarding() {
        isPresented = false
    }

    @ViewBuilder
    private func featureRow(icon: String, color: Color, title: String, desc: String) -> some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(color)
                .frame(width: 36)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                Text(desc)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
        }
    }

    @ViewBuilder
    private func gameToggleCard(_ game: HoYoGame) -> some View {
        let following = prefs?.isFollowing(game) ?? false
        Button {
            prefs?.toggleGame(game)
        } label: {
            HStack(spacing: 16) {
                Text(game.emoji)
                    .font(.title)

                VStack(alignment: .leading, spacing: 2) {
                    Text(game.displayName)
                        .font(.headline)
                        .foregroundStyle(.primary)
                    Text(game.englishName)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                Image(systemName: following ? "checkmark.circle.fill" : "circle")
                    .font(.title2)
                    .foregroundStyle(following ? game.accentColor : Color.secondary.opacity(0.4))
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .fill(following ? game.accentColor.opacity(0.1) : Color(.systemGray6))
                    .overlay(
                        RoundedRectangle(cornerRadius: 14)
                            .stroke(following ? game.accentColor : Color.clear, lineWidth: 1.5)
                    )
            )
        }
        .buttonStyle(.plain)
        .animation(.spring(duration: 0.25), value: following)
    }

}
