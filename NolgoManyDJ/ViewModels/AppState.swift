import SwiftUI

// MARK: - App State (전역 상태 관리)
@Observable
class AppState {
    // Onboarding
    var hasCompletedOnboarding: Bool = UserDefaults.standard.bool(forKey: "hasCompletedOnboarding")
    var selectedThemes: Set<OnboardingTheme> = []
    var preferredAgeGroup: AgeGroup = {
        guard let rawValue = UserDefaults.standard.string(forKey: "preferredAgeGroup"),
              let ageGroup = AgeGroup(rawValue: rawValue) else {
            return .twenties
        }
        return ageGroup
    }()

    // Navigation
    var selectedTab: AppTab = .home
    var selectedDistrict: District = .eunhaeng

    // Saved items (로컬, 추후 Supabase 연동)
    var savedStoreIds: Set<String> = []
    var savedCourseIds: Set<String> = []
    var likedSharedCourseIds: Set<String> = []

    // Visits
    var visitedStoreIds: Set<String> = []
    var visits: [UserVisit] = []

    // MARK: - Onboarding
    func completeOnboarding() {
        hasCompletedOnboarding = true
        UserDefaults.standard.set(true, forKey: "hasCompletedOnboarding")
    }

    // MARK: - Save/Unsave
    func toggleSaveStore(_ storeId: String) {
        if savedStoreIds.contains(storeId) {
            savedStoreIds.remove(storeId)
        } else {
            savedStoreIds.insert(storeId)
        }
        persistSavedStores()
    }

    func toggleSaveCourse(_ courseId: String) {
        if savedCourseIds.contains(courseId) {
            savedCourseIds.remove(courseId)
        } else {
            savedCourseIds.insert(courseId)
        }
        persistSavedCourses()
    }

    func isStoreSaved(_ storeId: String) -> Bool {
        savedStoreIds.contains(storeId)
    }

    func isCourseSaved(_ courseId: String) -> Bool {
        savedCourseIds.contains(courseId)
    }

    func toggleLikeSharedCourse(_ courseId: String) {
        if likedSharedCourseIds.contains(courseId) {
            likedSharedCourseIds.remove(courseId)
        } else {
            likedSharedCourseIds.insert(courseId)
        }
        persistLikedSharedCourses()
    }

    func isSharedCourseLiked(_ courseId: String) -> Bool {
        likedSharedCourseIds.contains(courseId)
    }

    func updatePreferredAgeGroup(_ ageGroup: AgeGroup) {
        preferredAgeGroup = ageGroup
        UserDefaults.standard.set(ageGroup.rawValue, forKey: "preferredAgeGroup")
    }

    // MARK: - Visit
    func markVisited(_ storeId: String) {
        visitedStoreIds.insert(storeId)
        let coordinate = MockData.store(byId: storeId).map {
            CodableCoordinate(latitude: $0.latitude, longitude: $0.longitude)
        }
        let visit = UserVisit(
            id: UUID().uuidString,
            userId: "local-user",
            storeId: storeId,
            visitedAt: Date(),
            verificationType: .manual,
            note: nil,
            coordinate: coordinate
        )
        visits.append(visit)
        persistVisits()
        persistVisitedStores()
    }

    func isVisited(_ storeId: String) -> Bool {
        visitedStoreIds.contains(storeId)
    }

    var completedEditorCourseIds: [String] {
        MockData.courses.compactMap { course in
            let stopIds = Set(course.stops.map(\.storeId))
            return stopIds.isSubset(of: visitedStoreIds) ? course.id : nil
        }
    }

    var completedSharedCourseIds: [String] {
        MockData.userGeneratedCourses.compactMap { course in
            let stopIds = Set(course.stops.compactMap(\.storeId))
            guard !stopIds.isEmpty else { return nil }
            return stopIds.isSubset(of: visitedStoreIds) ? course.id : nil
        }
    }

    var rewardProgress: RewardProgress {
        let stamps = visits.compactMap { visit -> StampRecord? in
            guard let coordinate = visit.coordinate else { return nil }
            return StampRecord(
                id: "stamp-\(visit.id)",
                storeId: visit.storeId,
                courseId: nil,
                verifiedAt: visit.visitedAt,
                verificationType: visit.verificationType,
                coordinate: coordinate
            )
        }

        let badges = earnedBadgeTypes.enumerated().map { offset, badgeType in
            BadgeRecord(
                id: "badge-\(offset)-\(badgeType.rawValue)",
                badgeType: badgeType,
                earnedAt: Date().addingTimeInterval(TimeInterval(-offset * 86_400)),
                courseId: nil
            )
        }

        let totalCoursesCompleted = completedEditorCourseIds.count + completedSharedCourseIds.count
        let seasonProgress = min(
            100,
            (visitedStoreIds.count * 12) +
            (totalCoursesCompleted * 18) +
            (likedSharedCourseIds.count * 4) +
            (savedCourseIds.count * 3)
        )

        return RewardProgress(
            id: "reward-local-user",
            userId: "local-user",
            stamps: stamps,
            badges: badges,
            totalVisits: visitedStoreIds.count,
            totalCoursesCompleted: totalCoursesCompleted,
            currentSeasonId: "2026-spring-daejeon",
            seasonProgress: seasonProgress
        )
    }

