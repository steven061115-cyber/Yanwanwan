import SwiftUI
import SwiftData

@main
struct Object1App: App {
    @State private var activityService = ActivityService()
    @State private var codeService     = CodeService()
    @State private var purchaseService = PurchaseService()
    @State private var showSplash      = true
    @Environment(\.scenePhase) private var scenePhase

    init() {
        applyAppearance()
    }

    private func applyAppearance() {
        // Tab bar
        let tabAppearance = UITabBarAppearance()
        tabAppearance.configureWithOpaqueBackground()
        tabAppearance.backgroundColor = UIColor(Color.hoyoBg)
        tabAppearance.stackedLayoutAppearance.selected.iconColor   = UIColor(Color.hoyoPink)
        tabAppearance.stackedLayoutAppearance.selected.titleTextAttributes = [.foregroundColor: UIColor(Color.hoyoPink)]
        UITabBar.appearance().standardAppearance  = tabAppearance
        UITabBar.appearance().scrollEdgeAppearance = tabAppearance

        // Navigation bar
        let navAppearance = UINavigationBarAppearance()
        navAppearance.configureWithOpaqueBackground()
        navAppearance.backgroundColor = UIColor(Color.hoyoBg)
        navAppearance.titleTextAttributes      = [.foregroundColor: UIColor(Color.hoyoDark)]
        navAppearance.largeTitleTextAttributes = [.foregroundColor: UIColor(Color.hoyoDark)]
        UINavigationBar.appearance().standardAppearance   = navAppearance
        UINavigationBar.appearance().scrollEdgeAppearance = navAppearance
        UINavigationBar.appearance().tintColor = UIColor(Color.hoyoPink)
    }

    // Uses CloudKit when iCloud entitlement is available, falls back to local store otherwise.
    // On any failure, resets the local store files and retries to survive migration errors.
    private let modelContainer: ModelContainer = {
        let schema = Schema([UserPreferences.self, CustomGame.self, CustomEvent.self])

        // Try iCloud-backed store first (requires iCloud + CloudKit capability in Xcode)
        // groupContainer is pinned to .none: the App Group is only used to share the
        // lightweight widget snapshot (SharedWidgetData), not the SwiftData store itself.
        let cloudConfig = ModelConfiguration(schema: schema, groupContainer: .none, cloudKitDatabase: .automatic)
        if let container = try? ModelContainer(for: schema, configurations: [cloudConfig]) {
            return container
        }

        // Fall back to local-only store (no iCloud entitlement or CloudKit unavailable)
        func makeLocal() throws -> ModelContainer {
            let config = ModelConfiguration(schema: schema, groupContainer: .none)
            return try ModelContainer(for: schema, configurations: [config])
        }

        do {
            return try makeLocal()
        } catch {
            // Store corrupted — reset and retry
            let storeURL = URL.applicationSupportDirectory.appending(component: "default.store")
            try? FileManager.default.removeItem(at: storeURL)
            try? FileManager.default.removeItem(at: storeURL.appendingPathExtension("shm"))
            try? FileManager.default.removeItem(at: storeURL.appendingPathExtension("wal"))
            return try! makeLocal()
        }
    }()

    var body: some Scene {
        WindowGroup {
            ZStack {
                ContentView()
                    .modelContainer(modelContainer)
                    .environment(activityService)
                    .environment(codeService)
                    .environment(purchaseService)

                if showSplash {
                    SplashView { showSplash = false }
                        .transition(.opacity)
                        .zIndex(1)
                }
            }
            .animation(.easeOut(duration: 0.35), value: showSplash)
            .onAppear {
                NotificationManager.shared.modelContainer = modelContainer
                NotificationManager.shared.activityService = activityService
                NotificationManager.shared.requestPermission()
                purchaseService.start()
            }
        }
        .onChange(of: scenePhase) { _, phase in
            if phase == .active {
                NotificationManager.shared.activityService = activityService
                NotificationManager.shared.rescheduleAll()
                NotificationManager.shared.clearDeliveredNotifications()
                NotificationManager.shared.clearBadge()
            }
        }
    }
}
