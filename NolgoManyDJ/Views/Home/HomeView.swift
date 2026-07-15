import SwiftUI

private enum DashboardFeedSort: String, CaseIterable, Identifiable {
    case popular = "인기"
    case myAge = "내 연령대"
    case festival = "축제"
    case latest = "최신"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .popular: return "flame.fill"
        case .myAge: return "person.2.fill"
        case .festival: return "sparkles"
        case .latest: return "clock.fill"
        }
    }
}

private enum HomeSpotCategory: String, CaseIterable, Identifiable {
    case all = "전체"
    case restaurant = "맛집"
    case cafe = "카페"
    case attraction = "관광지"
    case festival = "축제"
    case date = "데이트"
    case family = "가족"
    case experience = "체험"
    case nightSpot = "야간명소"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .all: return "square.grid.2x2.fill"
        case .restaurant: return "fork.knife"
        case .cafe: return "cup.and.saucer.fill"
        case .attraction: return "camera.viewfinder"
        case .festival: return "sparkles"
        case .date: return "heart.fill"
        case .family: return "figure.2.and.child.holdinghands"
        case .experience: return "hand.raised.fill"
        case .nightSpot: return "moon.stars.fill"
        }
    }

    func matches(_ store: Store) -> Bool {
        switch self {
        case .all:
            return true
        case .restaurant:
            return store.category == .restaurant || store.searchTags.contains("맛집")
        case .cafe:
            return store.category == .cafe || store.searchTags.contains("카페")
        case .attraction:
            return store.category == .attraction || store.category == .walkSpot || store.searchTags.contains("관광지")
        case .festival:
            return store.category == .festival || store.searchTags.contains("축제")
        case .date:
            return store.category == .date || store.searchTags.contains("데이트")
        case .family:
            return store.category == .family || store.searchTags.contains("가족")
        case .experience:
            return store.category == .experience || store.category == .workshop || store.searchTags.contains("체험")
        case .nightSpot:
            return store.category == .nightSpot || store.searchTags.contains("야간명소") || store.searchTags.contains("밤")
        }
    }
}

struct HomeView: View {
    @Environment(AppState.self) private var appState

    @State private var selectedSort: DashboardFeedSort = .popular
    @State private var selectedTag: String? = nil
    @State private var searchText = ""
    @State private var selectedHomeCategory: HomeSpotCategory = .all

    init(initialSearchText: String = "", initialCategoryName: String? = nil) {
        _searchText = State(initialValue: initialSearchText)
        _selectedHomeCategory = State(
            initialValue: initialCategoryName.flatMap(HomeSpotCategory.init(rawValue:)) ?? .all
        )
    }

