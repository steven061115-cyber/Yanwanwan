import SwiftUI
import SwiftData

// MARK: - Home: game card grid

struct GameGridView: View {
    @Environment(ActivityService.self) private var service
    @Environment(PurchaseService.self) private var purchaseService
    @Environment(\.modelContext) private var modelContext
    @Query private var prefsQuery: [UserPreferences]
    @Query private var customGames: [CustomGame]
    @State private var showAISearch      = false
    @State private var showPremium       = false
    @State private var showCompleteGuide = false
    @State private var cardsAppeared     = false
    @State private var addLimitMessage: String? = nil

    private var prefs: UserPreferences? { prefsQuery.first }
    private var followedGames: [HoYoGame] { prefs?.followedGames ?? [] }

    var body: some View {
        NavigationStack {
            Group {
                if service.isLoading && service.events.isEmpty {
                    skeletonGrid
                } else if followedGames.isEmpty && customGames.isEmpty {
                    emptyState
                } else {
                    cardGrid
                }
            }
            .sheet(isPresented: $showAISearch) { AIGameSearchView() }
            .sheet(isPresented: $showPremium) { PremiumView() }
            .sheet(isPresented: $showCompleteGuide) { CompleteTaskGuideSheet() }
            .alert("自定义游戏已达上限", isPresented: Binding(
                get: { addLimitMessage != nil },
                set: { if !$0 { addLimitMessage = nil } }
            )) {
                if !purchaseService.isPremium {
                    Button("升级会员") {
                        addLimitMessage = nil
                        showPremium = true
                    }
                }
                Button("知道了", role: .cancel) {}
            } message: {
                Text(addLimitMessage ?? "")
            }
            .fontDesign(.rounded)
            .onAppear {
                cardsAppeared = false
                withAnimation { cardsAppeared = true }
            }
            .refreshable {
                if let p = prefs { await service.refresh(preferences: p) }
            }
            .task(id: prefs?.followedGameSlugs.joined()) {
                guard let p = prefs else { return }
                service.loadFromCache(preferences: p)
                await service.refresh(preferences: p)
            }
        }
    }

    // MARK: Empty State

    private var emptyState: some View {
        ZStack {
            Color.hoyoBg.ignoresSafeArea(edges: .top)
            VStack(spacing: 16) {
                customHeader
                Spacer()
                ContentUnavailableView {
                    Label("还未选择游戏", systemImage: "gamecontroller")
                } description: {
                    Text("您还没选要盯的游戏，小的暂时无事可办。")
                }
                Spacer()
            }
        }
    }

    // MARK: Skeleton

