import SwiftUI

// MARK: - Store Card (홈, 코스 등에서 재사용)
struct StoreCard: View {
    let store: Store
    var style: CardStyle = .standard
    @State private var kakaoImageService = KakaoImageService.shared

    private var resolvedThumbnailURL: String {
        if store.thumbnailURL.assetImageName != nil { return store.thumbnailURL }
        return kakaoImageService.thumbnailURL(for: store) ?? store.thumbnailURL
    }

    private var resolvedCoverURL: String {
        if store.coverImageURL.assetImageName != nil { return store.coverImageURL }
        return kakaoImageService.coverImageURL(for: store) ?? store.coverImageURL
    }

    enum CardStyle {
        case standard   // 세로형 카드
        case compact    // 가로형 소형 카드
        case featured   // 큰 피처드 카드
    }

    var body: some View {
        NavigationLink(value: store) {
            switch style {
            case .standard:
                standardCard
            case .compact:
                compactCard
            case .featured:
                featuredCard
            }
        }
        .buttonStyle(.plain)
        .task {
            if store.coverImageURL.assetImageName == nil {
                await kakaoImageService.loadImages(for: store)
            }
        }
    }

    // MARK: - Standard Card
    private var standardCard: some View {
        VStack(alignment: .leading, spacing: 0) {
            // 이미지
            AppImageView(source: resolvedThumbnailURL)
                .aspectRatio(4/3, contentMode: .fill)
            .frame(height: 160)
            .clipped()
            .clipShape(RoundedRectangle(cornerRadius: AppRadius.md))

            VStack(alignment: .leading, spacing: AppSpacing.xs) {
                // 카테고리 + 지역
                HStack(spacing: AppSpacing.xs) {
                    Text(store.category.rawValue)
                        .font(AppFont.caption(11))
                        .foregroundStyle(Color(hex: store.category.accentColor))
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color(hex: store.category.accentColor).opacity(0.12))
                        .clipShape(Capsule())

                    Text(store.district.rawValue)
                        .font(AppFont.caption(11))
                        .foregroundStyle(.appTextTertiary)
                }

                Text(store.name)
                    .font(AppFont.subtitle(16))
                    .foregroundStyle(.appTextPrimary)
                    .lineLimit(1)

                Text(store.shortDescription)
                    .font(AppFont.caption(12))
                    .foregroundStyle(.appTextSecondary)
                    .lineLimit(2)
            }
            .padding(.top, AppSpacing.sm)
        }
        .frame(width: 200)
    }

    // MARK: - Compact Card
    private var compactCard: some View {
        HStack(spacing: AppSpacing.md) {
            AppImageView(source: resolvedThumbnailURL)
            .frame(width: 72, height: 72)
            .clipShape(RoundedRectangle(cornerRadius: AppRadius.sm))

            VStack(alignment: .leading, spacing: AppSpacing.xs) {
                HStack(spacing: AppSpacing.xs) {
                    Image(systemName: store.category.icon)
                        .font(.system(size: 10))
                        .foregroundStyle(Color(hex: store.category.accentColor))
                    Text(store.category.rawValue)
                        .font(AppFont.caption(11))
                        .foregroundStyle(.appTextTertiary)
                }

                Text(store.name)
                    .font(AppFont.label())
                    .foregroundStyle(.appTextPrimary)

                Text(store.shortDescription)
                    .font(AppFont.caption(12))
                    .foregroundStyle(.appTextSecondary)
                    .lineLimit(1)
            }

            Spacer()
        }
        .padding(AppSpacing.sm)
        .background(Color.appCardBackground)
        .clipShape(RoundedRectangle(cornerRadius: AppRadius.md))
        .shadow(color: .black.opacity(0.04), radius: 4, y: 2)
    }

    // MARK: - Featured Card
    private var featuredCard: some View {
        ZStack(alignment: .bottomLeading) {
            AppImageView(source: resolvedCoverURL)
            .frame(height: 220)
            .clipped()

            // Gradient overlay
            LinearGradient(
                colors: [.clear, .black.opacity(0.7)],
                startPoint: .top,
                endPoint: .bottom
            )

            VStack(alignment: .leading, spacing: AppSpacing.xs) {
                Text(store.category.rawValue)
                    .font(AppFont.caption(11))
                    .foregroundStyle(.white.opacity(0.8))
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(.white.opacity(0.2))
                    .clipShape(Capsule())

                Text(store.name)
                    .font(AppFont.title(22))
                    .foregroundStyle(.white)

                Text(store.storyTitle)
                    .font(AppFont.storyQuote(14))
                    .foregroundStyle(.white.opacity(0.9))
                    .lineLimit(1)
            }
            .padding(AppSpacing.md)
        }
        .clipShape(RoundedRectangle(cornerRadius: AppRadius.lg))
    }

    private var imagePlaceholder: some View { Rectangle().fill(Color.appSurfaceDim) }
}
