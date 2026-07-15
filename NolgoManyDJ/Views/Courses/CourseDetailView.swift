import SwiftUI
import MapKit

struct CourseDetailView: View {
    let course: Course
    @Environment(AppState.self) private var appState
    @State private var transportMode: RouteTransportMode = .walking
    @State private var departureDate = Date()
    @State private var routePlan: RoutePlannerResult?
    @State private var isLoadingRoutePlan = false

    private var courseStops: [(stop: CourseStop, store: Store)] {
        MockData.storesForCourse(course)
    }

    private var stopLookup: [String: (stop: CourseStop, store: Store)] {
        Dictionary(uniqueKeysWithValues: courseStops.map { ($0.store.id, $0) })
    }

    private var displayedCourseStops: [(stop: CourseStop, store: Store)] {
        guard let routePlan else { return courseStops }
        let plannedStops = routePlan.orderedStops.compactMap { stopLookup[$0.id] }
        return plannedStops.isEmpty ? courseStops : plannedStops
    }

    var body: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(spacing: 0) {
                // MARK: - Hero
                courseHero

                // MARK: - Info Bar
                infoBar

                // MARK: - Description
                VStack(alignment: .leading, spacing: AppSpacing.md) {
                    Text(course.description)
                        .font(AppFont.body(15))
                        .foregroundStyle(.appTextSecondary)
                        .lineSpacing(6)
                }
                .padding(.horizontal, AppSpacing.lg)
                .padding(.top, AppSpacing.lg)

                routeRecommendationSection
                    .padding(.top, AppSpacing.xl)

                // MARK: - Course Timeline
                courseTimeline
                    .padding(.top, AppSpacing.xl)

                // MARK: - Map Preview
                courseMapPreview
                    .padding(.top, AppSpacing.xl)

                // MARK: - Action Bar
                actionBar
                    .padding(.top, AppSpacing.xl)
                    .padding(.bottom, AppSpacing.xxl)
            }
        }
        .background(Color.appBackground)
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            calculateRecommendedRoute()
        }
        .onChange(of: transportMode) { _, _ in
            calculateRecommendedRoute()
        }
        .onChange(of: departureDate) { _, _ in
            calculateRecommendedRoute()
        }
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                SaveButton(
                    isSaved: appState.isCourseSaved(course.id),
                    action: { appState.toggleSaveCourse(course.id) }
                )
            }
        }
    }

    private var routeRecommendationSection: some View {
        VStack(alignment: .leading, spacing: AppSpacing.md) {
            SectionHeader(
                title: "실시간 추천 동선",
                subtitle: "거리와 ETA 기준으로 순서를 다시 계산합니다"
            )

            VStack(alignment: .leading, spacing: AppSpacing.md) {
                Picker("이동 수단", selection: $transportMode) {
                    ForEach(RouteTransportMode.allCases) { mode in
                        Text(mode.rawValue).tag(mode)
                    }
                }
                .pickerStyle(.segmented)

                DatePicker(
                    "출발 시간",
                    selection: $departureDate,
                    displayedComponents: [.date, .hourAndMinute]
                )
                .datePickerStyle(.compact)

                if let routePlan {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: AppSpacing.xs) {
                            plannerSummaryPill("\(displayedCourseStops.count)곳", systemImage: "mappin.circle.fill")
                            plannerSummaryPill(travelTime(routePlan.totalTravelTime), systemImage: "clock.fill")
                            plannerSummaryPill(distance(routePlan.totalDistance), systemImage: transportMode.summaryIcon)
                            plannerSummaryPill(clockTime(routePlan.startDate), systemImage: "play.circle.fill")
                            plannerSummaryPill(clockTime(routePlan.endDate), systemImage: "flag.checkered")
                            if let etaBadgeText = transportMode.etaBadgeText {
                                plannerSummaryPill(etaBadgeText, systemImage: "bicycle.circle.fill")
                            }
                        }
                    }

                    Text("추천 순서: \(routePlan.orderedStops.map(\.title).joined(separator: " → "))")
                        .font(AppFont.caption(12))
                        .foregroundStyle(.appTextSecondary)
                        .lineSpacing(4)

                    if let plannerNotice = transportMode.plannerNotice {
                        Text(plannerNotice)
                            .font(AppFont.caption(11))
                            .foregroundStyle(.appTextSecondary)
                    }

                    VStack(alignment: .leading, spacing: AppSpacing.sm) {
                        ForEach(Array(routePlan.legs.enumerated()), id: \.offset) { index, leg in
                            HStack(alignment: .top, spacing: AppSpacing.sm) {
                                Text("\(index + 1)")
                                    .font(AppFont.caption(11))
                                    .foregroundStyle(.white)
                                    .frame(width: 20, height: 20)
                                    .background(Circle().fill(Color.appPrimary))

                                VStack(alignment: .leading, spacing: 2) {
                                    Text("\(leg.source?.title ?? "출발") → \(leg.destination.title)")
                                        .font(AppFont.caption(12))
                                        .foregroundStyle(.appTextPrimary)
                                        .lineLimit(2)

                                    Text("\(clockTime(leg.departureDate)) 출발 · \(clockTime(leg.arrivalDate)) 도착 · \(travelTime(leg.expectedTravelTime))")
                                        .font(AppFont.caption(11))
                                        .foregroundStyle(.appPrimary)

                                    Text("\(distance(leg.distance)) · 체류 \(leg.destination.stayMinutes)분 · 다음 이동 \(clockTime(leg.nextDepartureDate))")
                                        .font(AppFont.caption(11))
                                        .foregroundStyle(.appTextSecondary)
                                }
                            }
                        }
                    }
                } else if isLoadingRoutePlan {
                    HStack(spacing: AppSpacing.sm) {
                        ProgressView()
                        Text("실제 도로 기준 ETA를 계산하는 중입니다")
                            .font(AppFont.caption(12))
                            .foregroundStyle(.appTextSecondary)
                    }
                }
            }
            .padding(AppSpacing.md)
            .background(Color.appCardBackground)
            .clipShape(RoundedRectangle(cornerRadius: AppRadius.lg))
        }
        .padding(.horizontal, AppSpacing.lg)
    }

    private func plannerSummaryPill(_ text: String, systemImage: String) -> some View {
        HStack(spacing: 4) {
            Image(systemName: systemImage)
            Text(text)
        }
        .font(AppFont.caption(11))
        .foregroundStyle(.appPrimary)
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(Color.appPrimary.opacity(0.1))
        .clipShape(Capsule())
    }

    // MARK: - Hero
    private var courseHero: some View {
        ZStack(alignment: .bottomLeading) {
            AppImageView(source: course.coverImageURL)
            .frame(height: 260)
            .clipped()

            LinearGradient(
                colors: [.clear, .black.opacity(0.7)],
                startPoint: .center,
                endPoint: .bottom
            )

            VStack(alignment: .leading, spacing: AppSpacing.sm) {
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
                    .font(AppFont.title(24))
                    .foregroundStyle(.white)
            }
            .padding(AppSpacing.lg)
        }
    }

    // MARK: - Info Bar
    private var infoBar: some View {
        ViewThatFits(in: .horizontal) {
            HStack(spacing: 0) {
                infoItem(icon: "clock.fill", label: course.durationLabel, subtitle: "소요 시간")
                Divider().frame(height: 40)
                infoItem(icon: "mappin.circle.fill", label: "\(course.storeCount)곳", subtitle: "방문 장소")
                Divider().frame(height: 40)
                infoItem(icon: "location.fill", label: course.district.rawValue, subtitle: "지역")
            }
            .padding(.vertical, AppSpacing.md)
            .background(Color.appCardBackground)

            VStack(spacing: 0) {
                infoItem(icon: "clock.fill", label: course.durationLabel, subtitle: "소요 시간")
                Divider()
                infoItem(icon: "mappin.circle.fill", label: "\(course.storeCount)곳", subtitle: "방문 장소")
                Divider()
                infoItem(icon: "location.fill", label: course.district.rawValue, subtitle: "지역")
            }
            .padding(.vertical, AppSpacing.sm)
            .background(Color.appCardBackground)
        }
    }

    private func infoItem(icon: String, label: String, subtitle: String) -> some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .font(.system(size: 16))
                .foregroundStyle(.appPrimary)
            Text(label)
                .font(AppFont.label(14))
                .foregroundStyle(.appTextPrimary)
            Text(subtitle)
                .font(AppFont.caption(11))
                .foregroundStyle(.appTextTertiary)
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Course Timeline
    private var courseTimeline: some View {
        VStack(alignment: .leading, spacing: 0) {
            SectionHeader(title: "코스 동선", subtitle: routePlan == nil ? "기본 순서" : "ETA 기준 추천 순서")
                .padding(.bottom, AppSpacing.md)

            ForEach(Array(displayedCourseStops.enumerated()), id: \.element.stop.id) { index, item in
                courseStopRow(index: index, stop: item.stop, store: item.store, isLast: index == displayedCourseStops.count - 1)
            }
        }
        .padding(.horizontal, AppSpacing.lg)
    }

    private func courseStopRow(index: Int, stop: CourseStop, store: Store, isLast: Bool) -> some View {
        HStack(alignment: .top, spacing: AppSpacing.md) {
            // Timeline indicator
            VStack(spacing: 0) {
                ZStack {
                    Circle()
                        .fill(Color.appPrimary)
                        .frame(width: 32, height: 32)
                    Text("\(index + 1)")
                        .font(AppFont.label(14))
                        .foregroundStyle(.white)
                }
                if !isLast {
                    Rectangle()
                        .fill(Color.appDivider)
                        .frame(width: 2)
                        .frame(minHeight: 60)
                }
            }

            // Store info
            NavigationLink(value: store) {
                VStack(alignment: .leading, spacing: AppSpacing.sm) {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(store.name)
                                .font(AppFont.subtitle(16))
                                .foregroundStyle(.appTextPrimary)
                                .lineLimit(2)
                                .minimumScaleFactor(0.85)
                            Text(store.category.rawValue)
                                .font(AppFont.caption(12))
                                .foregroundStyle(Color(hex: store.category.accentColor))
                        }
                        Spacer()
                        Text("\(stop.stayMinutes)분")
                            .font(AppFont.caption(12))
                            .foregroundStyle(.appPrimary)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color.appPrimary.opacity(0.1))
                            .clipShape(Capsule())
                    }

                    if let note = stop.note {
                        Text(note)
                            .font(AppFont.storyQuote(14))
                            .foregroundStyle(.appTextSecondary)
                            .italic()
                    }
                }
                .padding(AppSpacing.md)
                .background(Color.appCardBackground)
                .clipShape(RoundedRectangle(cornerRadius: AppRadius.md))
                .shadow(color: .black.opacity(0.04), radius: 4, y: 2)
            }
            .buttonStyle(.plain)
        }
        .padding(.bottom, isLast ? 0 : AppSpacing.sm)
    }

    // MARK: - Map Preview
    private var courseMapPreview: some View {
        VStack(alignment: .leading, spacing: AppSpacing.md) {
            SectionHeader(title: "지도에서 보기")

            Map {
                ForEach(Array(displayedCourseStops.enumerated()), id: \.element.stop.id) { index, item in
                    Annotation("\(index + 1). \(item.store.name)", coordinate: item.store.coordinate) {
                        ZStack {
                            Circle()
                                .fill(Color.appPrimary)
                                .frame(width: 28, height: 28)
                            Text("\(index + 1)")
                                .font(AppFont.caption(12))
                                .foregroundStyle(.white)
                        }
                    }
                }

                if let routePlan {
                    ForEach(Array(routePlan.legs.enumerated()), id: \.offset) { _, leg in
                        if let route = leg.route {
                            MapPolyline(route.polyline)
                                .stroke(Color.appPrimary, lineWidth: 4)
                        }
                    }
                }
            }
            .frame(height: 200)
            .clipShape(RoundedRectangle(cornerRadius: AppRadius.lg))
            .padding(.horizontal, AppSpacing.lg)
        }
    }

    // MARK: - Action Bar
    private var actionBar: some View {
        ViewThatFits(in: .horizontal) {
            HStack(spacing: AppSpacing.md) {
                actionBarPrimaryButton
                actionBarShareButton
            }

            VStack(spacing: AppSpacing.sm) {
                actionBarPrimaryButton
                actionBarShareButton
            }
        }
        .padding(.horizontal, AppSpacing.lg)
    }

    private var actionBarPrimaryButton: some View {
        Button {
            appState.toggleSaveCourse(course.id)
        } label: {
            Label(
                appState.isCourseSaved(course.id) ? "저장됨" : "코스 저장",
                systemImage: appState.isCourseSaved(course.id) ? "bookmark.fill" : "bookmark"
            )
            .font(AppFont.label(14))
            .foregroundStyle(.appPrimary)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(Color.appPrimary.opacity(0.1))
            .clipShape(RoundedRectangle(cornerRadius: AppRadius.md))
        }
    }

    private var actionBarShareButton: some View {
        ShareLink(item: "놀거많은대?전 - \(course.title)") {
            Label("공유하기", systemImage: "square.and.arrow.up")
                .font(AppFont.label(14))
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(Color.appPrimary)
                .clipShape(RoundedRectangle(cornerRadius: AppRadius.md))
        }
    }

    private func calculateRecommendedRoute() {
        guard courseStops.count >= 2 else { return }

        isLoadingRoutePlan = true
        let plannerStops = courseStops.map { item in
            RoutePlannerStop.fromStore(item.store, stayMinutes: item.stop.stayMinutes)
        }

        Task {
            let result = await RoutePlannerService.shared.recommendRoute(
                stops: plannerStops,
                transportType: transportMode.transportType,
                departureDate: departureDate,
                start: nil
            )

            await MainActor.run {
                routePlan = result
                isLoadingRoutePlan = false
            }
        }
    }

    private func distance(_ distance: CLLocationDistance) -> String {
        if distance >= 1000 {
            return String(format: "%.1fkm", distance / 1000)
        }
        return "\(Int(distance))m"
    }

    private func travelTime(_ time: TimeInterval) -> String {
        let formatter = DateComponentsFormatter()
        formatter.unitsStyle = .abbreviated
        formatter.allowedUnits = [.hour, .minute]
        return formatter.string(from: time) ?? "-"
    }

    private func clockTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ko_KR")
        formatter.dateFormat = "HH:mm"
        return formatter.string(from: date)
    }
}