    private var skeletonGrid: some View {
        ZStack {
            Color.hoyoBg.ignoresSafeArea(edges: .top)
            ScrollView {
                VStack(spacing: 0) {
                    customHeader
                    LazyVStack(spacing: 20) {
                        ForEach(0..<2, id: \.self) { _ in
                            GameCardSkeleton()
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 12)
                }
            }
        }
    }

    // MARK: Card Grid

    private var cardGrid: some View {
        ZStack {
            Color.hoyoBg.ignoresSafeArea(edges: .top)

            // Polka-dot background
            Canvas { ctx, size in
                for row in stride(from: 0, through: size.height, by: 22) {
                    for col in stride(from: 0, through: size.width, by: 22) {
                        let r = CGRect(x: col - 1.5, y: row - 1.5, width: 3, height: 3)
                        ctx.fill(Path(ellipseIn: r), with: .color(Color.hoyoPink.opacity(0.12)))
                    }
                }
            }
            .ignoresSafeArea()
            .allowsHitTesting(false)

            ScrollView {
                VStack(spacing: 0) {
                    customHeader

                    LazyVStack(spacing: 20) {
                        if let msg = service.errorMessage {
                            Label(msg, systemImage: "wifi.exclamationmark")
                                .foregroundStyle(.orange)
                                .font(.footnote)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(.horizontal, 4)
                        }

                        overviewCard
                        recentlyEndedCard
                        gameListCard

                        Color.clear.frame(height: 110)
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 14)
                }
            }
        }
    }

    // MARK: Custom Header

    private var customHeader: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 5) {
                    Text("皇上请阅奏折")
                        .font(.system(size: 28, weight: .black))
                        .foregroundStyle(Color.hoyoNavy)
                    Rectangle()
                        .fill(Color.hoyoPink)
                        .frame(height: 4)
                        .cornerRadius(2)
                        .padding(.trailing, 36)
                }
                Spacer()
                HStack(spacing: 10) {
                    if service.isLoading && !service.events.isEmpty {
                        ProgressView().scaleEffect(0.75)
                    }
                    // ? button — thick square cartoon style
                    Button { showCompleteGuide = true } label: {
                        Image(systemName: "questionmark")
                            .font(.system(size: 15, weight: .black))
                            .foregroundStyle(Color.hoyoNavy)
                            .frame(width: 40, height: 40)
                            .background(Color.hoyoCardBg)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                            .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.hoyoNavy, lineWidth: 2.5))
                            .shadow(color: Color.hoyoNavy.opacity(0.20), radius: 0, x: 2, y: 2)
                    }
                    // + button — pink filled square
                    Button { openAddGame() } label: {
                        Image(systemName: "plus")
                            .font(.system(size: 17, weight: .black))
                            .foregroundStyle(.white)
                            .frame(width: 40, height: 40)
                            .background(Color.hoyoPink)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                            .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.hoyoNavy, lineWidth: 2.5))
                            .shadow(color: Color.hoyoNavy.opacity(0.20), radius: 0, x: 2, y: 2)
                    }
                }
            }

            // Date badge — thick cartoon pill
            HStack(spacing: 7) {
                Image(systemName: "star.fill")
                    .font(.system(size: 12, weight: .black))
                    .foregroundStyle(Color.hoyoYellow)
                Text(todayLabel)
                    .font(.system(size: 14, weight: .black))
                    .foregroundStyle(.white)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 9)
            .background(Color.hoyoNavy)
            .clipShape(Capsule())
            .overlay(Capsule().stroke(Color.hoyoNavy, lineWidth: 2))
            .shadow(color: Color.hoyoNavy.opacity(0.18), radius: 0, x: 2, y: 2)
        }
        .padding(.horizontal, 16)
        .padding(.top, 18)
        .padding(.bottom, 6)
    }

    private var todayLabel: String {
        let f = DateFormatter()
        f.locale = Locale(identifier: "zh_CN")
        f.dateFormat = "M月d日 EEEE"
        return f.string(from: Date())
    }

    private func openAddGame() {
        guard customGames.count < purchaseService.tier.maxCustomGames else {
            addLimitMessage = purchaseService.tier.customGameLimitMessage(currentCount: customGames.count)
            return
        }
        showAISearch = true
    }

    // MARK: - Overview Stats

    private var totalPending: Int {
        let remote = service.events.filter { $0.remaining > 0 && !$0.isDone }.count
        let custom = customGames.flatMap(\.events).filter { $0.remaining > 0 && !$0.isDone }.count
        return remote + custom
    }

    private var totalEndingSoon: Int {
        let remote = service.events.filter { $0.remaining > 0 && $0.remaining <= 7 * 86400 && !$0.isDone }.count
        let custom = customGames.flatMap(\.events).filter { $0.remaining > 0 && $0.remaining <= 7 * 86400 && !$0.isDone }.count
        return remote + custom
    }

    private var totalDone: Int {
        let remote = service.events.filter { $0.isDone }.count
        let custom = customGames.flatMap(\.events).filter { $0.isDone }.count
        return remote + custom
    }

    // Unified recent item for mixing RemoteEvent + CustomEvent
    private struct RecentItem: Identifiable {
        let id: String
        let title: String
        let gameEmoji: String
        let gameName: String
        let endDate: Date
        let isDone: Bool
    }

    private var recentItems: [RecentItem] {
        let sevenDays = 7.0 * 86400
        var items: [RecentItem] = []
        for e in service.events where !e.isDone && e.remaining > 0 && e.remaining <= sevenDays {
            items.append(RecentItem(id: e.id, title: e.title,
                                    gameEmoji: e.game.emoji, gameName: e.game.displayName,
                                    endDate: e.endDate, isDone: e.isDone))
        }
        for g in customGames {
            for e in g.events where !e.isDone && e.remaining > 0 && e.remaining <= sevenDays {
                items.append(RecentItem(id: e.id, title: e.title,
                                        gameEmoji: g.emoji, gameName: g.name,
                                        endDate: e.endDate, isDone: e.isDone))
            }
        }
        return items.sorted { $0.endDate < $1.endDate }
    }

    // MARK: - Overview Card

    private var overviewCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            dashSectionHeader(icon: "chart.bar.fill", iconColor: Color.hoyoPink, title: "今日呈报")

            HStack(spacing: 10) {
                statPill(count: totalPending,    label: "待完成",  bg: Color.hoyoPink,   fg: .white)
                statPill(count: totalEndingSoon, label: "即将结束", bg: Color.hoyoYellow, fg: Color.hoyoNavy)
                statPill(count: totalDone,       label: "已完成",  bg: Color.hoyoMint,   fg: .white)
            }
        }
        .padding(16)
        .background(Color.hoyoCardBg)
        .clipShape(RoundedRectangle(cornerRadius: 18))
        .overlay(RoundedRectangle(cornerRadius: 18).stroke(Color.hoyoNavy, lineWidth: 2.5))
        .shadow(color: Color.hoyoNavy.opacity(0.22), radius: 0, x: 3, y: 3)
    }

    @ViewBuilder
    private func statPill(count: Int, label: String, bg: Color, fg: Color) -> some View {
        VStack(spacing: 4) {
            Text("\(count)")
                .font(.system(size: 26, weight: .black, design: .rounded))
                .foregroundStyle(fg)
            Text(label)
                .font(.system(size: 11, weight: .bold))
                .foregroundStyle(fg.opacity(0.85))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 14)
        .background(bg)
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.hoyoNavy, lineWidth: 2))
    }

    // MARK: - Recently Ended Card

    private var recentlyEndedCard: some View {
        VStack(alignment: .leading, spacing: 0) {
            dashSectionHeader(icon: "hourglass", iconColor: Color.hoyoYellow, title: "临期活动")
                .padding(.horizontal, 16)
                .padding(.top, 14)
                .padding(.bottom, 10)

            if recentItems.isEmpty {
                Text("7 天内暂无临期活动，小的先候着。")
                    .font(.subheadline)
                    .foregroundStyle(Color.hoyoNavy.opacity(0.35))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 20)
            } else {
                ForEach(Array(recentItems.enumerated()), id: \.element.id) { idx, item in
                    if idx > 0 {
                        Rectangle()
                            .fill(Color.hoyoNavy.opacity(0.07))
                            .frame(height: 1)
                            .padding(.horizontal, 16)
                    }
                    HStack(spacing: 12) {
                        Text(item.gameEmoji)
                            .font(.system(size: 18))
                            .frame(width: 36, height: 36)
                            .background(
                                RoundedRectangle(cornerRadius: 10)
                                    .fill(Color.hoyoNavy.opacity(0.07))
                            )

                        VStack(alignment: .leading, spacing: 2) {
                            Text(item.title)
                                .font(.system(size: 13, weight: .bold))
                                .foregroundStyle(Color.hoyoNavy)
                                .lineLimit(1)
                            Text(item.gameName)
                                .font(.system(size: 11))
                                .foregroundStyle(Color.hoyoNavy.opacity(0.35))
                        }

                        Spacer()

                        let days = Int(item.endDate.timeIntervalSinceNow) / 86400
                        let hours = (Int(item.endDate.timeIntervalSinceNow) % 86400) / 3600
                        let remainLabel = days > 0 ? "\(days)天\(hours)时" : "\(hours)时"
                        let isUrgent = item.endDate.timeIntervalSinceNow <= 2 * 86400
                        Text(remainLabel)
                            .font(.system(size: 11, weight: .bold))
                            .foregroundStyle(isUrgent ? Color.hoyoPink : Color.hoyoNavy)
                            .padding(.horizontal, 9)
                            .padding(.vertical, 5)
                            .background(
                                (isUrgent ? Color.hoyoPink : Color.hoyoNavy).opacity(0.10),
                                in: Capsule()
                            )
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                }
            }
        }
        .background(Color.hoyoCardBg)
        .clipShape(RoundedRectangle(cornerRadius: 18))
        .overlay(RoundedRectangle(cornerRadius: 18).stroke(Color.hoyoNavy, lineWidth: 2.5))
        .shadow(color: Color.hoyoNavy.opacity(0.22), radius: 0, x: 3, y: 3)
    }

    // MARK: - Game List Card

    private var gameListCard: some View {
        VStack(alignment: .leading, spacing: 0) {
            dashSectionHeader(icon: "gamecontroller.fill", iconColor: Color(hex: "6B5EA8"), title: "朕的奏折")
                .padding(.horizontal, 16)
                .padding(.top, 14)
                .padding(.bottom, 10)

            if followedGames.isEmpty && customGames.isEmpty {
                Text("还没有要盯的游戏")
                    .font(.subheadline)
                    .foregroundStyle(Color.hoyoNavy.opacity(0.35))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 20)
            } else {
                ForEach(Array(followedGames.enumerated()), id: \.element.rawValue) { idx, game in
                    if idx > 0 {
                        Rectangle().fill(Color.hoyoNavy.opacity(0.07)).frame(height: 1).padding(.horizontal, 16)
                    }
                    NavigationLink { GameDetailView(game: game) } label: {
                        gameListRow(emoji: game.emoji, name: game.displayName,
                                    count: activeCount(for: game), color: game.cardHeaderColor)
                    }
                    .buttonStyle(CardPressStyle())
                }
                ForEach(Array(customGames.enumerated()), id: \.element.id) { idx, game in
                    Rectangle().fill(Color.hoyoNavy.opacity(0.07)).frame(height: 1).padding(.horizontal, 16)
                    NavigationLink { CustomGameDetailView(game: game) } label: {
                        gameListRow(emoji: game.emoji, name: game.name,
                                    count: game.activeEvents.count, color: game.accentColor)
                    }
                    .buttonStyle(CardPressStyle())
                }
            }
        }
        .background(Color.hoyoCardBg)
        .clipShape(RoundedRectangle(cornerRadius: 18))
        .overlay(RoundedRectangle(cornerRadius: 18).stroke(Color.hoyoNavy, lineWidth: 2.5))
        .shadow(color: Color.hoyoNavy.opacity(0.22), radius: 0, x: 3, y: 3)
    }

    @ViewBuilder
    private func gameListRow(emoji: String, name: String, count: Int, color: Color) -> some View {
        HStack(spacing: 12) {
            Text(emoji)
                .font(.system(size: 20))
                .frame(width: 40, height: 40)
                .background(
                    RoundedRectangle(cornerRadius: 11)
                        .fill(color.opacity(0.15))
                        .overlay(RoundedRectangle(cornerRadius: 11).stroke(color.opacity(0.30), lineWidth: 1.5))
                )

            Text(name)
                .font(.system(size: 15, weight: .bold))
                .foregroundStyle(Color.hoyoNavy)

            Spacer()

            if count > 0 {
                Text("\(count) 个活动")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(Color.hoyoNavy)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(Color.hoyoYellow)
                    .clipShape(Capsule())
                    .overlay(Capsule().stroke(Color.hoyoNavy, lineWidth: 1.5))
            }

            Image(systemName: "chevron.right")
                .font(.system(size: 12, weight: .bold))
                .foregroundStyle(Color.hoyoNavy.opacity(0.30))
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }

    // MARK: - Dashboard Section Header

    @ViewBuilder
    private func dashSectionHeader(icon: String, iconColor: Color, title: String) -> some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 12, weight: .bold))
                .foregroundStyle(.white)
                .frame(width: 26, height: 26)
                .background(iconColor, in: RoundedRectangle(cornerRadius: 7))
            Text(title)
                .font(.system(size: 15, weight: .black, design: .rounded))
                .foregroundStyle(Color.hoyoNavy)
            Spacer()
        }
    }

    // MARK: Helpers

    private func activeCount(for game: HoYoGame) -> Int {
        service.events.filter { $0.game == game && $0.remaining > 0 && !$0.isDone }.count
    }

    private func totalCount(for game: HoYoGame) -> Int {
        service.events.filter { $0.game == game && $0.remaining > 0 }.count
    }

    private func urgentEvent(for game: HoYoGame) -> RemoteEvent? {
        service.events
            .filter { $0.game == game && $0.remaining > 0 && !$0.isDone }
            .min(by: { $0.remaining < $1.remaining })
    }

    private func topEvents(for game: HoYoGame) -> [RemoteEvent] {
        Array(
            service.events
                .filter { $0.game == game && $0.remaining > 0 && !$0.isDone }
                .sorted { $0.remaining < $1.remaining }
                .prefix(2)
        )
    }
}

