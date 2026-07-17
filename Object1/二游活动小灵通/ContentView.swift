import SwiftUI
import SwiftData

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var prefsQuery: [UserPreferences]
    @AppStorage("onboardingDone") private var onboardingDone = false
    @State private var showOnboarding = false
    @State private var selectedTab = 0

    var body: some View {
        ZStack(alignment: .bottom) {
            Color.white.ignoresSafeArea()

            Group {
                if selectedTab == 0 {
                    GameGridView()
                } else if selectedTab == 1 {
                    GamesTabView()
                } else {
                    SettingsView()
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)

            FloatingTabBar(selectedTab: $selectedTab)
                .frame(maxWidth: .infinity)
                .background(
                    Color.white
                        .padding(.top, -40)
                        .ignoresSafeArea(edges: .bottom)
                )
        }
        .ignoresSafeArea(.keyboard)
        .fontDesign(.rounded)
        .fullScreenCover(isPresented: $showOnboarding, onDismiss: {
            onboardingDone = true
        }) {
            OnboardingView(isPresented: $showOnboarding)
        }
        .task {
            if prefsQuery.isEmpty {
                modelContext.insert(UserPreferences(followedGameSlugs: []))
            }
            if !onboardingDone {
                showOnboarding = true
            }
        }
    }
}

// MARK: - Floating Tab Bar

struct FloatingTabBar: View {
    @Binding var selectedTab: Int

    var body: some View {
        HStack(spacing: 0) {
            tabButton(index: 0, icon: "waveform",           label: "首页")
            tabButton(index: 1, icon: "gamecontroller.fill", label: "游戏")
            tabButton(index: 2, icon: "gearshape.fill",     label: "设置")
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 40)
                .fill(Color.hoyoCardBg)
                .overlay(
                    RoundedRectangle(cornerRadius: 40)
                        .stroke(Color.hoyoNavy, lineWidth: 3)
                )
        )
        .shadow(color: Color.hoyoNavy.opacity(0.22), radius: 0, x: 3, y: 3)
        .padding(.horizontal, 28)
        .padding(.bottom, 16)
    }

    @ViewBuilder
    private func tabButton(index: Int, icon: String, label: String) -> some View {
        let isSelected = selectedTab == index
        Button {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                selectedTab = index
            }
        } label: {
            HStack(spacing: 7) {
                Image(systemName: icon)
                    .font(.system(size: 16, weight: .black))
                Text(label)
                    .font(.system(size: 15, weight: .black))
            }
            .foregroundStyle(isSelected ? .white : Color.hoyoNavy.opacity(0.50))
            .padding(.vertical, 14)
            .padding(.horizontal, isSelected ? 26 : 22)
            .frame(maxWidth: isSelected ? .infinity : nil)
            .background(
                Group {
                    if isSelected {
                        Capsule()
                            .fill(Color.hoyoPink)
                            .overlay(Capsule().stroke(Color.hoyoNavy, lineWidth: 2))
                    }
                }
            )
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    ContentView()
        .modelContainer(for: UserPreferences.self, inMemory: true)
        .environment(ActivityService())
        .environment(PurchaseService())
}
