import SwiftUI

// MARK: - App Image
extension String {
    var assetImageName: String? {
        let prefix = "asset://"
        guard hasPrefix(prefix) else { return nil }
        return String(dropFirst(prefix.count))
    }
}

struct AppImageView: View {
    let source: String
    var contentMode: ContentMode = .fill
    var placeholder: AnyShapeStyle = AnyShapeStyle(Color.appSurfaceDim)

    var body: some View {
        if let assetName = source.assetImageName {
            Image(assetName)
                .resizable()
                .aspectRatio(contentMode: contentMode)
        } else if let url = URL(string: source), !source.isEmpty {
            AsyncImage(url: url) { phase in
                switch phase {
                case .success(let image):
                    image
                        .resizable()
                        .aspectRatio(contentMode: contentMode)
                default:
                    Rectangle()
                        .fill(placeholder)
                }
            }
        } else {
            Rectangle()
                .fill(placeholder)
        }
    }
}

// MARK: - Section Header
struct SectionHeader: View {
    let title: String
    var subtitle: String? = nil
    var showMore: Bool = false
    var onMoreTap: (() -> Void)? = nil

    var body: some View {
        HStack(alignment: .bottom) {
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(AppFont.heading(20))
                    .foregroundStyle(.appTextPrimary)
                if let subtitle {
                    Text(subtitle)
                        .font(AppFont.caption(13))
                        .foregroundStyle(.appTextTertiary)
                }
            }
            Spacer()
            if showMore {
                Button(action: { onMoreTap?() }) {
                    Text("더보기")
                        .font(AppFont.caption(13))
                        .foregroundStyle(.appPrimary)
                }
            }
        }
        .padding(.horizontal, AppSpacing.md)
    }
}

// MARK: - Filter Chip
struct FilterChip: View {
    let label: String
    var icon: String? = nil
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 4) {
                if let icon {
                    Image(systemName: icon)
                        .font(.system(size: 12))
                }
                Text(label)
                    .font(AppFont.label(13))
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .background(isSelected ? Color.appPrimary : Color.appSurfaceDim)
            .foregroundStyle(isSelected ? .white : .appTextSecondary)
            .clipShape(Capsule())
        }
    }
}

// MARK: - Save Button
struct SaveButton: View {
    let isSaved: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: isSaved ? "bookmark.fill" : "bookmark")
                .font(.system(size: 18))
                .foregroundStyle(isSaved ? .appPrimary : .appTextTertiary)
                .frame(width: 40, height: 40)
                .background(Color.appCardBackground)
                .clipShape(Circle())
                .shadow(color: .black.opacity(0.08), radius: 4, y: 2)
        }
    }
}

// MARK: - Empty State
struct EmptyStateView: View {
    let icon: String
    let title: String
    let message: String

    var body: some View {
        VStack(spacing: AppSpacing.md) {
            Image(systemName: icon)
                .font(.system(size: 48))
                .foregroundStyle(.appTextTertiary)
            Text(title)
                .font(AppFont.subtitle())
                .foregroundStyle(.appTextPrimary)
            Text(message)
                .font(AppFont.body(14))
                .foregroundStyle(.appTextSecondary)
                .multilineTextAlignment(.center)
        }
        .padding(AppSpacing.xxl)
    }
}

// MARK: - District Picker
struct DistrictPicker: View {
    @Binding var selected: District

    var body: some View {
        HStack(spacing: AppSpacing.sm) {
            ForEach(District.allCases) { district in
                Button {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        selected = district
                    }
                } label: {
                    Text(district.rawValue)
                        .font(AppFont.label(14))
                        .foregroundStyle(selected == district ? .white : .appTextSecondary)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(selected == district ? Color.appPrimary : Color.appSurfaceDim)
                        .clipShape(Capsule())
                }
            }
        }
    }
}

// MARK: - Shared Course Card
struct SharedCourseCard: View {
    @Environment(AppState.self) private var appState

    let course: UserGeneratedCourse
    var rank: Int? = nil

    private var isSaved: Bool {
        appState.isCourseSaved(course.id)
    }

    private var isLiked: Bool {
        appState.isSharedCourseLiked(course.id)
    }

    private var adjustedLikeCount: Int {
        course.likeCount + (isLiked ? 1 : 0)
    }