// MARK: - Games Tab

struct GamesTabView: View {
    @Environment(ActivityService.self) private var service
    @Environment(PurchaseService.self) private var purchaseService
    @Environment(\.modelContext)       private var modelContext
    @Query private var prefsQuery:  [UserPreferences]
    @Query private var customGames: [CustomGame]
    @State private var showAISearch  = false
    @State private var showPremium   = false
    @State private var cardsAppeared = false
    @State private var addLimitMessage: String? = nil

    private var prefs:        UserPreferences? { prefsQuery.first }
    private var followedGames: [HoYoGame]      { prefs?.followedGames ?? [] }

    var body: some View {
        NavigationStack {
            ZStack {
                Color.hoyoBg.ignoresSafeArea(edges: .top)

                Canvas { ctx, size in
                    for row in stride(from: 0, through: size.height, by: 22) {
                        for col in stride(from: 0, through: size.width, by: 22) {
                            let r = CGRect(x: col - 1.5, y: row - 1.5, width: 3, height: 3)
                            ctx.fill(Path(ellipseIn: r), with: .color(Color.hoyoPink.opacity(0.12)))
                        }
                    }
                }
                .ignoresSafeArea()
                .allowsHitTesting(false)

                if followedGames.isEmpty && customGames.isEmpty {
                    VStack(spacing: 16) {
                        gamesHeader
                        Spacer()
                        ContentUnavailableView {
                            Label("还没有游戏", systemImage: "gamecontroller")
                        } description: {
                            Text("点右上角 + 添加自定义游戏，或在设置中关注米哈游游戏。")
                        }
                        Spacer()
                    }
                } else {
                    ScrollView {
                        VStack(spacing: 0) {
                            gamesHeader

                            LazyVStack(spacing: 20) {
                                ForEach(Array(followedGames.enumerated()), id: \.element.rawValue) { index, game in
                                    NavigationLink {
                                        GameDetailView(game: game)
                                    } label: {
                                        GameCard(
                                            game: game,
                                            activeCount: activeCount(for: game),
                                            totalCount: totalCount(for: game),
                                            urgentEvent: urgentEvent(for: game),
                                            topEvents: topEvents(for: game)
                                        )
                                    }
                                    .buttonStyle(CardPressStyle())
                                    .opacity(cardsAppeared ? 1 : 0)
                                    .offset(y: cardsAppeared ? 0 : 28)
                                    .animation(.spring(response: 0.5, dampingFraction: 0.72).delay(Double(index) * 0.09), value: cardsAppeared)
                                }

                                ForEach(Array(customGames.enumerated()), id: \.element.id) { index, game in
                                    NavigationLink {
                                        CustomGameDetailView(game: game)
                                    } label: {
                                        CustomGameCard(game: game)
                                    }
                                    .buttonStyle(CardPressStyle())
                                    .opacity(cardsAppeared ? 1 : 0)
                                    .offset(y: cardsAppeared ? 0 : 28)
                                    .animation(.spring(response: 0.5, dampingFraction: 0.72).delay(Double(followedGames.count + index) * 0.09), value: cardsAppeared)
                                }

                                Text("✦ 以上就是小的今日呈报 ✦")
                                    .font(.caption2).fontWeight(.semibold)
                                    .foregroundStyle(Color.hoyoPink.opacity(0.45))
                                    .frame(maxWidth: .infinity, alignment: .center)
                                    .padding(.top, 4)
                                    .padding(.bottom, 110)
                            }
                            .padding(.horizontal, 16)
                            .padding(.top, 14)
                        }
                    }
                }
            }
            .sheet(isPresented: $showAISearch) { AIGameSearchView() }
            .sheet(isPresented: $showPremium) { PremiumView() }
            .alert("自定义游戏已达上限", isPresented: Binding(
                get: { addLimitMessage != nil },
                set: { if !$0 { addLimitMessage = nil } }
            )) {
                if !purchaseService.isPremium {
                    Button("升级会员") {
                        addLimitMessage = nil
                        showPremium = true
                    }
                }
                Button("知道了", role: .cancel) {}
            } message: {
                Text(addLimitMessage ?? "")
            }
            .fontDesign(.rounded)
            .onAppear {
                cardsAppeared = false
                withAnimation { cardsAppeared = true }
            }
        }
    }

