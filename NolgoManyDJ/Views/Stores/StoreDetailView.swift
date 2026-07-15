import SwiftUI
import MapKit

// MARK: - Store Detail View (콘텐츠형 스토리 중심 상세 페이지)
struct StoreDetailView: View {
    let store: Store
    @Environment(AppState.self) private var appState
    @State private var showFullStory = false
    @State private var kakaoImageService = KakaoImageService.shared
    @State private var isLoadingImages = true

    private var kakaoImages: [KakaoImageService.KakaoImage] {
        kakaoImageService.images(for: store)
    }

    private var resolvedCoverURL: String {
        if store.coverImageURL.assetImageName != nil { return store.coverImageURL }
        return kakaoImageService.coverImageURL(for: store) ?? store.coverImageURL
    }

    private var storeImages: [StoreImage] {
        MockData.images(forStore: store.id)
    }

    private var relatedCourses: [Course] {
        MockData.courses.filter { course in
            course.stops.contains { $0.storeId == store.id }
        }
    }

    var body: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(spacing: 0) {
                // 1. Hero 커버 이미지
                storeHero

                // 2. 가게 기본 정보 바
                storeQuickInfo

                // 3. 한 줄 소개
                shortDescriptionSection

                // 4. 창업 히스토리 (핵심!)
                founderStorySection

                // 5. 이 가게만의 차별점
                signatureSection

                // 6. 메뉴/서비스
                menuSection

                // 7. 공간 갤러리
                gallerySection

                // 8. 방문 팁
                visitTipSection

                // 9. 기본 정보 (주소/전화/영업시간)
                storeInfoSection

                // 10. 지도
                mapSection

                // 11. 관련 코스
                relatedCoursesSection

                // 12. 하단 액션 바
                actionBar

                Spacer(minLength: AppSpacing.xxl)
            }
        }
        .background(Color.appBackground)
        .navigationBarTitleDisplayMode(.inline)
        .task {
            if store.coverImageURL.assetImageName == nil {
                await kakaoImageService.loadImages(for: store)
            }
            isLoadingImages = false
        }
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                HStack(spacing: AppSpacing.sm) {
                    ShareLink(item: "놀거많은대?전 - \(store.name)") {
                        Image(systemName: "square.and.arrow.up")
                            .font(.system(size: 16))
                            .foregroundStyle(.appTextSecondary)
                    }
                    SaveButton(
                        isSaved: appState.isStoreSaved(store.id),
                        action: { appState.toggleSaveStore(store.id) }
                    )
                }
            }
        }
    }

    // MARK: - 1. Hero
    private var storeHero: some View {
        ZStack(alignment: .bottomLeading) {
            AppImageView(source: resolvedCoverURL)
            .frame(height: 280)
            .clipped()

            // Gradient
            LinearGradient(
                colors: [.clear, .clear, .black.opacity(0.8)],
                startPoint: .top,
                endPoint: .bottom
            )

            // 가게 정보 오버레이
            VStack(alignment: .leading, spacing: AppSpacing.sm) {
                // 카테고리 뱃지
                HStack(spacing: 6) {
                    Image(systemName: store.category.icon)
                        .font(.system(size: 12))
                    Text(store.category.rawValue)
                        .font(AppFont.caption(12))
                    Text("·")
                    Text(store.district.rawValue)
                        .font(AppFont.caption(12))
                }
                .foregroundStyle(.white.opacity(0.9))
                .padding(.horizontal, 10)
                .padding(.vertical, 5)
                .background(.white.opacity(0.15))
                .clipShape(Capsule())

                // 가게명
                Text(store.name)
                    .font(AppFont.title(28))
                    .foregroundStyle(.white)
                    .lineLimit(2)
                    .minimumScaleFactor(0.82)
                    .frame(maxWidth: .infinity, alignment: .leading)

                // 스토리 타이틀
                Text("「\(store.storyTitle)」")
                    .font(AppFont.storyQuote(16))
                    .foregroundStyle(.white.opacity(0.85))
                    .italic()
                    .lineLimit(2)
                    .minimumScaleFactor(0.9)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding(AppSpacing.lg)
            .padding(.bottom, AppSpacing.sm)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    // MARK: - 2. Quick Info
    private var storeQuickInfo: some View {
        ViewThatFits(in: .horizontal) {
            HStack(spacing: 0) {
                quickInfoItem(icon: "clock", text: "영업중")
                Divider().frame(height: 36)
                quickInfoItem(icon: "location", text: store.district.rawValue)
                Divider().frame(height: 36)
                quickInfoItem(icon: "star.fill", text: "추천")
            }
            .padding(.vertical, AppSpacing.md)
            .background(Color.appCardBackground)

            VStack(spacing: 0) {
                quickInfoItem(icon: "clock", text: "영업중")
                    .padding(.vertical, AppSpacing.sm)
                Divider()
                quickInfoItem(icon: "location", text: store.district.rawValue)
                    .padding(.vertical, AppSpacing.sm)
                Divider()
                quickInfoItem(icon: "star.fill", text: "추천")
                    .padding(.vertical, AppSpacing.sm)
            }
            .background(Color.appCardBackground)
        }
    }

    private func quickInfoItem(icon: String, text: String) -> some View {
        HStack(spacing: 4) {
            Image(systemName: icon)
                .font(.system(size: 12))
                .foregroundStyle(.appPrimary)
            Text(text)
                .font(AppFont.label(13))
                .foregroundStyle(.appTextPrimary)
                .lineLimit(1)
                .minimumScaleFactor(0.85)
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - 3. Short Description
    private var shortDescriptionSection: some View {
        Text(store.shortDescription)
            .font(AppFont.body(15))
            .foregroundStyle(.appTextSecondary)
            .lineSpacing(6)
            .padding(.horizontal, AppSpacing.lg)
            .padding(.vertical, AppSpacing.lg)
    }

    // MARK: - 4. Founder Story (가장 중요한 섹션!)
    private var founderStorySection: some View {
        VStack(alignment: .leading, spacing: AppSpacing.md) {
            // 인터뷰형 제목
            HStack(spacing: AppSpacing.sm) {
                Rectangle()
                    .fill(Color.appPrimary)
                    .frame(width: 3, height: 24)
                Text("왜 이 가게를 시작했나요?")
                    .font(AppFont.heading(18))
                    .foregroundStyle(.appTextPrimary)
            }

            // 스토리 본문
            VStack(alignment: .leading, spacing: AppSpacing.md) {
                Text(store.founderStory)
                    .font(AppFont.storyQuote(15))
                    .foregroundStyle(.appTextPrimary)
                    .lineSpacing(8)
                    .lineLimit(showFullStory ? nil : 6)

                if store.founderStory.count > 200 {
                    Button {
                        withAnimation { showFullStory.toggle() }
                    } label: {
                        Text(showFullStory ? "접기" : "이야기 더 보기")
                            .font(AppFont.label(14))
                            .foregroundStyle(.appPrimary)
                    }
                }
            }
            .padding(AppSpacing.lg)
            .background(
                RoundedRectangle(cornerRadius: AppRadius.lg)
                    .fill(Color.appSurfaceDim.opacity(0.5))
            )
        }
        .padding(.horizontal, AppSpacing.lg)
        .padding(.vertical, AppSpacing.sm)
    }

    // MARK: - 5. Signature Point
    private var signatureSection: some View {
        VStack(alignment: .leading, spacing: AppSpacing.md) {
            HStack(spacing: AppSpacing.sm) {
                Image(systemName: "sparkles")
                    .foregroundStyle(.appAccent)
                Text("이 가게만의 특별함")
                    .font(AppFont.heading(18))
                    .foregroundStyle(.appTextPrimary)
            }

            Text(store.signaturePoint)
                .font(AppFont.body(15))
                .foregroundStyle(.appTextSecondary)
                .lineSpacing(6)
        }
        .padding(.horizontal, AppSpacing.lg)
        .padding(.vertical, AppSpacing.lg)
    }

    // MARK: - 6. Menu
    private var menuSection: some View {
        VStack(alignment: .leading, spacing: AppSpacing.md) {
            HStack(spacing: AppSpacing.sm) {
                Image(systemName: "menucard")
                    .foregroundStyle(.appPrimary)
                Text("메뉴 / 서비스")
                    .font(AppFont.heading(18))
                    .foregroundStyle(.appTextPrimary)
            }

            VStack(spacing: 0) {
                ForEach(store.menuItems) { item in
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            HStack(spacing: 4) {
                                if item.isSignature {
                                    Text("BEST")
                                        .font(AppFont.caption(9))
                                        .foregroundStyle(.white)
                                        .padding(.horizontal, 5)
                                        .padding(.vertical, 2)
                                        .background(Color.appPrimary)
                                        .clipShape(RoundedRectangle(cornerRadius: 3))
                                }
                                Text(item.name)
                                    .font(AppFont.body(15))
                                    .foregroundStyle(.appTextPrimary)
                                    .lineLimit(2)
                            }
                        }
                        Spacer()
                        Text(item.price)
                            .font(AppFont.label(14))
                            .foregroundStyle(.appTextSecondary)
                    }
                    .padding(.vertical, AppSpacing.sm)

                    if item.id != store.menuItems.last?.id {
                        Divider()
                    }
                }
            }
            .padding(AppSpacing.md)
            .background(Color.appCardBackground)
            .clipShape(RoundedRectangle(cornerRadius: AppRadius.md))
            .shadow(color: .black.opacity(0.04), radius: 4, y: 2)
        }
        .padding(.horizontal, AppSpacing.lg)
    }

    // MARK: - 7. Gallery
    private var gallerySection: some View {
        let kakaoGallery = store.coverImageURL.assetImageName == nil ? kakaoImageService.galleryImages(for: store) : []
        let hasKakaoGallery = !kakaoGallery.isEmpty

        return VStack(alignment: .leading, spacing: AppSpacing.md) {
            HStack(spacing: AppSpacing.sm) {
                Image(systemName: "photo.on.rectangle.angled")
                    .foregroundStyle(.appSecondary)
                Text("공간 둘러보기")
                    .font(AppFont.heading(18))
                    .foregroundStyle(.appTextPrimary)
            }
            .padding(.horizontal, AppSpacing.lg)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: AppSpacing.sm) {
                    if hasKakaoGallery {
                        ForEach(kakaoGallery) { image in
                            AppImageView(source: image.imageURL)
                            .frame(width: 200, height: 150)
                            .clipShape(RoundedRectangle(cornerRadius: AppRadius.md))
                        }
                    } else {
                        ForEach(storeImages) { image in
                            VStack(alignment: .leading, spacing: 4) {
                                AppImageView(source: image.imageURL)
                                .frame(width: 200, height: 150)
                                .clipShape(RoundedRectangle(cornerRadius: AppRadius.md))

                                if let caption = image.caption {
                                    Text(caption)
                                        .font(AppFont.caption(11))
                                        .foregroundStyle(.appTextTertiary)
                                }
                            }
                        }
                    }
                }
                .padding(.horizontal, AppSpacing.lg)
            }
        }
        .padding(.vertical, AppSpacing.lg)
    }

    // MARK: - 8. Visit Tip
    private var visitTipSection: some View {
        HStack(alignment: .top, spacing: AppSpacing.md) {
            Image(systemName: "lightbulb.fill")
                .foregroundStyle(.appAccent)
                .font(.system(size: 20))

            VStack(alignment: .leading, spacing: 4) {
                Text("방문 팁")
                    .font(AppFont.label(14))
                    .foregroundStyle(.appTextPrimary)
                Text(store.visitTip)
                    .font(AppFont.body(14))
                    .foregroundStyle(.appTextSecondary)
                    .lineSpacing(4)
            }
        }
        .padding(AppSpacing.lg)
        .background(Color.appAccent.opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: AppRadius.lg))
        .padding(.horizontal, AppSpacing.lg)
    }

    // MARK: - 9. Store Info
    private var storeInfoSection: some View {
        VStack(alignment: .leading, spacing: AppSpacing.md) {
            Text("가게 정보")
                .font(AppFont.heading(18))
                .foregroundStyle(.appTextPrimary)

            VStack(spacing: AppSpacing.md) {
                infoRow(icon: "mappin.and.ellipse", label: "주소", value: store.address)
                infoRow(icon: "phone.fill", label: "전화", value: store.phone)
                infoRow(icon: "clock.fill", label: "영업시간", value: store.openingHours)

                if let instagram = store.instagramURL {
                    infoRow(icon: "camera.fill", label: "인스타그램", value: instagram)
                }

                if let website = store.websiteURL {
                    infoRow(icon: "globe", label: "웹사이트", value: website)
                }
            }
            .padding(AppSpacing.md)
            .background(Color.appCardBackground)
            .clipShape(RoundedRectangle(cornerRadius: AppRadius.md))
            .shadow(color: .black.opacity(0.04), radius: 4, y: 2)
        }
        .padding(.horizontal, AppSpacing.lg)
        .padding(.vertical, AppSpacing.lg)
    }

    private func infoRow(icon: String, label: String, value: String) -> some View {
        HStack(alignment: .top, spacing: AppSpacing.md) {
            Image(systemName: icon)
                .font(.system(size: 14))
                .foregroundStyle(.appPrimary)
                .frame(width: 20)
            VStack(alignment: .leading, spacing: 2) {
                Text(label)
                    .font(AppFont.caption(11))
                    .foregroundStyle(.appTextTertiary)
                Text(value)
                    .font(AppFont.body(14))
                    .foregroundStyle(.appTextPrimary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer()
        }
    }

    // MARK: - 10. Map
    private var mapSection: some View {
        Map {
            Annotation(store.name, coordinate: store.coordinate) {
                Image(systemName: store.category.icon)
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(.white)
                    .frame(width: 32, height: 32)
                    .background(Circle().fill(Color.appPrimary))
            }
        }
        .frame(height: 180)
        .clipShape(RoundedRectangle(cornerRadius: AppRadius.lg))
        .padding(.horizontal, AppSpacing.lg)
    }

    // MARK: - 11. Related Courses
    @ViewBuilder
    private var relatedCoursesSection: some View {
        if !relatedCourses.isEmpty {
            VStack(alignment: .leading, spacing: AppSpacing.md) {
                SectionHeader(
                    title: "이 가게가 포함된 코스",
                    subtitle: "함께 둘러보면 좋아요"
                )

                VStack(spacing: AppSpacing.md) {
                    ForEach(relatedCourses) { course in
                        CourseCard(course: course, style: .standard)
                    }
                }
                .padding(.horizontal, AppSpacing.lg)
            }
            .padding(.vertical, AppSpacing.lg)
        }
    }

    // MARK: - 12. Action Bar
    private var actionBar: some View {
        ViewThatFits(in: .horizontal) {
            HStack(spacing: AppSpacing.md) {
                visitedButton
                directionsButton
            }

            VStack(spacing: AppSpacing.sm) {
                visitedButton
                directionsButton
            }
        }
        .padding(.horizontal, AppSpacing.lg)
    }

    private var visitedButton: some View {
        Button {
            appState.markVisited(store.id)
        } label: {
            Label(
                appState.isVisited(store.id) ? "방문 완료!" : "방문 완료",
                systemImage: appState.isVisited(store.id) ? "checkmark.circle.fill" : "checkmark.circle"
            )
            .font(AppFont.label(14))
            .foregroundStyle(appState.isVisited(store.id) ? .appSecondary : .appTextSecondary)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(appState.isVisited(store.id) ? Color.appSecondary.opacity(0.1) : Color.appSurfaceDim)
            .clipShape(RoundedRectangle(cornerRadius: AppRadius.md))
        }
    }

    private var directionsButton: some View {
        Button {
            openInMaps()
        } label: {
            Label("길찾기", systemImage: "arrow.triangle.turn.up.right.diamond.fill")
                .font(AppFont.label(14))
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(Color.appPrimary)
                .clipShape(RoundedRectangle(cornerRadius: AppRadius.md))
        }
    }

    // MARK: - Open in Maps
    private func openInMaps() {
        let coordinate = store.coordinate
        let placemark = MKPlacemark(coordinate: coordinate)
        let mapItem = MKMapItem(placemark: placemark)
        mapItem.name = store.name
        mapItem.openInMaps(launchOptions: [
            MKLaunchOptionsDirectionsModeKey: MKLaunchOptionsDirectionsModeWalking
        ])
    }
}