    var earnedBadgeTypes: [BadgeType] {
        var badges: [BadgeType] = []
        let completedCount = completedEditorCourseIds.count + completedSharedCourseIds.count

        if completedCount >= 1 { badges.append(.firstCourse) }
        if completedCount >= 5 { badges.append(.fiveCourses) }
        if completedCount >= 10 { badges.append(.tenCourses) }
        if visitedCount(in: .eunhaeng) >= 3 { badges.append(.eunhaengMaster) }
        if visitedCount(in: .daeheung) >= 3 { badges.append(.daeheungMaster) }
        if visitedCount(in: .sunhwa) >= 3 { badges.append(.sunhwaMaster) }

        let nightCourses = MockData.courses.filter { completedEditorCourseIds.contains($0.id) && $0.theme == .night }
        if !nightCourses.isEmpty { badges.append(.nightOwl) }

        let rainyCourses = MockData.courses.filter { completedEditorCourseIds.contains($0.id) && $0.theme == .rainy }
        if !rainyCourses.isEmpty { badges.append(.rainyDayWalker) }

        let foodCourses = MockData.courses.filter { completedEditorCourseIds.contains($0.id) && $0.theme == .food }
        if !foodCourses.isEmpty { badges.append(.foodHunter) }

        let breadTagged = MockData.userGeneratedCourses.filter {
            completedSharedCourseIds.contains($0.id) && $0.tags.contains("빵축제")
        }
        if !breadTagged.isEmpty { badges.append(.breadFestival2026) }

        let blossomTagged = MockData.userGeneratedCourses.filter {
            completedSharedCourseIds.contains($0.id) && $0.tags.contains("벚꽃축제")
        }
        if !blossomTagged.isEmpty { badges.append(.cherryBlossom2026) }

        return badges
    }

    var nextBadgeTarget: BadgeType? {
        BadgeType.allCases.first { earnedBadgeTypes.contains($0) == false }
    }

    var dashboardStreak: Int {
        max(1, min(21, visitedStoreIds.count + completedEditorCourseIds.count + likedSharedCourseIds.count / 2))
    }

    var localExplorerLevel: String {
        switch rewardProgress.totalCoursesCompleted {
        case 0: return "로컬 입문자"
        case 1...2: return "골목 탐험가"
        case 3...4: return "대전 큐레이터"
        default: return "원도심 마스터"
        }
    }

    func visitedCount(in district: District) -> Int {
        MockData.stores.filter { $0.district == district && visitedStoreIds.contains($0.id) }.count
    }

    // MARK: - Persistence (UserDefaults, 추후 Supabase 전환)
    func loadSavedData() {
        if let storeIds = UserDefaults.standard.array(forKey: "savedStoreIds") as? [String] {
            savedStoreIds = Set(storeIds)
        }
        if let courseIds = UserDefaults.standard.array(forKey: "savedCourseIds") as? [String] {
            savedCourseIds = Set(courseIds)
        }
        if let visitIds = UserDefaults.standard.array(forKey: "visitedStoreIds") as? [String] {
            visitedStoreIds = Set(visitIds)
        }
        if let likedIds = UserDefaults.standard.array(forKey: "likedSharedCourseIds") as? [String] {
            likedSharedCourseIds = Set(likedIds)
        }
        if let visitData = UserDefaults.standard.data(forKey: "userVisits"),
           let decodedVisits = try? JSONDecoder().decode([UserVisit].self, from: visitData) {
            visits = decodedVisits
        }
    }

    private func persistSavedStores() {
        UserDefaults.standard.set(Array(savedStoreIds), forKey: "savedStoreIds")
    }

    private func persistSavedCourses() {
        UserDefaults.standard.set(Array(savedCourseIds), forKey: "savedCourseIds")
    }

    private func persistVisitedStores() {
        UserDefaults.standard.set(Array(visitedStoreIds), forKey: "visitedStoreIds")
    }

    private func persistLikedSharedCourses() {
        UserDefaults.standard.set(Array(likedSharedCourseIds), forKey: "likedSharedCourseIds")
    }

    private func persistVisits() {
        if let encoded = try? JSONEncoder().encode(visits) {
            UserDefaults.standard.set(encoded, forKey: "userVisits")
        }
    }
}

// MARK: - Tab
enum AppTab: String, CaseIterable {
    case home = "홈"
    case map = "지도"
    case courses = "코스"
    case saved = "저장"
    case myPage = "마이"

    var icon: String {
        switch self {
        case .home: return "house.fill"
        case .map: return "map.fill"
        case .courses: return "point.topleft.down.to.point.bottomright.curvepath.fill"
        case .saved: return "bookmark.fill"
        case .myPage: return "person.fill"
        }
    }
}