    // MARK: Header

    private var gamesHeader: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 5) {
                Text("朕的奏折")
                    .font(.system(size: 28, weight: .black))
                    .foregroundStyle(Color.hoyoNavy)
                Rectangle()
                    .fill(Color.hoyoPink)
                    .frame(height: 4)
                    .cornerRadius(2)
                    .padding(.trailing, 36)
            }
            Spacer()
            Button { openAddGame() } label: {
                Image(systemName: "plus")
                    .font(.system(size: 17, weight: .black))
                    .foregroundStyle(.white)
                    .frame(width: 40, height: 40)
                    .background(Color.hoyoPink)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.hoyoNavy, lineWidth: 2.5))
                    .shadow(color: Color.hoyoNavy.opacity(0.20), radius: 0, x: 2, y: 2)
            }
        }
        .padding(.horizontal, 16)
        .padding(.top, 18)
        .padding(.bottom, 6)
    }

    private func openAddGame() {
        guard customGames.count < purchaseService.tier.maxCustomGames else {
            addLimitMessage = purchaseService.tier.customGameLimitMessage(currentCount: customGames.count)
            return
        }
        showAISearch = true
    }

    // MARK: Helpers

    private func activeCount(for game: HoYoGame) -> Int {
        service.events.filter { $0.game == game && $0.remaining > 0 && !$0.isDone }.count
    }

    private func totalCount(for game: HoYoGame) -> Int {
        service.events.filter { $0.game == game && $0.remaining > 0 }.count
    }

    private func urgentEvent(for game: HoYoGame) -> RemoteEvent? {
        service.events
            .filter { $0.game == game && $0.remaining > 0 && !$0.isDone }
            .min(by: { $0.remaining < $1.remaining })
    }

    private func topEvents(for game: HoYoGame) -> [RemoteEvent] {
        Array(
            service.events
                .filter { $0.game == game && $0.remaining > 0 && !$0.isDone }
                .sorted { $0.remaining < $1.remaining }
                .prefix(2)
        )
    }
}