    private var trimmedSearchText: String {
        searchText.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private var normalizedSearchText: String {
        normalized(trimmedSearchText)
    }

    private var isHomeSpotFilterActive: Bool {
        normalizedSearchText.isEmpty == false || selectedHomeCategory != .all
    }

    private var defaultHomeStores: [Store] {
        let priorityIds = [
            "store-014", "store-015", "store-016", "store-019",
            "store-013", "store-021", "store-020", "store-022"
        ]
        let priorityStores = priorityIds.compactMap(MockData.store(byId:))
        let remainingStores = MockData.stores.filter { store in
            priorityIds.contains(store.id) == false
        }
        return priorityStores + remainingStores
    }

    private var visibleHomeStores: [Store] {
        let source = isHomeSpotFilterActive ? MockData.stores : defaultHomeStores
        return source.filter { store in
            selectedHomeCategory.matches(store) && storeMatchesSearch(store)
        }
    }

    private var publicSharedCourses: [UserGeneratedCourse] {
        var courses = MockData.userGeneratedCourses.filter {
            $0.visibility == .publicOpen &&
            $0.district == appState.selectedDistrict
        }

        if let selectedTag {
            courses = courses.filter { $0.tags.contains(selectedTag) }
        }

        switch selectedSort {
        case .popular:
            courses.sort { popularityScore(for: $0) > popularityScore(for: $1) }
        case .myAge:
            courses.sort { coursePriorityForAge($0) > coursePriorityForAge($1) }
        case .festival:
            courses.sort { festivalPriority(for: $0) > festivalPriority(for: $1) }
        case .latest:
            courses.sort { $0.createdAt > $1.createdAt }
        }

        return courses
    }

    private var relevantTags: [String] {
        let counts = publicSharedCourses
            .flatMap(\.tags)
            .reduce(into: [String: Int]()) { partialResult, tag in
                partialResult[tag, default: 0] += 1
            }

        return counts
            .sorted { lhs, rhs in
                if lhs.value == rhs.value { return lhs.key < rhs.key }
                return lhs.value > rhs.value
            }
            .map(\.key)
    }

    private var topRankedCourses: [UserGeneratedCourse] {
        Array(publicSharedCourses.prefix(3))
    }

    private var spotlightCourse: UserGeneratedCourse? {
        publicSharedCourses.first
    }

    private var savedSharedCourses: [UserGeneratedCourse] {
        MockData.userGeneratedCourses.filter {
            appState.isCourseSaved($0.id) && $0.district == appState.selectedDistrict
        }
    }

    private var editorCourses: [Course] {
        MockData.courses.filter { $0.district == appState.selectedDistrict }
    }

    private var nearbyStores: [Store] {
        MockData.stores.filter { $0.district == appState.selectedDistrict }
    }

    var body: some View {
        NavigationStack {
            ScrollView(.vertical, showsIndicators: false) {
                VStack(spacing: AppSpacing.xl) {
                    headerSection
                    homeCategorySection
                    homeSpotSection
                    if isHomeSpotFilterActive == false {
                        districtAndAgeSection
                        rankingSection
                        sharedRoutesSection
                        savedSharedRoutesSection
                        badgeShelfSection
                        editorRoutesSection
                        storeSpotlightSection
                    }
                    Spacer(minLength: AppSpacing.xxl)
                }
                .padding(.vertical, AppSpacing.md)
            }
            .background(Color.appBackground)
            .navigationDestination(for: Store.self) { store in
                StoreDetailView(store: store)
            }
            .navigationDestination(for: Course.self) { course in
                CourseDetailView(course: course)
            }
            .navigationDestination(for: UserGeneratedCourse.self) { course in
                SharedCourseDetailView(course: course)
            }
            .onChange(of: appState.selectedDistrict) { _, _ in
                if let selectedTag, relevantTags.contains(selectedTag) == false {
                    self.selectedTag = nil
                }
            }
        }
    }

    private var headerSection: some View {
        VStack(alignment: .leading, spacing: AppSpacing.md) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("놀거많은대?전")
                        .font(AppFont.title(28))
                        .foregroundStyle(.appTextPrimary)

                    Text("오늘 대전에서 뭐 하지?")
                        .font(AppFont.title(26))
                        .foregroundStyle(.appTextPrimary)

                    Text("놀거많은대?전에서 맛집, 카페, 축제, 데이트 코스를 한 번에 찾아보세요.")
                        .font(AppFont.body(14))
                        .foregroundStyle(.appTextSecondary)
                        .lineSpacing(3)
                }

                Spacer(minLength: AppSpacing.md)

                VStack(alignment: .trailing, spacing: 8) {
                    HStack(spacing: 6) {
                        Image(systemName: "mappin.and.ellipse")
                        Text("대전 특화")
                    }
                    .font(AppFont.caption(12))
                    .foregroundStyle(.appPrimary)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(.ultraThinMaterial, in: Capsule())
                    .overlay(
                        Capsule().stroke(Color.appPrimary.opacity(0.18), lineWidth: 0.5)
                    )

                    Text("놀거리 · 먹거리 · 축제 · 체험")
                        .font(AppFont.caption(11))
                        .foregroundStyle(.appTextTertiary)
                        .multilineTextAlignment(.trailing)
                }
            }

