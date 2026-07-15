import SwiftUI

@main
struct NolgoManyDJApp: App {
    @State private var appState: AppState

#if DEBUG
    private let screenshotScene: ScreenshotScene?
#endif

    init() {
        let state = AppState()

#if DEBUG
        let scene = ScreenshotScene.current
        screenshotScene = scene
        scene?.prepare(state)
#endif

        _appState = State(initialValue: state)
    }

    var body: some Scene {
        WindowGroup {
            Group {
#if DEBUG
                if let screenshotScene {
                    ScreenshotSceneView(scene: screenshotScene)
                } else {
                    RootView()
                }
#else
                RootView()
#endif
            }
                .environment(appState)
        }
    }
}

#if DEBUG
// Deterministic launch scenes used by scripts/capture-screenshots.sh.
private enum ScreenshotScene: String {
    case splash
    case onboarding
    case home
    case search
    case category
    case map
    case courses
    case courseDetail = "course-detail"
    case storeDetail = "store-detail"
    case saved
    case myPage = "my-page"
    case ownerDashboard = "owner-dashboard"

    static var current: ScreenshotScene? {
        let arguments = ProcessInfo.processInfo.arguments

        if let inlineArgument = arguments.first(where: { $0.hasPrefix("--screenshot-scene=") }) {
            return ScreenshotScene(rawValue: String(inlineArgument.dropFirst("--screenshot-scene=".count)))
        }

        guard let flagIndex = arguments.firstIndex(of: "--screenshot-scene"),
              arguments.indices.contains(flagIndex + 1) else {
            return nil
        }

        return ScreenshotScene(rawValue: arguments[flagIndex + 1])
    }

    func prepare(_ state: AppState) {
        state.hasCompletedOnboarding = true

        switch self {
        case .map:
            state.selectedTab = .map
        case .courses:
            state.selectedTab = .courses
        case .saved:
            state.selectedTab = .saved
            state.savedStoreIds = ["store-013", "store-014", "store-015"]
            state.savedCourseIds = ["course-006"]
        case .myPage:
            state.selectedTab = .myPage
            state.visitedStoreIds = ["store-013", "store-014", "store-015", "store-016"]
        default:
            state.selectedTab = .home
        }
    }
}

private struct ScreenshotSceneView: View {
    let scene: ScreenshotScene

    @ViewBuilder
    var body: some View {
        switch scene {
        case .splash:
            SplashView()
        case .onboarding:
            OnboardingView()
        case .home:
            MainTabView()
        case .search:
            MainTabView(initialHomeSearchText: "성심당")
        case .category:
            MainTabView(initialHomeCategoryName: "체험")
        case .map, .courses, .saved, .myPage:
            MainTabView()
        case .courseDetail:
            NavigationStack {
                if let course = MockData.courses.first(where: { $0.id == "course-006" }) {
                    CourseDetailView(course: course)
                }
            }
        case .storeDetail:
            NavigationStack {
                if let store = MockData.store(byId: "store-013") {
                    StoreDetailView(store: store)
                }
            }
        case .ownerDashboard:
            NavigationStack {
                OwnerDashboardView()
            }
        }
    }
}
#endif

// MARK: - Root View (스플래시 → 온보딩 → 메인)
struct RootView: View {
    @Environment(AppState.self) private var appState
    @State private var isSplashFinished = false

    var body: some View {
        ZStack {
            if appState.hasCompletedOnboarding {
                MainTabView()
            } else {
                OnboardingView()
            }

            if !isSplashFinished {
                SplashView()
                    .transition(.opacity)
                    .zIndex(10)
            }
        }
        .task {
            try? await Task.sleep(nanoseconds: 1_200_000_000)
            withAnimation(.easeOut(duration: 0.45)) {
                isSplashFinished = true
            }
        }
    }
}

// MARK: - Splash View
struct SplashView: View {
    @State private var scale: CGFloat = 0.82
    @State private var opacity: Double = 0

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [Color.appPrimaryLight.opacity(0.55), Color.appAccentLight, Color.white],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            VStack(spacing: 18) {
                ZStack {
                    Circle()
                        .fill(Color.appPrimary.opacity(0.14))
                        .frame(width: 132, height: 132)

                    Image(systemName: "map.fill")
                        .font(.system(size: 56, weight: .semibold))
                        .foregroundStyle(Color.appPrimary)
                }

                Text("놀거많은대?전")
                    .font(.system(size: 40, weight: .bold))
                    .foregroundStyle(Color.appTextPrimary)

                Text("대전 놀거리와 로컬 스팟 추천")
                    .font(.system(size: 15, weight: .medium))
                    .foregroundStyle(Color.appTextSecondary)
            }
            .scaleEffect(scale)
            .opacity(opacity)
            .onAppear {
                withAnimation(.spring(response: 0.55, dampingFraction: 0.78)) {
                    scale = 1.0
                    opacity = 1.0
                }
            }
        }
    }
}

// MARK: - Main Tab View
struct MainTabView: View {
    @Environment(AppState.self) private var appState

    private let initialHomeSearchText: String
    private let initialHomeCategoryName: String?

    init(
        initialHomeSearchText: String = "",
        initialHomeCategoryName: String? = nil
    ) {
        self.initialHomeSearchText = initialHomeSearchText
        self.initialHomeCategoryName = initialHomeCategoryName
    }

    var body: some View {
        @Bindable var state = appState
        TabView(selection: $state.selectedTab) {
            HomeView(
                initialSearchText: initialHomeSearchText,
                initialCategoryName: initialHomeCategoryName
            )
                .tabItem {
                    Label(AppTab.home.rawValue, systemImage: AppTab.home.icon)
                }
                .tag(AppTab.home)

            MapExploreView()
                .tabItem {
                    Label(AppTab.map.rawValue, systemImage: AppTab.map.icon)
                }
                .tag(AppTab.map)

            CoursesView()
                .tabItem {
                    Label(AppTab.courses.rawValue, systemImage: AppTab.courses.icon)
                }
                .tag(AppTab.courses)

            SavedView()
                .tabItem {
                    Label(AppTab.saved.rawValue, systemImage: AppTab.saved.icon)
                }
                .tag(AppTab.saved)

            MyPageView()
                .tabItem {
                    Label(AppTab.myPage.rawValue, systemImage: AppTab.myPage.icon)
                }
                .tag(AppTab.myPage)
        }
        .tint(.appPrimary)
        .onAppear {
            appState.loadSavedData()
            let appearance = UITabBarAppearance()
            appearance.configureWithTransparentBackground()
            appearance.backgroundEffect = UIBlurEffect(style: .systemUltraThinMaterial)
            appearance.backgroundColor = UIColor(Color.appCardBackground.opacity(0.85))
            UITabBar.appearance().standardAppearance = appearance
            UITabBar.appearance().scrollEdgeAppearance = appearance
        }
    }
}