// MARK: - Game Card Skeleton

struct GameCardSkeleton: View {
    @State private var phase: CGFloat = -1

    var body: some View {
        VStack(spacing: 0) {
            RoundedRectangle(cornerRadius: 0)
                .fill(Color.primary.opacity(0.12))
                .frame(height: 80)

            RoundedRectangle(cornerRadius: 0)
                .fill(Color.primary.opacity(0.05))
                .frame(height: 120)
        }
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .overlay(shimmerOverlay)
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(Color.hoyoNavy, lineWidth: 2.5)
        )
        .shadow(color: Color.hoyoNavy.opacity(0.18), radius: 0, x: 2, y: 2)
        .onAppear {
            withAnimation(.easeInOut(duration: 1.4).repeatForever(autoreverses: false)) {
                phase = 1
            }
        }
    }

    private var shimmerOverlay: some View {
        GeometryReader { geo in
            let w = geo.size.width
            LinearGradient(
                stops: [
                    .init(color: .clear,               location: 0),
                    .init(color: .white.opacity(0.25), location: 0.4),
                    .init(color: .white.opacity(0.4),  location: 0.5),
                    .init(color: .white.opacity(0.25), location: 0.6),
                    .init(color: .clear,               location: 1),
                ],
                startPoint: .leading,
                endPoint: .trailing
            )
            .frame(width: w * 2)
            .offset(x: phase * w)
        }
        .clipShape(RoundedRectangle(cornerRadius: 20))
    }
}