            searchField
        }
        .padding(.horizontal, AppSpacing.md)
        .padding(.top, AppSpacing.sm)
    }

    private var searchField: some View {
        HStack(spacing: AppSpacing.sm) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(.appPrimary)

            TextField("대전의 놀거리, 맛집, 카페를 검색해보세요", text: $searchText)
                .font(AppFont.body(15))
                .foregroundStyle(.appTextPrimary)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
                .submitLabel(.search)

            if searchText.isEmpty == false {
                Button {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        searchText = ""
                    }
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundStyle(.appTextTertiary)
                }
                .accessibilityLabel("검색어 지우기")
            }
        }
        .padding(.horizontal, AppSpacing.md)
        .padding(.vertical, 14)
        .background(Color.appCardBackground)
        .clipShape(RoundedRectangle(cornerRadius: AppRadius.lg))
        .overlay(
            RoundedRectangle(cornerRadius: AppRadius.lg)
                .stroke(Color.appPrimary.opacity(0.12), lineWidth: 1)
        )
        .shadow(color: Color.appPrimary.opacity(0.08), radius: 16, y: 8)
    }

    private var homeCategorySection: some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            SectionHeader(
                title: "카테고리로 빠르게 찾기",
                subtitle: "검색어와 함께 적용돼 더 정확하게 좁혀집니다"
            )

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: AppSpacing.sm) {
                    ForEach(HomeSpotCategory.allCases) { category in
                        FilterChip(
                            label: category.rawValue,
                            icon: category.icon,
                            isSelected: selectedHomeCategory == category
                        ) {
                            withAnimation(.easeInOut(duration: 0.2)) {
                                selectedHomeCategory = category
                            }
                        }
                    }
                }
                .padding(.horizontal, AppSpacing.md)
            }
        }
    }

    private var homeSpotSection: some View {
        VStack(alignment: .leading, spacing: AppSpacing.md) {
            SectionHeader(
                title: isHomeSpotFilterActive ? "검색 결과" : "오늘 대전에서 가볼 만한 곳",
                subtitle: isHomeSpotFilterActive
                    ? "\(visibleHomeStores.count)개의 대전 스팟을 찾았어요"
                    : "대전 인기 스팟과 로컬 공간을 먼저 추천해드려요"
            )

            if visibleHomeStores.isEmpty {
                EmptyStateView(
                    icon: "magnifyingglass",
                    title: "검색 결과가 없습니다.",
                    message: "다른 키워드로 다시 검색해보세요."
                )
                .frame(maxWidth: .infinity)
                .background(Color.appCardBackground)
                .clipShape(RoundedRectangle(cornerRadius: AppRadius.lg))
                .padding(.horizontal, AppSpacing.md)
            } else {
                VStack(spacing: AppSpacing.md) {
                    ForEach(visibleHomeStores.prefix(isHomeSpotFilterActive ? 30 : 8)) { store in
                        homeSpotResultCard(store)
                    }
                }
                .padding(.horizontal, AppSpacing.md)
            }
        }
    }

    private func homeSpotResultCard(_ store: Store) -> some View {
        NavigationLink(value: store) {
            HStack(alignment: .top, spacing: AppSpacing.md) {
                AppImageView(source: store.imageUrl)
                    .frame(width: 104, height: 112)
                    .clipShape(RoundedRectangle(cornerRadius: AppRadius.md))
                    .overlay(
                        RoundedRectangle(cornerRadius: AppRadius.md)
                            .stroke(Color.white.opacity(0.7), lineWidth: 1)
                    )

                VStack(alignment: .leading, spacing: 8) {
                    HStack(spacing: 6) {
                        Label(store.category.rawValue, systemImage: store.category.icon)
                            .font(AppFont.caption(11))
                            .foregroundStyle(Color(hex: store.category.accentColor))
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color(hex: store.category.accentColor).opacity(0.12))
                            .clipShape(Capsule())

                        Text(store.area)
                            .font(AppFont.caption(11))
                            .foregroundStyle(.appTextTertiary)
                            .lineLimit(1)
                    }

                    Text(store.name)
                        .font(AppFont.subtitle(18))
                        .foregroundStyle(.appTextPrimary)
                        .lineLimit(1)

                    Text(store.shortDescription)
                        .font(AppFont.body(13))
                        .foregroundStyle(.appTextSecondary)
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)

                    HStack(spacing: 6) {
                        ForEach(Array(store.searchTags.prefix(3)), id: \.self) { tag in
                            Text("#\(tag)")
                                .font(AppFont.caption(11))
                                .foregroundStyle(.appPrimary)
                                .lineLimit(1)
                        }
                    }

                    HStack(spacing: 4) {
                        Text("상세보기")
                            .font(AppFont.label(12))
                        Image(systemName: "chevron.right")
                            .font(.system(size: 10, weight: .bold))
                    }
                    .foregroundStyle(.appPrimary)
                }

                Spacer(minLength: 0)
            }
            .padding(AppSpacing.md)
            .background(Color.appCardBackground)
            .clipShape(RoundedRectangle(cornerRadius: AppRadius.lg))
            .overlay(
                RoundedRectangle(cornerRadius: AppRadius.lg)
                    .stroke(Color.appDivider.opacity(0.75), lineWidth: 1)
            )
            .shadow(color: Color.appPrimary.opacity(0.05), radius: 12, y: 6)
        }
        .buttonStyle(.plain)
    }

    private func storeMatchesSearch(_ store: Store) -> Bool {
        guard normalizedSearchText.isEmpty == false else { return true }
        return normalized(store.searchableText).contains(normalizedSearchText)
    }

    private func normalized(_ value: String) -> String {
        value
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .folding(options: [.caseInsensitive, .diacriticInsensitive], locale: .current)
            .lowercased()
    }

    private var progressDashboardSection: some View {
        let reward = appState.rewardProgress

        return VStack(alignment: .leading, spacing: AppSpacing.lg) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("오늘의 로컬 레벨")
                        .font(AppFont.caption(13))
                        .foregroundStyle(.white.opacity(0.85))

                    Text(appState.localExplorerLevel)
                        .font(AppFont.title(30))
                        .foregroundStyle(.white)

                    Text("연속 \(appState.dashboardStreak)일째 대전 탐험 중")
                        .font(AppFont.body(14))
                        .foregroundStyle(.white.opacity(0.86))
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 8) {
                    Image(systemName: "sparkles")
                        .font(.system(size: 20, weight: .bold))
                        .foregroundStyle(.white)

                    Text("\(reward.seasonProgress)%")
                        .font(AppFont.subtitle(20))
                        .foregroundStyle(.white)

                    Text("시즌 진행도")
                        .font(AppFont.caption(12))
                        .foregroundStyle(.white.opacity(0.8))
                }
            }

            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Text("다음 보상")
                        .font(AppFont.caption(12))
                        .foregroundStyle(.white.opacity(0.82))
                    Spacer()
                    if let nextBadge = appState.nextBadgeTarget {
                        Text(nextBadge.rawValue)
                            .font(AppFont.label(13))
                            .foregroundStyle(.white)
                    } else {
                        Text("현재 공개된 뱃지를 모두 모았어요")
                            .font(AppFont.label(13))
                            .foregroundStyle(.white)
                    }
                }

                GeometryReader { proxy in
                    ZStack(alignment: .leading) {
                        Capsule()
                            .fill(Color.white.opacity(0.18))
                            .frame(height: 10)

                        Capsule()
                            .fill(Color.white)
                            .frame(
                                width: max(24, proxy.size.width * CGFloat(reward.seasonProgress) / 100),
                                height: 10
                            )
                    }
                }
                .frame(height: 10)
            }

            HStack(spacing: AppSpacing.sm) {
                dashboardMetric(title: "완주 코스", value: "\(reward.totalCoursesCompleted)", icon: "flag.checkered")
                dashboardMetric(title: "방문 스탬프", value: "\(reward.totalVisits)", icon: "seal.fill")
                dashboardMetric(title: "저장 경로", value: "\(savedSharedCourses.count)", icon: "bookmark.fill")
                dashboardMetric(title: "획득 뱃지", value: "\(appState.earnedBadgeTypes.count)", icon: "rosette")
            }
        }
        .padding(AppSpacing.lg)
        .background(
            LinearGradient(
                colors: [Color.appPrimaryDark, Color.appPrimary, Color.appSecondary],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .clipShape(RoundedRectangle(cornerRadius: AppRadius.xl))
        .overlay(alignment: .topTrailing) {
            Circle()
                .fill(Color.white.opacity(0.1))
                .frame(width: 120, height: 120)
                .offset(x: 28, y: -24)
        }
        .padding(.horizontal, AppSpacing.md)
    }

    private var districtAndAgeSection: some View {
        VStack(spacing: AppSpacing.md) {
            VStack(alignment: .leading, spacing: AppSpacing.sm) {
                SectionHeader(
                    title: "동네 기준으로 보기",
                    subtitle: "대전 원도심 안에서 공유 경로를 좁혀봅니다"
                )

                ScrollView(.horizontal, showsIndicators: false) {
                    DistrictPicker(
                        selected: Binding(
                            get: { appState.selectedDistrict },
                            set: { appState.selectedDistrict = $0 }
                        )
                    )
                    .padding(.horizontal, AppSpacing.md)
                }
            }

            VStack(alignment: .leading, spacing: AppSpacing.sm) {
                SectionHeader(
                    title: "내 연령대 기준 추천",
                    subtitle: "비슷한 사용자들이 저장하는 경로를 먼저 보여줍니다"
                )

                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: AppSpacing.sm) {
                        ForEach(AgeGroup.allCases) { ageGroup in
                            FilterChip(
                                label: ageGroup.rawValue,
                                icon: ageGroup == appState.preferredAgeGroup ? "checkmark.circle.fill" : nil,
                                isSelected: ageGroup == appState.preferredAgeGroup
                            ) {
                                appState.updatePreferredAgeGroup(ageGroup)
                                selectedSort = .myAge
                            }
                        }
                    }
                    .padding(.horizontal, AppSpacing.md)
                }
            }
        }
    }

    private var rankingSection: some View {
        VStack(alignment: .leading, spacing: AppSpacing.md) {
            SectionHeader(
                title: "한눈에 보는 추천 랭킹",
                subtitle: "\(appState.selectedDistrict.rawValue)에서 지금 반응이 좋은 공유 경로"
            )

            if topRankedCourses.isEmpty {
                EmptyStateView(
                    icon: "map",
                    title: "조건에 맞는 공유 경로가 없어요",
                    message: "동네나 키워드를 바꾸면 다른 추천 경로가 보입니다"
                )
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: AppSpacing.md) {
                        ForEach(Array(topRankedCourses.enumerated()), id: \.element.id) { index, course in
                            NavigationLink(value: course) {
                                VStack(alignment: .leading, spacing: 14) {
                                    HStack {
                                        Text("\(index + 1)위")
                                            .font(AppFont.label(12))
                                            .foregroundStyle(.white)
                                            .padding(.horizontal, 10)
                                            .padding(.vertical, 6)
                                            .background(index == 0 ? Color.appPrimary : Color.appSecondary)
                                            .clipShape(Capsule())

                                        Spacer()

                                        Text(course.authorNickname)
                                            .font(AppFont.caption(12))
                                            .foregroundStyle(.appTextSecondary)
                                    }

                                    Text(course.title)
                                        .font(AppFont.subtitle(17))
                                        .foregroundStyle(.appTextPrimary)
                                        .multilineTextAlignment(.leading)

                                    Text(course.tags.prefix(3).map { "#\($0)" }.joined(separator: " "))
                                        .font(AppFont.caption(12))
                                        .foregroundStyle(.appTextSecondary)
                                        .lineLimit(2)

                                    Spacer()

                                    HStack(spacing: 14) {
                                        Label("\(course.likeCount + (appState.isSharedCourseLiked(course.id) ? 1 : 0))", systemImage: "heart.fill")
                                        Label("\(course.completionCount)", systemImage: "flag.checkered")
                                    }
                                    .font(AppFont.caption(12))
                                    .foregroundStyle(.appPrimary)
                                }
                                .padding(AppSpacing.md)
                                .frame(width: 210, height: 180, alignment: .topLeading)
                                .background(Color.appCardBackground)
                                .clipShape(RoundedRectangle(cornerRadius: AppRadius.lg))
                                .shadow(color: .black.opacity(0.04), radius: 8, y: 3)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.horizontal, AppSpacing.md)
                }
            }
        }
    }

    private var sharedRoutesSection: some View {
        VStack(alignment: .leading, spacing: AppSpacing.md) {
            SectionHeader(
                title: "공유 경로 광장",
                subtitle: "사용자가 만든 추천 동선을 저장하고 공유해보세요"
            )

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: AppSpacing.sm) {
                    ForEach(DashboardFeedSort.allCases) { sort in
                        FilterChip(
                            label: sort.rawValue,
                            icon: sort.icon,
                            isSelected: selectedSort == sort
                        ) {
                            selectedSort = sort
                        }
                    }
                }
                .padding(.horizontal, AppSpacing.md)
            }

            if relevantTags.isEmpty == false {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: AppSpacing.sm) {
                        FilterChip(label: "전체", isSelected: selectedTag == nil) {
                            selectedTag = nil
                        }

                        ForEach(relevantTags, id: \.self) { tag in
                            FilterChip(
                                label: tag,
                                icon: selectedTag == tag ? "tag.fill" : "tag",
                                isSelected: selectedTag == tag
                            ) {
                                selectedTag = selectedTag == tag ? nil : tag
                            }
                        }
                    }
                    .padding(.horizontal, AppSpacing.md)
                }
            }

            if let spotlightCourse {
                VStack(alignment: .leading, spacing: AppSpacing.md) {
                    HStack {
                        Text(selectedSort == .myAge ? "내 연령대 추천 1순위" : "지금 가장 저장되는 경로")
                            .font(AppFont.label(15))
                            .foregroundStyle(.appTextPrimary)
                        Spacer()
                        Text("\(publicSharedCourses.count)개 노출")
                            .font(AppFont.caption(12))
                            .foregroundStyle(.appTextTertiary)
                    }
                    .padding(.horizontal, AppSpacing.md)

                    SharedCourseCard(course: spotlightCourse, rank: 1)
                        .padding(.horizontal, AppSpacing.md)
                }
            }

            VStack(spacing: AppSpacing.md) {
                ForEach(Array(publicSharedCourses.dropFirst()), id: \.id) { course in
                    SharedCourseCard(course: course)
                        .padding(.horizontal, AppSpacing.md)
                }
            }

            if publicSharedCourses.isEmpty {
                EmptyStateView(
                    icon: "person.3.fill",
                    title: "공유 중인 추천 경로가 없어요",
                    message: "필터를 바꾸면 다른 대전 로컬 경로를 볼 수 있습니다"
                )
            }
        }
    }

    private var savedSharedRoutesSection: some View {
        VStack(alignment: .leading, spacing: AppSpacing.md) {
            SectionHeader(
                title: "내가 찜한 공유 경로",
                subtitle: "다음 탐방 때 바로 열 수 있는 저장 리스트"
            )

            if savedSharedCourses.isEmpty {
                VStack(alignment: .leading, spacing: 10) {
                    Text("아직 저장한 공유 경로가 없어요")
                        .font(AppFont.subtitle(17))
                        .foregroundStyle(.appTextPrimary)

                    Text("마음에 드는 유저 코스를 저장하면 홈에서 바로 이어볼 수 있습니다.")
                        .font(AppFont.body(14))
                        .foregroundStyle(.appTextSecondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(AppSpacing.lg)
                .background(Color.appCardBackground)
                .clipShape(RoundedRectangle(cornerRadius: AppRadius.lg))
                .padding(.horizontal, AppSpacing.md)
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: AppSpacing.md) {
                        ForEach(savedSharedCourses) { course in
                            SharedCourseCard(course: course)
                                .frame(width: 320)
                        }
                    }
                    .padding(.horizontal, AppSpacing.md)
                }
            }
        }
    }

    private var badgeShelfSection: some View {
        VStack(alignment: .leading, spacing: AppSpacing.md) {
            SectionHeader(
                title: "완주 보상 진열장",
                subtitle: "뱃지와 시즌 미션이 탐방 동기를 만듭니다"
            )

            VStack(alignment: .leading, spacing: AppSpacing.md) {
                if appState.earnedBadgeTypes.isEmpty {
                    Text("첫 코스를 완주하면 뱃지가 열립니다.")
                        .font(AppFont.body(14))
                        .foregroundStyle(.appTextSecondary)
                } else {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 10) {
                            ForEach(appState.earnedBadgeTypes, id: \.self) { badge in
                                badgePill(badge)
                            }
                        }
                    }
                }

                if let nextBadge = appState.nextBadgeTarget {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("다음 목표")
                            .font(AppFont.caption(12))
                            .foregroundStyle(.appTextTertiary)
                        Text(nextBadge.rawValue)
                            .font(AppFont.subtitle(18))
                            .foregroundStyle(.appTextPrimary)
                        Text(nextBadge.description)
                            .font(AppFont.body(13))
                            .foregroundStyle(.appTextSecondary)
                    }
                }
            }
            .padding(AppSpacing.md)
            .background(Color.appCardBackground)
            .clipShape(RoundedRectangle(cornerRadius: AppRadius.lg))
            .padding(.horizontal, AppSpacing.md)
        }
    }

    private var editorRoutesSection: some View {
        VStack(alignment: .leading, spacing: AppSpacing.md) {
            SectionHeader(
                title: "에디터 검증 코스",
                subtitle: "공유 경로와 함께 비교해서 고를 수 있는 기본 루트"
            )

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: AppSpacing.md) {
                    ForEach(editorCourses) { course in
                        CourseCard(course: course, style: .standard)
                            .frame(width: 260)
                    }
                }
                .padding(.horizontal, AppSpacing.md)
            }
        }
    }

    private var storeSpotlightSection: some View {
        VStack(alignment: .leading, spacing: AppSpacing.md) {
            SectionHeader(
                title: "같이 뜨는 실제 가게",
                subtitle: "공유 경로에 자주 엮이는 \(appState.selectedDistrict.rawValue) 로컬 스팟"
            )

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: AppSpacing.md) {
                    ForEach(nearbyStores.prefix(5)) { store in
                        StoreCard(store: store, style: .featured)
                            .frame(width: 290)
                    }
                }
                .padding(.horizontal, AppSpacing.md)
            }
        }
    }

    private func dashboardMetric(title: String, value: String, icon: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(.white.opacity(0.88))
            Text(value)
                .font(AppFont.subtitle(19))
                .foregroundStyle(.white)
            Text(title)
                .font(AppFont.caption(11))
                .foregroundStyle(.white.opacity(0.8))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.vertical, 12)
        .padding(.horizontal, 10)
        .background(Color.white.opacity(0.12))
        .clipShape(RoundedRectangle(cornerRadius: AppRadius.md))
    }

    private func badgePill(_ badge: BadgeType) -> some View {
        HStack(spacing: 8) {
            Image(systemName: badge.icon)
                .font(.system(size: 13, weight: .bold))
                .foregroundStyle(.appPrimary)
            Text(badge.rawValue)
                .font(AppFont.label(13))
                .foregroundStyle(.appTextPrimary)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(Color.appSurfaceDim)
        .clipShape(Capsule())
    }

    private func popularityScore(for course: UserGeneratedCourse) -> Int {
        course.likeCount * 3 + course.completionCount * 4 + course.viewCount
    }

    private func coursePriorityForAge(_ course: UserGeneratedCourse) -> Int {
        let ageBonus = course.authorAgeGroup == appState.preferredAgeGroup ? 10_000 : 0
        return popularityScore(for: course) + ageBonus
    }

    private func festivalPriority(for course: UserGeneratedCourse) -> Int {
        let bonus = course.tags.contains { $0.contains("축제") || $0 == "타슈" } ? 10_000 : 0
        return popularityScore(for: course) + bonus
    }
}