    private var accentColor: Color {
        switch course.theme {
        case .date: return .appPrimary
        case .solo: return .appSecondary
        case .friends: return .appAccent
        case .rainy: return .appSecondary
        case .night: return .appPrimaryDark
        case .photo: return .appAccent
        case .food: return .appPrimary
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.md) {
            NavigationLink(value: course) {
                VStack(alignment: .leading, spacing: AppSpacing.md) {
                    cardCover

                    VStack(alignment: .leading, spacing: AppSpacing.sm) {
                        HStack(alignment: .top, spacing: AppSpacing.sm) {
                            VStack(alignment: .leading, spacing: 6) {
                                Text(course.title)
                                    .font(AppFont.subtitle(18))
                                    .foregroundStyle(.appTextPrimary)
                                    .multilineTextAlignment(.leading)

                                Text(course.description)
                                    .font(AppFont.body(14))
                                    .foregroundStyle(.appTextSecondary)
                                    .lineLimit(2)
                            }

                            Spacer(minLength: 8)

                            Text(course.district.rawValue)
                                .font(AppFont.caption(12))
                                .foregroundStyle(.appTextTertiary)
                        }

                        HStack(spacing: 6) {
                            Label(course.theme.rawValue, systemImage: course.theme.icon)
                                .font(AppFont.caption(12))
                                .foregroundStyle(accentColor)

                            if let ageGroup = course.authorAgeGroup {
                                Text(ageGroup.rawValue)
                                    .font(AppFont.caption(12))
                                    .foregroundStyle(.appTextSecondary)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(Color.appSurfaceDim)
                                    .clipShape(Capsule())
                            }

                            Spacer()

                            Text(course.createdAt, style: .relative)
                                .font(AppFont.caption(12))
                                .foregroundStyle(.appTextTertiary)
                        }

                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 8) {
                                ForEach(course.tags.prefix(4), id: \.self) { tag in
                                    Text("#\(tag)")
                                        .font(AppFont.caption(12))
                                        .foregroundStyle(.appTextSecondary)
                                        .padding(.horizontal, 10)
                                        .padding(.vertical, 6)
                                        .background(Color.appSurfaceDim)
                                        .clipShape(Capsule())
                                }
                            }
                        }

                        ViewThatFits(in: .horizontal) {
                            HStack(spacing: 14) {
                                sharedMetaItem(icon: "figure.walk", text: "\(course.estimatedWalkingMinutes)분")
                                if let tashu = course.estimatedTashuMinutes {
                                    sharedMetaItem(icon: "bicycle", text: "\(tashu)분")
                                }
                                sharedMetaItem(icon: "heart.fill", text: "\(adjustedLikeCount)")
                                sharedMetaItem(icon: "checkmark.seal.fill", text: "\(course.completionCount)")
                            }

                            VStack(alignment: .leading, spacing: 6) {
                                HStack(spacing: 14) {
                                    sharedMetaItem(icon: "figure.walk", text: "\(course.estimatedWalkingMinutes)분")
                                    if let tashu = course.estimatedTashuMinutes {
                                        sharedMetaItem(icon: "bicycle", text: "\(tashu)분")
                                    }
                                }
                                HStack(spacing: 14) {
                                    sharedMetaItem(icon: "heart.fill", text: "\(adjustedLikeCount)")
                                    sharedMetaItem(icon: "checkmark.seal.fill", text: "\(course.completionCount)")
                                }
                            }
                        }
                    }
                }
            }
            .buttonStyle(.plain)