// MARK: - Game Card

struct GameCard: View {
    let game: HoYoGame
    let activeCount: Int
    let totalCount: Int
    var urgentEvent: RemoteEvent? = nil
    var topEvents: [RemoteEvent] = []

    var body: some View {
        VStack(spacing: 0) {
            boardHeader

            if !topEvents.isEmpty {
                VStack(spacing: 10) {
                    ForEach(topEvents) { event in
                        MiniEventRow(event: event, game: game)
                    }
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 12)
                .background(Color.hoyoCardBg)
            } else {
                HStack {
                    Text(totalCount == 0 ? "本轮暂且清闲，您可歇会儿 🎉" : "已全清，小的记下了！")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundStyle(Color.hoyoNavy.opacity(0.40))
                        .padding(.vertical, 20)
                    Spacer()
                }
                .padding(.horizontal, 16)
                .background(Color.hoyoCardBg)
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(Color.hoyoNavy, lineWidth: 3)
        )
        .overlay(alignment: .topTrailing) {
            activityBadge
                .offset(x: -10, y: -12)
        }
        .fontDesign(.rounded)
    }

    private var activityBadge: some View {
        HStack(spacing: 4) {
            Image(systemName: "bolt.fill")
                .font(.system(size: 11, weight: .black))
            Text("\(activeCount) 个活动")
                .font(.system(size: 12, weight: .black))
        }
        .foregroundStyle(Color.hoyoNavy)
        .padding(.horizontal, 11)
        .padding(.vertical, 7)
        .background(Color.hoyoYellow)
        .clipShape(Capsule())
        .overlay(Capsule().stroke(Color.hoyoNavy, lineWidth: 2))
    }

    private var boardHeader: some View {
        HStack(spacing: 12) {
            Text(game.emoji)
                .font(.system(size: 30))
                .frame(width: 58, height: 58)
                .background(
                    RoundedRectangle(cornerRadius: 14)
                        .fill(Color.white.opacity(0.92))
                        .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.white.opacity(0.60), lineWidth: 2))
                )

            VStack(alignment: .leading, spacing: 4) {
                Text(game.displayName)
                    .font(.system(size: 20, weight: .black))
                    .foregroundStyle(.white)
                Text("QUEST BOARD · 进行中")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundStyle(.white.opacity(0.80))
                    .kerning(0.8)
            }

            Spacer()
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 14)
        .padding(.trailing, 76)
        .background(game.cardHeaderColor)
        .overlay(alignment: .trailing) {
            ZStack {
                Circle()
                    .fill(.white.opacity(0.18))
                    .overlay(Circle().stroke(.white.opacity(0.40), lineWidth: 1.5))
                    .frame(width: 30, height: 30)
                Image(systemName: "chevron.right")
                    .font(.system(size: 13, weight: .black))
                    .foregroundStyle(.white.opacity(0.85))
            }
            .padding(.trailing, 14)
        }
    }
}

