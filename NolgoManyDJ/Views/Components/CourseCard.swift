import SwiftUI

// MARK: - Course Card
struct CourseCard: View {
    let course: Course
    var style: CardStyle = .standard

    enum CardStyle {
        case standard
        case featured
    }

    var body: some View {
        NavigationLink(value: course) {
            switch style {
            case .standard:
                standardCard
            case .featured:
                featuredCard
            }
        }
        .buttonStyle(.plain)
    }

    // MARK: - Standard Card
    private var standardCard: some View {
        VStack(alignment: .leading, spacing: 0) {
            // 커버 이미지
            ZStack(alignment: .topTrailing) {
                AppImageView(source: course.coverImageURL)
                    .aspectRatio(16/9, contentMode: .fill)
                .frame(height: 140)
                .clipped()

                // 소요시간 뱃지
                HStack(spacing: 4) {
                    Image(systemName: "clock.fill")
                        .font(.system(size: 10))
                    Text(course.durationLabel)
                        .font(AppFont.caption(11))
                }
                .foregroundStyle(.white)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(.black.opacity(0.6))
                .clipShape(Capsule())
                .padding(8)
            }
            .clipShape(RoundedRectangle(cornerRadius: AppRadius.md))

            VStack(alignment: .leading, spacing: AppSpacing.xs) {
                // 테마 + 지역
                HStack(spacing: AppSpacing.xs) {
                    Text(course.theme.emoji)
                        .font(.system(size: 12))
                    Text(course.theme.rawValue)
                        .font(AppFont.caption(11))
                        .foregroundStyle(.appPrimary)
                    Text("·")
                        .foregroundStyle(.appTextTertiary)
                    Text(course.district.rawValue)
                        .font(AppFont.caption(11))
                        .foregroundStyle(.appTextTertiary)
                }

                Text(course.title)
                    .font(AppFont.subtitle(15))
                    .foregroundStyle(.appTextPrimary)
                    .lineLimit(2)

                HStack(spacing: AppSpacing.sm) {
                    Label("\(course.storeCount)곳", systemImage: "mappin.circle.fill")
                    Label(course.durationLabel, systemImage: "clock")
                    if let tashuDurationLabel = course.tashuDurationLabel {
                        Label(tashuDurationLabel, systemImage: "bicycle")
                    }
                }
                .font(AppFont.caption(11))
                .foregroundStyle(.appTextTertiary)

                if !course.tags.isEmpty {
                    Text(course.tags.prefix(3).map { "#\($0)" }.joined(separator: " "))
                        .font(AppFont.caption(11))
                        .foregroundStyle(.appPrimary)
                        .lineLimit(1)
                }
            }
            .padding(.top, AppSpacing.sm)
        }
    }

    // MARK: - Featured Card (큰 배너형)
    private var featuredCard: some View {
        ZStack(alignment: .bottomLeading) {
            AppImageView(source: course.coverImageURL)
            .frame(height: 240)
            .clipped()

            LinearGradient(
                colors: [.clear, .clear, .black.opacity(0.75)],
                startPoint: .top,
                endPoint: .bottom
            )

            VStack(alignment: .leading, spacing: AppSpacing.sm) {
                // 테마 뱃지
                HStack(spacing: 6) {
                    Text(course.theme.emoji)
                    Text(course.theme.rawValue)
                        .font(AppFont.caption(12))
                }
                .foregroundStyle(.white)
                .padding(.horizontal, 10)
                .padding(.vertical, 5)
                .background(.white.opacity(0.2))
                .clipShape(Capsule())

                Text(course.title)
                    .font(AppFont.title(22))
                    .foregroundStyle(.white)
                    .lineLimit(2)

                Text(course.description)
                    .font(AppFont.body(13))
                    .foregroundStyle(.white.opacity(0.85))
                    .lineLimit(2)

                HStack(spacing: AppSpacing.md) {
                    Label("\(course.storeCount)곳 방문", systemImage: "mappin.circle.fill")
                    Label(course.durationLabel, systemImage: "clock.fill")
                    if let tashuDurationLabel = course.tashuDurationLabel {
                        Label(tashuDurationLabel, systemImage: "bicycle")
                    }
                    Label(course.district.rawValue, systemImage: "location.fill")
                }
                .font(AppFont.caption(12))
                .foregroundStyle(.white.opacity(0.9))
            }
            .padding(AppSpacing.lg)
        }
        .clipShape(RoundedRectangle(cornerRadius: AppRadius.xl))
    }
}
