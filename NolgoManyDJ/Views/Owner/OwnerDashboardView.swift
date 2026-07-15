import SwiftUI
import Charts

// MARK: - Owner Dashboard
// 소상공인(가게 사장님)이 자신의 가게 유입/매출/시간대/계절 데이터를
// 한 화면에서 확인하고 AI 요약을 받을 수 있는 대시보드.

struct OwnerDashboardView: View {
    @State private var selectedStore: Store = MockData.stores.first!
    @State private var revenueViewMode: RevenueMode = .visits

    enum RevenueMode: String, CaseIterable, Identifiable {
        case visits = "방문"
        case revenue = "매출"
        var id: String { rawValue }
    }

    private var analytics: OwnerAnalytics {
        OwnerAnalyticsMock.analytics(for: selectedStore)
    }

    var body: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(alignment: .leading, spacing: AppSpacing.lg) {
                storeSelector
                kpiCards
                aiSummaryCard
                monthlyChartCard
                hourlyChartCard
                weekdayAndSeasonRow
                inflowChartCard
                topMenuCard
                footerNote
            }
            .padding(.vertical, AppSpacing.md)
            .padding(.bottom, AppSpacing.xxl)
        }
        .background(Color.appBackground)
        .navigationTitle("사장님 대시보드")
        .navigationBarTitleDisplayMode(.inline)
    }

    // MARK: Store Selector
    private var storeSelector: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("가게 선택")
                .font(AppFont.caption(12))
                .foregroundStyle(.appTextSecondary)
                .padding(.horizontal, AppSpacing.md)

            Menu {
                ForEach(MockData.stores) { store in
                    Button {
                        selectedStore = store
                    } label: {
                        Label("\(store.name) · \(store.district.rawValue)", systemImage: store.category.icon)
                    }
                }
            } label: {
                HStack(spacing: 10) {
                    Image(systemName: selectedStore.category.icon)
                        .foregroundStyle(.appPrimary)
                    VStack(alignment: .leading, spacing: 2) {
                        Text(selectedStore.name)
                            .font(AppFont.subtitle(17))
                            .foregroundStyle(.appTextPrimary)
                        Text("\(selectedStore.district.rawValue) · \(selectedStore.category.rawValue)")
                            .font(AppFont.caption(12))
                            .foregroundStyle(.appTextSecondary)
                    }
                    Spacer()
                    Image(systemName: "chevron.up.chevron.down")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(.appTextTertiary)
                }
                .padding(.horizontal, AppSpacing.md)
                .padding(.vertical, 14)
                .background(Color.appCardBackground, in: RoundedRectangle(cornerRadius: AppRadius.md))
                .overlay(
                    RoundedRectangle(cornerRadius: AppRadius.md)
                        .stroke(Color.appDivider, lineWidth: 1)
                )
            }
            .padding(.horizontal, AppSpacing.md)
        }
    }

    // MARK: KPI Cards
    private var kpiCards: some View {
        let a = analytics
        return VStack(spacing: AppSpacing.sm) {
            HStack(spacing: AppSpacing.sm) {
                kpiCard(
                    title: "이번 달 방문",
                    value: "\(a.totalVisitsThisMonth.formatted())",
                    delta: a.visitsDeltaPercent,
                    icon: "person.2.fill"
                )
                kpiCard(
                    title: "추정 매출",
                    value: krw(a.estimatedRevenueThisMonth),
                    delta: a.revenueDeltaPercent,
                    icon: "wonsign.circle.fill"
                )
            }
            HStack(spacing: AppSpacing.sm) {
                kpiCard(
                    title: "저장 수",
                    value: "\(a.savedCount.formatted())",
                    delta: nil,
                    icon: "bookmark.fill"
                )
                kpiCard(
                    title: "객단가(추정)",
                    value: krw(a.totalVisitsThisMonth > 0 ? a.estimatedRevenueThisMonth / a.totalVisitsThisMonth : 0),
                    delta: nil,
                    icon: "tag.fill"
                )
            }
        }
        .padding(.horizontal, AppSpacing.md)
    }

    private func kpiCard(title: String, value: String, delta: Double?, icon: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: icon)
                    .foregroundStyle(.appPrimary)
                Spacer()
                if let delta {
                    HStack(spacing: 2) {
                        Image(systemName: delta >= 0 ? "arrow.up.right" : "arrow.down.right")
                        Text(String(format: "%@%.1f%%", delta >= 0 ? "+" : "", delta))
                    }
                    .font(AppFont.caption(11))
                    .foregroundStyle(delta >= 0 ? Color.green : Color.red)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background((delta >= 0 ? Color.green : Color.red).opacity(0.12), in: Capsule())
                }
            }
            Text(value)
                .font(AppFont.title(22))
                .foregroundStyle(.appTextPrimary)
                .minimumScaleFactor(0.7)
                .lineLimit(1)
            Text(title)
                .font(AppFont.caption(12))
                .foregroundStyle(.appTextSecondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(AppSpacing.md)
        .background(Color.appCardBackground, in: RoundedRectangle(cornerRadius: AppRadius.lg))
        .overlay(
            RoundedRectangle(cornerRadius: AppRadius.lg)
                .stroke(Color.appDivider, lineWidth: 0.5)
        )
    }

    // MARK: AI Summary
    private var aiSummaryCard: some View {
        let a = analytics
        return VStack(alignment: .leading, spacing: AppSpacing.md) {
            HStack(spacing: 8) {
                Image(systemName: "sparkles")
                    .foregroundStyle(.white)
                    .padding(8)
                    .background(LinearGradient(colors: [Color.appPrimary, Color.appSecondary], startPoint: .topLeading, endPoint: .bottomTrailing), in: Circle())
                VStack(alignment: .leading, spacing: 2) {
                    Text("AI 요약 리포트")
                        .font(AppFont.subtitle(16))
                        .foregroundStyle(.appTextPrimary)
                    Text("최근 12개월 추세 기반 자동 분석")
                        .font(AppFont.caption(11))
                        .foregroundStyle(.appTextSecondary)
                }
                Spacer()
            }

            Text(a.aiHighlight)
                .font(AppFont.body(15))
                .foregroundStyle(.appTextPrimary)
                .padding(.vertical, 10)
                .padding(.horizontal, 12)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color.appPrimary.opacity(0.08), in: RoundedRectangle(cornerRadius: AppRadius.md))

            VStack(alignment: .leading, spacing: 10) {
                ForEach(Array(a.aiSummary.enumerated()), id: \.offset) { _, line in
                    HStack(alignment: .top, spacing: 8) {
                        Circle()
                            .fill(Color.appPrimary)
                            .frame(width: 5, height: 5)
                            .offset(y: 7)
                        Text(line)
                            .font(AppFont.body(14))
                            .foregroundStyle(.appTextPrimary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
            }
        }
        .padding(AppSpacing.lg)
        .background(Color.appCardBackground, in: RoundedRectangle(cornerRadius: AppRadius.lg))
        .overlay(
            RoundedRectangle(cornerRadius: AppRadius.lg)
                .stroke(Color.appDivider, lineWidth: 0.5)
        )
        .padding(.horizontal, AppSpacing.md)
    }

    // MARK: Monthly chart
    private var monthlyChartCard: some View {
        let a = analytics
        let data: [MonthlyPoint] = revenueViewMode == .visits ? a.monthlyVisits : a.monthlyRevenue
        return chartCard(title: "월별 추이", subtitle: "최근 12개월") {
            Picker("", selection: $revenueViewMode) {
                ForEach(RevenueMode.allCases) { Text($0.rawValue).tag($0) }
            }
            .pickerStyle(.segmented)
            .padding(.bottom, 8)

            Chart(data) { point in
                LineMark(
                    x: .value("월", point.label),
                    y: .value(revenueViewMode.rawValue, point.value)
                )
                .interpolationMethod(.catmullRom)
                .foregroundStyle(Color.appPrimary)
                .lineStyle(StrokeStyle(lineWidth: 2.5))

                AreaMark(
                    x: .value("월", point.label),
                    y: .value(revenueViewMode.rawValue, point.value)
                )
                .interpolationMethod(.catmullRom)
                .foregroundStyle(
                    LinearGradient(
                        colors: [Color.appPrimary.opacity(0.35), Color.appPrimary.opacity(0.02)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )

                PointMark(
                    x: .value("월", point.label),
                    y: .value(revenueViewMode.rawValue, point.value)
                )
                .foregroundStyle(Color.appPrimary)
                .symbolSize(28)
            }
            .frame(height: 220)
            .chartYAxis {
                AxisMarks(position: .leading) { value in
                    AxisGridLine().foregroundStyle(Color.appDivider)
                    AxisValueLabel {
                        if let v = value.as(Double.self) {
                            Text(revenueViewMode == .revenue ? shortKRW(Int(v)) : "\(Int(v))")
                                .font(.system(size: 10))
                                .foregroundStyle(Color.appTextTertiary)
                        }
                    }
                }
            }
            .chartXAxis {
                AxisMarks(values: .automatic(desiredCount: 6)) { _ in
                    AxisValueLabel()
                        .font(.system(size: 10))
                        .foregroundStyle(Color.appTextTertiary)
                }
            }
        }
    }

    // MARK: Hourly heat
    private var hourlyChartCard: some View {
        let a = analytics
        let peak = a.hourly.max(by: { $0.visits < $1.visits })?.hour ?? 14
        return chartCard(title: "시간대별 방문", subtitle: "피크 \(peak)시 전후") {
            Chart(a.hourly) { point in
                BarMark(
                    x: .value("시", point.hour),
                    y: .value("방문", point.visits)
                )
                .foregroundStyle(
                    point.hour == peak
                    ? Color.appPrimaryDark
                    : Color.appPrimary.opacity(0.55)
                )
                .cornerRadius(3)
            }
            .frame(height: 180)
            .chartXAxis {
                AxisMarks(values: [0, 6, 9, 12, 15, 18, 21]) { value in
                    AxisValueLabel {
                        if let h = value.as(Int.self) {
                            Text("\(h)시")
                                .font(.system(size: 10))
                                .foregroundStyle(Color.appTextTertiary)
                        }
                    }
                }
            }
            .chartYAxis {
                AxisMarks(position: .leading) { _ in
                    AxisGridLine().foregroundStyle(Color.appDivider)
                    AxisValueLabel()
                        .font(.system(size: 10))
                        .foregroundStyle(Color.appTextTertiary)
                }
            }
        }
    }

    // MARK: Weekday & Season row
    private var weekdayAndSeasonRow: some View {
        let a = analytics
        return VStack(spacing: AppSpacing.md) {
            chartCard(title: "요일별 방문", subtitle: "주말 \(weekendShare(a.weekday))% 비중") {
                Chart(a.weekday) { point in
                    BarMark(
                        x: .value("요일", point.label),
                        y: .value("방문", point.visits)
                    )
                    .foregroundStyle(point.isWeekend ? Color.appPrimary : Color.appSecondary.opacity(0.7))
                    .cornerRadius(6)
                }
                .frame(height: 160)
                .chartYAxis {
                    AxisMarks(position: .leading) { _ in
                        AxisGridLine().foregroundStyle(Color.appDivider)
                        AxisValueLabel()
                            .font(.system(size: 10))
                            .foregroundStyle(Color.appTextTertiary)
                    }
                }
                .chartXAxis {
                    AxisMarks { _ in
                        AxisValueLabel()
                            .font(.system(size: 11))
                            .foregroundStyle(Color.appTextSecondary)
                    }
                }
            }

            chartCard(title: "계절별 방문", subtitle: "시즌 효과 비교") {
                Chart(a.seasonal) { point in
                    BarMark(
                        x: .value("계절", point.season),
                        y: .value("방문", point.visits)
                    )
                    .foregroundStyle(by: .value("계절", point.season))
                    .cornerRadius(8)
                    .annotation(position: .top) {
                        Text("\(Int(point.visits))")
                            .font(.system(size: 10, weight: .semibold))
                            .foregroundStyle(.appTextSecondary)
                    }
                }
                .chartForegroundStyleScale([
                    "봄": Color.pink.opacity(0.55),
                    "여름": Color.teal.opacity(0.7),
                    "가을": Color.orange.opacity(0.7),
                    "겨울": Color.blue.opacity(0.5)
                ])
                .frame(height: 180)
                .chartLegend(.hidden)
                .chartYAxis {
                    AxisMarks(position: .leading) { _ in
                        AxisGridLine().foregroundStyle(Color.appDivider)
                        AxisValueLabel()
                            .font(.system(size: 10))
                            .foregroundStyle(Color.appTextTertiary)
                    }
                }
            }
        }
    }

    // MARK: Inflow channels
    private var inflowChartCard: some View {
        let a = analytics
        return chartCard(title: "유입 경로", subtitle: "방문객이 가게로 들어온 경로") {
            HStack(alignment: .center, spacing: AppSpacing.lg) {
                Chart(a.inflowChannels) { channel in
                    SectorMark(
                        angle: .value("비중", channel.share),
                        innerRadius: .ratio(0.62),
                        angularInset: 2
                    )
                    .foregroundStyle(by: .value("경로", channel.channel))
                    .cornerRadius(4)
                }
                .chartForegroundStyleScale([
                    "코스 추천": Color.appPrimary,
                    "지도 탐색": Color.appSecondary,
                    "저장 → 방문": Color.appAccent,
                    "검색": Color.purple.opacity(0.55),
                    "외부 공유": Color.orange.opacity(0.6)
                ])
                .chartLegend(.hidden)
                .frame(width: 140, height: 140)

                VStack(alignment: .leading, spacing: 8) {
                    ForEach(a.inflowChannels) { c in
                        HStack(spacing: 8) {
                            Circle()
                                .fill(legendColor(for: c.channel))
                                .frame(width: 8, height: 8)
                            Text(c.channel)
                                .font(AppFont.caption(12))
                                .foregroundStyle(.appTextPrimary)
                            Spacer()
                            Text("\(c.percent)%")
                                .font(AppFont.label(13))
                                .foregroundStyle(.appTextSecondary)
                        }
                    }
                }
            }
        }
    }

    // MARK: Top menus
    private var topMenuCard: some View {
        let a = analytics
        let maxOrders = max(1, a.topMenus.map { $0.orders }.max() ?? 1)
        return chartCard(title: "인기 메뉴 Top", subtitle: "최근 90일 주문 추정") {
            VStack(spacing: 10) {
                ForEach(Array(a.topMenus.enumerated()), id: \.element.id) { idx, menu in
                    HStack(spacing: 10) {
                        Text("\(idx + 1)")
                            .font(AppFont.label(13))
                            .foregroundStyle(.appPrimary)
                            .frame(width: 18, alignment: .leading)
                        VStack(alignment: .leading, spacing: 4) {
                            Text(menu.name)
                                .font(AppFont.body(14))
                                .foregroundStyle(.appTextPrimary)
                                .lineLimit(1)
                            GeometryReader { geo in
                                ZStack(alignment: .leading) {
                                    Capsule()
                                        .fill(Color.appSurfaceDim)
                                        .frame(height: 6)
                                    Capsule()
                                        .fill(LinearGradient(
                                            colors: [Color.appPrimary, Color.appSecondary],
                                            startPoint: .leading, endPoint: .trailing
                                        ))
                                        .frame(width: geo.size.width * CGFloat(menu.orders) / CGFloat(maxOrders), height: 6)
                                }
                            }
                            .frame(height: 6)
                        }
                        Text("\(menu.orders)")
                            .font(AppFont.label(13))
                            .foregroundStyle(.appTextSecondary)
                            .frame(width: 48, alignment: .trailing)
                    }
                }
            }
        }
    }

    // MARK: Footer
    private var footerNote: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 6) {
                Image(systemName: "info.circle")
                Text("데이터 안내")
            }
            .font(AppFont.caption(12))
            .foregroundStyle(.appTextSecondary)

            Text("이 대시보드는 ‘놀거많은대?전’ 앱 내 코스 노출·저장·방문 완료 이벤트를 바탕으로 추정된 수치입니다. 실제 POS 매출과 차이가 있을 수 있어요.")
                .font(AppFont.caption(11))
                .foregroundStyle(.appTextTertiary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(AppSpacing.md)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.appSurfaceDim, in: RoundedRectangle(cornerRadius: AppRadius.md))
        .padding(.horizontal, AppSpacing.md)
    }

    // MARK: Generic chart card
    @ViewBuilder
    private func chartCard<Content: View>(title: String, subtitle: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(AppFont.subtitle(16))
                    .foregroundStyle(.appTextPrimary)
                Text(subtitle)
                    .font(AppFont.caption(11))
                    .foregroundStyle(.appTextSecondary)
            }
            content()
        }
        .padding(AppSpacing.lg)
        .background(Color.appCardBackground, in: RoundedRectangle(cornerRadius: AppRadius.lg))
        .overlay(
            RoundedRectangle(cornerRadius: AppRadius.lg)
                .stroke(Color.appDivider, lineWidth: 0.5)
        )
        .padding(.horizontal, AppSpacing.md)
    }

    // MARK: Helpers
    private func krw(_ v: Int) -> String {
        let f = NumberFormatter()
        f.numberStyle = .decimal
        f.locale = Locale(identifier: "ko_KR")
        return "₩\(f.string(from: NSNumber(value: v)) ?? "\(v)")"
    }

    private func shortKRW(_ v: Int) -> String {
        if v >= 10_000_000 { return String(format: "%.1f천만", Double(v) / 10_000_000) }
        if v >= 10_000 { return String(format: "%.1f만", Double(v) / 10_000) }
        return "\(v)"
    }

    private func weekendShare(_ pts: [WeekdayPoint]) -> Int {
        let total = pts.reduce(0) { $0 + $1.visits }
        let weekend = pts.filter { $0.isWeekend }.reduce(0) { $0 + $1.visits }
        return total > 0 ? Int((weekend / total * 100).rounded()) : 0
    }

    private func legendColor(for channel: String) -> Color {
        switch channel {
        case "코스 추천": return .appPrimary
        case "지도 탐색": return .appSecondary
        case "저장 → 방문": return .appAccent
        case "검색": return .purple.opacity(0.55)
        case "외부 공유": return .orange.opacity(0.6)
        default: return .appPrimary
        }
    }
}