// MARK: - Mini Event Row (inside GameCard)

struct MiniEventRow: View {
    let event: RemoteEvent
    let game: HoYoGame

    private var isUrgent: Bool { event.urgency == .critical || event.urgency == .warning }

    private var compactRemaining: String {
        let rem = Int(event.remaining)
        guard rem > 0 else { return "已结束" }
        let days    = rem / 86400
        let hours   = (rem % 86400) / 3600
        let minutes = (rem % 3600) / 60
        if days  > 0 { return "\(days)天\(hours)时" }
        if hours > 0 { return "\(hours)时\(minutes)分" }
        return "\(minutes)分"
    }

    var body: some View {
        HStack(spacing: 10) {
            // Left accent bar
            Capsule()
                .fill(isUrgent ? Color.hoyoPink : game.cardHeaderColor)
                .frame(width: 5, height: 36)

            // Icon circle
            ZStack {
                Circle()
                    .fill(isUrgent ? Color.hoyoPink.opacity(0.15) : game.cardHeaderColor.opacity(0.12))
                    .frame(width: 32, height: 32)
                    .overlay(Circle().stroke(isUrgent ? Color.hoyoPink : game.cardHeaderColor, lineWidth: 1.5))
                Text(isUrgent ? "!" : "▶")
                    .font(.system(size: isUrgent ? 15 : 10, weight: .black))
                    .foregroundStyle(isUrgent ? Color.hoyoPink : game.cardHeaderColor)
            }

            // Title
            Text(event.title)
                .font(.system(size: 14, weight: .bold))
                .foregroundStyle(Color.hoyoNavy)
                .lineLimit(1)

            Spacer(minLength: 4)

            // Countdown pill
            HStack(spacing: 3) {
                Image(systemName: "clock")
                    .font(.system(size: 10, weight: .bold))
                Text(compactRemaining)
                    .font(.system(size: 12, weight: .black))
            }
            .foregroundStyle(isUrgent ? .white : Color.hoyoNavy)
            .padding(.horizontal, 11)
            .padding(.vertical, 6)
            .background(isUrgent ? Color.hoyoPink : Color.hoyoYellow)
            .clipShape(Capsule())
            .overlay(Capsule().stroke(Color.hoyoNavy, lineWidth: 1.5))
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(Color.hoyoCardBg)
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(isUrgent ? Color.hoyoPink : Color.hoyoNavy.opacity(0.20), lineWidth: 2)
        )
    }
}