            HStack(spacing: 10) {
                sharedActionButton(
                    title: "좋아요",
                    systemImage: isLiked ? "heart.fill" : "heart",
                    tint: isLiked ? .appPrimary : .appTextSecondary
                ) {
                    appState.toggleLikeSharedCourse(course.id)
                }

                sharedActionButton(
                    title: "저장",
                    systemImage: isSaved ? "bookmark.fill" : "bookmark",
                    tint: isSaved ? .appPrimary : .appTextSecondary
                ) {
                    appState.toggleSaveCourse(course.id)
                }

                ShareLink(item: shareMessage) {
                    Label("공유", systemImage: "square.and.arrow.up")
                        .font(AppFont.label(13))
                        .foregroundStyle(.appTextSecondary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(Color.appSurfaceDim)
                        .clipShape(Capsule())
                }
                .buttonStyle(.plain)
            }
        }
        .padding(AppSpacing.md)
        .background(Color.appCardBackground)
        .clipShape(RoundedRectangle(cornerRadius: AppRadius.lg))
        .shadow(color: .black.opacity(0.06), radius: 10, y: 4)
    }

    private var cardCover: some View {
        ZStack(alignment: .topLeading) {
            AppImageView(
                source: course.coverImageURL ?? "",
                placeholder: AnyShapeStyle(
                    LinearGradient(
                        colors: [accentColor.opacity(0.8), Color.appSecondary.opacity(0.6)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
            )
            .overlay {
                if course.coverImageURL == nil {
                    Image(systemName: course.theme.icon)
                        .font(.system(size: 28))
                        .foregroundStyle(.white.opacity(0.9))
                }
            }
            .frame(height: 180)
            .frame(maxWidth: .infinity)
            .clipped()
            .clipShape(RoundedRectangle(cornerRadius: AppRadius.md))

            HStack(spacing: 8) {
                if let rank {
                    Text("\(rank)위")
                        .font(AppFont.label(12))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(Color.black.opacity(0.32))
                        .clipShape(Capsule())
                }

                Text(course.authorNickname)
                    .font(AppFont.label(12))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(accentColor.opacity(0.92))
                    .clipShape(Capsule())
            }
            .padding(AppSpacing.sm)
        }
    }

    private var shareMessage: String {
        """
        \(course.authorNickname)님이 공유한 대전 추천 경로
        \(course.title)
        \(course.description)
        """
    }

    private func sharedMetaItem(icon: String, text: String) -> some View {
        Label(text, systemImage: icon)
            .font(AppFont.caption(12))
            .foregroundStyle(.appTextSecondary)
    }

    private func sharedActionButton(
        title: String,
        systemImage: String,
        tint: Color,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            Label(title, systemImage: systemImage)
                .font(AppFont.label(13))
                .foregroundStyle(tint)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(Color.appSurfaceDim)
                .clipShape(Capsule())
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Shared Course Detail
struct SharedCourseDetailView: View {
    @Environment(AppState.self) private var appState

    let course: UserGeneratedCourse

    private let statGrid = [
        GridItem(.flexible(), spacing: AppSpacing.sm),
        GridItem(.flexible(), spacing: AppSpacing.sm)
    ]

    private var linkedStops: [(stop: UserCourseStop, store: Store?)] {
        MockData.storesForUserCourse(course)
    }

    private var isSaved: Bool {
        appState.isCourseSaved(course.id)
    }

    private var isLiked: Bool {
        appState.isSharedCourseLiked(course.id)
    }

    private var visibleLikeCount: Int {
        course.likeCount + (isLiked ? 1 : 0)
    }

    var body: some View {
        GeometryReader { proxy in
            ScrollView(.vertical, showsIndicators: false) {
                VStack(alignment: .leading, spacing: AppSpacing.lg) {
                    coverSection(topInset: proxy.safeAreaInsets.top)
                    summarySection(contentWidth: proxy.size.width)
                    actionsSection(contentWidth: proxy.size.width)
                    routeSection(contentWidth: proxy.size.width)
                    badgeHintSection(contentWidth: proxy.size.width)
                }
                .frame(width: proxy.size.width, alignment: .topLeading)
                .clipped()
                .padding(.bottom, AppSpacing.xxl)
            }
        }
        .background(Color.appBackground)
        .navigationTitle("")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(.hidden, for: .navigationBar)
    }

    private func coverSection(topInset: CGFloat) -> some View {
        ZStack(alignment: .bottomLeading) {
            AppImageView(
                source: course.coverImageURL ?? "",
                placeholder: AnyShapeStyle(
                    LinearGradient(
                        colors: [Color.appPrimary.opacity(0.9), Color.appSecondary.opacity(0.65)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
            )
            .frame(height: 320)
            .frame(maxWidth: .infinity)
            .clipped()

            LinearGradient(
                colors: [.clear, .black.opacity(0.6)],
                startPoint: .top,
                endPoint: .bottom
            )

            VStack(alignment: .leading, spacing: AppSpacing.sm) {
                HStack(spacing: 8) {
                    Text(course.district.rawValue)
                    Text(course.theme.rawValue)
                    if let ageGroup = course.authorAgeGroup {
                        Text(ageGroup.rawValue)
                }
            }
            .font(AppFont.caption(12))
            .foregroundStyle(.white.opacity(0.92))
            .lineLimit(1)

                Text(course.title)
                    .font(AppFont.title(24))
                    .foregroundStyle(.white)
                    .lineLimit(3)
                    .minimumScaleFactor(0.76)
                    .multilineTextAlignment(.leading)
                    .fixedSize(horizontal: false, vertical: true)

                Text("\(course.authorNickname)님이 만든 공유 경로")
                    .font(AppFont.body(14))
                    .foregroundStyle(.white.opacity(0.86))
                    .lineLimit(1)
            }
            .padding(.horizontal, AppSpacing.lg)
            .padding(.bottom, AppSpacing.lg)
            .padding(.top, max(topInset, 20) + 56)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .frame(maxWidth: .infinity)
    }

    private func summarySection(contentWidth: CGFloat) -> some View {
        VStack(alignment: .leading, spacing: AppSpacing.md) {
            Text(course.description)
                .font(AppFont.body(16))
                .foregroundStyle(.appTextPrimary)
                .lineSpacing(5)
                .fixedSize(horizontal: false, vertical: true)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(course.tags, id: \.self) { tag in
                        Text("#\(tag)")
                            .font(AppFont.caption(12))
                            .foregroundStyle(.appTextSecondary)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 6)
                            .background(Color.appSurfaceDim)
                            .clipShape(Capsule())
                    }
                }
            }

            LazyVGrid(columns: statGrid, alignment: .leading, spacing: AppSpacing.sm) {
                detailStatCard(title: "좋아요", value: "\(visibleLikeCount)", icon: "heart.fill")
                detailStatCard(title: "완주", value: "\(course.completionCount)", icon: "checkmark.seal.fill")
                detailStatCard(title: "도보", value: "\(course.estimatedWalkingMinutes)분", icon: "figure.walk")
                if let tashu = course.estimatedTashuMinutes {
                    detailStatCard(title: "타슈", value: "\(tashu)분", icon: "bicycle")
                }
            }
        }
        .frame(width: contentWidth - (AppSpacing.md * 2), alignment: .leading)
        .padding(.horizontal, AppSpacing.md)
    }

    private func actionsSection(contentWidth: CGFloat) -> some View {
        ViewThatFits(in: .horizontal) {
            HStack(spacing: 12) {
                likeButton
                saveButton
                shareButton
            }

            VStack(spacing: 10) {
                likeButton
                saveButton
                shareButton
            }
        }
        .frame(width: contentWidth - (AppSpacing.md * 2), alignment: .leading)
        .padding(.horizontal, AppSpacing.md)
    }

    private func routeSection(contentWidth: CGFloat) -> some View {
        VStack(alignment: .leading, spacing: AppSpacing.md) {
            SectionHeader(
                title: "이 코스 동선",
                subtitle: "실제 가게와 연결된 공유 경로"
            )

            VStack(spacing: AppSpacing.md) {
                ForEach(Array(linkedStops.enumerated()), id: \.element.stop.id) { index, item in
                    HStack(alignment: .top, spacing: AppSpacing.md) {
                        VStack(spacing: 0) {
                            ZStack {
                                Circle()
                                    .fill(index == 0 ? Color.appPrimary : Color.appSecondary)
                                    .frame(width: 34, height: 34)
                                Text("\(index + 1)")
                                    .font(AppFont.label(13))
                                    .foregroundStyle(.white)
                            }

                            if index < linkedStops.count - 1 {
                                Rectangle()
                                    .fill(Color.appDivider)
                                    .frame(width: 2, height: 64)
                                    .padding(.top, 6)
                            }
                        }

                        VStack(alignment: .leading, spacing: 10) {
                            if let store = item.store {
                                NavigationLink(value: store) {
                                    sharedStopContent(stop: item.stop, subtitle: store.shortDescription)
                                }
                                .buttonStyle(.plain)
                            } else {
                                sharedStopContent(stop: item.stop, subtitle: "직접 추가한 장소")
                            }

                            HStack(spacing: 12) {
                                if let walking = minuteLabel(from: item.stop.walkingDurationSeconds) {
                                    Label("도보 \(walking)", systemImage: "figure.walk")
                                        .font(AppFont.caption(12))
                                        .foregroundStyle(.appTextSecondary)
                                }
                                if let tashu = minuteLabel(from: item.stop.tashuDurationSeconds) {
                                    Label("타슈 \(tashu)", systemImage: "bicycle")
                                        .font(AppFont.caption(12))
                                        .foregroundStyle(.appPrimary)
                                }
                            }
                        }
                        Spacer()
                    }
                    .padding(AppSpacing.md)
                    .background(Color.appCardBackground)
                    .clipShape(RoundedRectangle(cornerRadius: AppRadius.lg))
                    .padding(.horizontal, AppSpacing.md)
                }
            }
        }
        .frame(width: contentWidth, alignment: .leading)
    }

    private func badgeHintSection(contentWidth: CGFloat) -> some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            SectionHeader(
                title: "완주 보상 힌트",
                subtitle: "지역 키워드가 보상과 연결됩니다"
            )

            VStack(alignment: .leading, spacing: 10) {
                Text("이 경로를 저장하거나 완주하면 시즌 진행도가 올라갑니다.")
                    .font(AppFont.body(14))
                    .foregroundStyle(.appTextSecondary)

                if let matchedBadge = badgeHint {
                    Label(matchedBadge.rawValue, systemImage: matchedBadge.icon)
                        .font(AppFont.label(14))
                        .foregroundStyle(.appPrimary)
                } else {
                    Text("대전 로컬 뱃지는 방문 기록이 쌓일수록 자동으로 열립니다.")
                        .font(AppFont.caption(13))
                        .foregroundStyle(.appTextTertiary)
                }
            }
            .padding(AppSpacing.md)
            .background(Color.appCardBackground)
            .clipShape(RoundedRectangle(cornerRadius: AppRadius.lg))
            .padding(.horizontal, AppSpacing.md)
        }
        .frame(width: contentWidth, alignment: .leading)
    }

    private var badgeHint: BadgeType? {
        if course.tags.contains("빵축제") { return .breadFestival2026 }
        if course.tags.contains("벚꽃축제") { return .cherryBlossom2026 }
        if course.theme == .night { return .nightOwl }
        if course.theme == .food { return .foodHunter }
        return nil
    }

    private var shareMessage: String {
        """
        대전 공유 경로
        \(course.title)
        \(course.description)
        """
    }

    private func detailStatCard(title: String, value: String, icon: String) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Image(systemName: icon)
                .font(.system(size: 16))
                .foregroundStyle(.appPrimary)
            Text(value)
                .font(AppFont.subtitle(18))
                .foregroundStyle(.appTextPrimary)
            Text(title)
                .font(AppFont.caption(12))
                .foregroundStyle(.appTextTertiary)
        }
        .frame(maxWidth: .infinity, minHeight: 92, alignment: .leading)
        .padding(AppSpacing.md)
        .background(Color.appCardBackground)
        .clipShape(RoundedRectangle(cornerRadius: AppRadius.md))
    }

    private var likeButton: some View {
        actionPill(
            title: isLiked ? "좋아요 완료" : "좋아요",
            icon: isLiked ? "heart.fill" : "heart",
            tint: isLiked ? .white : .appPrimary,
            background: isLiked ? .appPrimary : .appPrimary.opacity(0.12)
        ) {
            appState.toggleLikeSharedCourse(course.id)
        }
    }

    private var saveButton: some View {
        actionPill(
            title: isSaved ? "저장됨" : "저장",
            icon: isSaved ? "bookmark.fill" : "bookmark",
            tint: isSaved ? .white : .appTextPrimary,
            background: isSaved ? .appSecondary : .appSurfaceDim
        ) {
            appState.toggleSaveCourse(course.id)
        }
    }

    private var shareButton: some View {
        ShareLink(item: shareMessage) {
            Label("공유", systemImage: "square.and.arrow.up")
                .font(AppFont.label(14))
                .foregroundStyle(.appTextPrimary)
                .lineLimit(1)
                .minimumScaleFactor(0.85)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(Color.appSurfaceDim)
                .clipShape(Capsule())
        }
        .buttonStyle(.plain)
    }

    private func actionPill(
        title: String,
        icon: String,
        tint: Color,
        background: Color,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            Label(title, systemImage: icon)
                .font(AppFont.label(14))
                .foregroundStyle(tint)
                .lineLimit(1)
                .minimumScaleFactor(0.82)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(background)
                .clipShape(Capsule())
        }
        .buttonStyle(.plain)
    }

    private func sharedStopContent(stop: UserCourseStop, subtitle: String) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(stop.placeName)
                .font(AppFont.subtitle(17))
                .foregroundStyle(.appTextPrimary)
                .multilineTextAlignment(.leading)

            Text(subtitle)
                .font(AppFont.body(13))
                .foregroundStyle(.appTextSecondary)
                .lineLimit(2)

            Text("체류 \(stop.stayMinutes)분")
                .font(AppFont.caption(12))
                .foregroundStyle(.appTextTertiary)

            if let note = stop.note {
                Text(note)
                    .font(AppFont.caption(12))
                    .foregroundStyle(.appPrimary)
            }
        }
    }

    private func minuteLabel(from seconds: Double?) -> String? {
        guard let seconds, seconds > 0 else { return nil }
        let minutes = max(1, Int(seconds / 60))
        return "\(minutes)분"
    }
}