private extension Store {
    var searchTags: [String] {
        let categoryAliases: [String]
        switch category {
        case .restaurant:
            categoryAliases = ["맛집", "먹거리", "식당"]
        case .cafe:
            categoryAliases = ["카페", "커피", "디저트"]
        case .attraction:
            categoryAliases = ["관광지", "명소", "놀거리"]
        case .festival:
            categoryAliases = ["축제", "행사", "공연"]
        case .date:
            categoryAliases = ["데이트", "커플", "야간명소"]
        case .family:
            categoryAliases = ["가족", "아이와", "테마파크"]
        case .experience:
            categoryAliases = ["체험", "온천", "족욕"]
        case .nightSpot:
            categoryAliases = ["야간명소", "밤", "야경"]
        case .bar:
            categoryAliases = ["술집", "감성술집", "야간명소"]
        case .shop:
            categoryAliases = ["소품샵", "쇼핑", "편집숍"]
        case .workshop:
            categoryAliases = ["공방", "체험", "클래스"]
        case .culture:
            categoryAliases = ["문화", "전시", "복합문화공간"]
        case .walkSpot:
            categoryAliases = ["산책", "관광지", "걷기"]
        }

        let fallbackTags = [
            category.rawValue,
            district.rawValue,
            address,
            name
        ]

        var seen = Set<String>()
        return (tags + categoryAliases + fallbackTags)
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { tag in
                guard tag.isEmpty == false, seen.contains(tag) == false else { return false }
                seen.insert(tag)
                return true
            }
    }

    var searchableText: String {
        ([
            name,
            category.rawValue,
            district.rawValue,
            address,
            shortDescription,
            storyTitle,
            signaturePoint,
            visitTip
        ] + searchTags + menuItems.map(\.name))
        .joined(separator: " ")
    }
}