// MARK: - Custom Game Card

struct CustomGameCard: View {
    let game: CustomGame

    private var activeCount: Int { game.activeEvents.count }

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack(spacing: 12) {
                Text(game.emoji)
                    .font(.system(size: 30))
                    .frame(width: 58, height: 58)
                    .background(
                        RoundedRectangle(cornerRadius: 14)
                            .fill(Color.white.opacity(0.92))
                            .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.white.opacity(0.60), lineWidth: 2))
                    )

                VStack(alignment: .leading, spacing: 4) {
                    Text(game.name)
                        .font(.system(size: 20, weight: .black))
                        .foregroundStyle(.white)
                    Text("QUEST BOARD · 进行中")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundStyle(.white.opacity(0.80))
                        .kerning(0.8)
                }

                Spacer()
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 14)
            .padding(.trailing, 76)
            .background(game.accentColor)
            .overlay(alignment: .trailing) {
                ZStack {
                    Circle()
                        .fill(.white.opacity(0.18))
                        .overlay(Circle().stroke(.white.opacity(0.40), lineWidth: 1.5))
                        .frame(width: 30, height: 30)
                    Image(systemName: "chevron.right")
                        .font(.system(size: 13, weight: .black))
                        .foregroundStyle(.white.opacity(0.85))
                }
                .padding(.trailing, 14)
            }

            // Events body
            let topEvents = Array(game.activeEvents.prefix(2))
            if !topEvents.isEmpty {
                VStack(spacing: 10) {
                    ForEach(Array(topEvents.enumerated()), id: \.element.id) { _, event in
                        HStack(spacing: 10) {
                            Capsule()
                                .fill(game.accentColor)
                                .frame(width: 5, height: 36)
                            ZStack {
                                Circle()
                                    .fill(game.accentColor.opacity(0.12))
                                    .frame(width: 32, height: 32)
                                    .overlay(Circle().stroke(game.accentColor, lineWidth: 1.5))
                                Text("▶")
                                    .font(.system(size: 10, weight: .black))
                                    .foregroundStyle(game.accentColor)
                            }
                            Text(event.title)
                                .font(.system(size: 14, weight: .bold))
                                .foregroundStyle(Color.hoyoNavy)
                                .lineLimit(1)
                            Spacer(minLength: 4)
                            HStack(spacing: 3) {
                                Image(systemName: "clock").font(.system(size: 10, weight: .bold))
                                Text(event.remainingText.replacingOccurrences(of: "剩余 ", with: ""))
                                    .font(.system(size: 12, weight: .black))
                            }
                            .foregroundStyle(Color.hoyoNavy)
                            .padding(.horizontal, 11).padding(.vertical, 6)
                            .background(Color.hoyoYellow)
                            .clipShape(Capsule())
                            .overlay(Capsule().stroke(Color.hoyoNavy, lineWidth: 1.5))
                        }
                        .padding(.horizontal, 12).padding(.vertical, 10)
                        .background(Color.hoyoCardBg)
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                        .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.hoyoNavy.opacity(0.20), lineWidth: 2))
                    }
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 12)
                .background(Color.hoyoCardBg)
            } else {
                HStack {
                    Text("暂无活动，小的先候着 🎉")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundStyle(Color.hoyoNavy.opacity(0.40))
                        .padding(.vertical, 20)
                    Spacer()
                }
                .padding(.horizontal, 16)
                .background(Color.hoyoCardBg)
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(Color.hoyoNavy, lineWidth: 3)
        )
        .overlay(alignment: .topTrailing) {
            HStack(spacing: 4) {
                Image(systemName: "bolt.fill")
                    .font(.system(size: 11, weight: .black))
                Text("\(activeCount) 个活动")
                    .font(.system(size: 12, weight: .black))
            }
            .foregroundStyle(Color.hoyoNavy)
            .padding(.horizontal, 11)
            .padding(.vertical, 7)
            .background(Color.hoyoYellow)
            .clipShape(Capsule())
            .overlay(Capsule().stroke(Color.hoyoNavy, lineWidth: 2))
            .offset(x: -10, y: -12)
        }
        .fontDesign(.rounded)
    }
}
