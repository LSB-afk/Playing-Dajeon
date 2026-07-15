import Foundation

// MARK: - Owner Analytics Models
// 사장님 대시보드용 분석 데이터. 가게 ID 기반 시드로 재현 가능한 목 데이터를 생성.

struct OwnerAnalytics: Identifiable, Hashable {
    let id: String                       // == storeId
    let storeName: String
    let monthlyVisits: [MonthlyPoint]    // 최근 12개월
    let monthlyRevenue: [MonthlyPoint]   // 최근 12개월
    let hourly: [HourlyPoint]            // 0~23시 평균 방문
    let weekday: [WeekdayPoint]          // 월~일
    let seasonal: [SeasonalPoint]        // 봄/여름/가을/겨울
    let inflowChannels: [InflowChannel]  // 유입 경로
    let topMenus: [MenuRank]             // 인기 메뉴 Top
    let savedCount: Int
    let totalVisitsThisMonth: Int
    let estimatedRevenueThisMonth: Int   // KRW
    let visitsDeltaPercent: Double       // 전월 대비
    let revenueDeltaPercent: Double      // 전월 대비
    let aiSummary: [String]              // AI 요약 인사이트
    let aiHighlight: String              // 핵심 한 줄
}

struct MonthlyPoint: Identifiable, Hashable {
    let id = UUID()
    let month: Date
    let value: Double
    var label: String {
        let f = DateFormatter()
        f.locale = Locale(identifier: "ko_KR")
        f.dateFormat = "M월"
        return f.string(from: month)
    }
}

struct HourlyPoint: Identifiable, Hashable {
    let id = UUID()
    let hour: Int          // 0~23
    let visits: Double
    var label: String { "\(hour)시" }
}

struct WeekdayPoint: Identifiable, Hashable {
    let id = UUID()
    let weekday: Int       // 1=월 ... 7=일
    let visits: Double
    var label: String {
        ["월","화","수","목","금","토","일"][max(0, min(6, weekday - 1))]
    }
    var isWeekend: Bool { weekday >= 6 }
}

struct SeasonalPoint: Identifiable, Hashable {
    let id = UUID()
    let season: String     // 봄/여름/가을/겨울
    let visits: Double
}

struct InflowChannel: Identifiable, Hashable {
    let id = UUID()
    let channel: String    // 코스 추천, 지도 탐색, 저장 → 방문, 검색, 외부 공유
    let share: Double      // 0~1
    var percent: Int { Int((share * 100).rounded()) }
}

struct MenuRank: Identifiable, Hashable {
    let id = UUID()
    let name: String
    let orders: Int
}

// MARK: - Mock Generator

enum OwnerAnalyticsMock {

    static func analytics(for store: Store) -> OwnerAnalytics {
        var rng = SeededRNG(seed: stableSeed(from: store.id))
        let baseVisits = Int.random(in: 280...720, using: &rng)
        let baseTicket = Int.random(in: 7_500...22_000, using: &rng) // 객단가
        let monthsBack = 12

        let cal = Calendar(identifier: .gregorian)
        let now = Date()
        let currentMonthStart = cal.date(from: cal.dateComponents([.year, .month], from: now)) ?? now

        // 월별 방문 추세 (계절성 + 노이즈)
        var visitsSeries: [MonthlyPoint] = []
        var revenueSeries: [MonthlyPoint] = []
        for i in stride(from: monthsBack - 1, through: 0, by: -1) {
            guard let monthDate = cal.date(byAdding: .month, value: -i, to: currentMonthStart) else { continue }
            let m = cal.component(.month, from: monthDate)
            let seasonal = seasonalFactor(month: m, category: store.category)
            let trend = 1.0 + (Double(monthsBack - i) * 0.012) // 완만한 성장
            let noise = Double.random(in: 0.85...1.15, using: &rng)
            let v = Double(baseVisits) * seasonal * trend * noise
            visitsSeries.append(MonthlyPoint(month: monthDate, value: v.rounded()))

            let ticket = Double(baseTicket) * Double.random(in: 0.92...1.10, using: &rng)
            revenueSeries.append(MonthlyPoint(month: monthDate, value: (v * ticket).rounded()))
        }

        // 시간대 (카테고리별 피크 다름)
        let hourly = (0..<24).map { h -> HourlyPoint in
            let weight = hourlyWeight(hour: h, category: store.category)
            let v = Double(baseVisits) / 30.0 * weight * Double.random(in: 0.8...1.2, using: &rng)
            return HourlyPoint(hour: h, visits: max(0, v.rounded()))
        }

        // 요일
        let weekday = (1...7).map { w -> WeekdayPoint in
            let weekendBoost = (w >= 6) ? 1.45 : 1.0
            let v = Double(baseVisits) / 7.0 * weekendBoost * Double.random(in: 0.9...1.15, using: &rng)
            return WeekdayPoint(weekday: w, visits: v.rounded())
        }

        // 계절
        let seasons = ["봄", "여름", "가을", "겨울"]
        let seasonal = seasons.map { season -> SeasonalPoint in
            let factor: Double = {
                switch (store.category, season) {
                case (.cafe, "봄"), (.cafe, "가을"): return 1.25
                case (.bar, "여름"), (.bar, "겨울"): return 1.30
                case (.restaurant, "겨울"): return 1.20
                case (.shop, "겨울"): return 1.18
                case (.workshop, "봄"), (.culture, "가을"): return 1.22
                default: return 1.0
                }
            }()
            let v = Double(baseVisits) * 3.0 * factor * Double.random(in: 0.92...1.08, using: &rng)
            return SeasonalPoint(season: season, visits: v.rounded())
        }

        // 유입 경로
        let raw: [(String, Double)] = [
            ("코스 추천", Double.random(in: 0.32...0.46, using: &rng)),
            ("지도 탐색", Double.random(in: 0.16...0.24, using: &rng)),
            ("저장 → 방문", Double.random(in: 0.14...0.22, using: &rng)),
            ("검색", Double.random(in: 0.08...0.14, using: &rng)),
            ("외부 공유", Double.random(in: 0.05...0.10, using: &rng))
        ]
        let total = raw.reduce(0) { $0 + $1.1 }
        let channels = raw.map { InflowChannel(channel: $0.0, share: $0.1 / total) }

        // 인기 메뉴
        let menus = store.menuItems.prefix(5).enumerated().map { idx, m -> MenuRank in
            let base = baseVisits / (idx + 1) + Int.random(in: -30...30, using: &rng)
            return MenuRank(name: m.name, orders: max(20, base))
        }

        let visitsThisMonth = Int(visitsSeries.last?.value ?? 0)
        let revenueThisMonth = Int(revenueSeries.last?.value ?? 0)
        let prevVisits = visitsSeries.dropLast().last?.value ?? Double(visitsThisMonth)
        let prevRevenue = revenueSeries.dropLast().last?.value ?? Double(revenueThisMonth)
        let visitsDelta = prevVisits > 0 ? ((Double(visitsThisMonth) - prevVisits) / prevVisits) * 100 : 0
        let revenueDelta = prevRevenue > 0 ? ((Double(revenueThisMonth) - prevRevenue) / prevRevenue) * 100 : 0

        let peakHour = hourly.max(by: { $0.visits < $1.visits })?.hour ?? 14
        let peakDay = weekday.max(by: { $0.visits < $1.visits })?.label ?? "토"
        let topSeason = seasonal.max(by: { $0.visits < $1.visits })?.season ?? "가을"
        let topChannel = channels.max(by: { $0.share < $1.share })?.channel ?? "코스 추천"

        let highlight = "이번 달은 전월 대비 \(formatDelta(visitsDelta)) 방문, \(topChannel) 유입이 가장 큽니다."
        let summary: [String] = [
            "전월 대비 방문 \(formatDelta(visitsDelta)), 추정 매출 \(formatDelta(revenueDelta)).",
            "피크 시간대는 \(peakHour)시 전후, 가장 붐비는 요일은 \(peakDay)요일.",
            "\(topSeason)에 방문이 가장 많이 발생해 시즌 메뉴/이벤트 효과가 큽니다.",
            "유입 1위는 ‘\(topChannel)’ — 코스 노출이 늘면 신규 방문 전환이 빨라집니다.",
            "재방문 가능성이 높은 인기 메뉴 ‘\(menus.first?.name ?? "시그니처")’를 시그니처로 강조해보세요."
        ]

        return OwnerAnalytics(
            id: store.id,
            storeName: store.name,
            monthlyVisits: visitsSeries,
            monthlyRevenue: revenueSeries,
            hourly: hourly,
            weekday: weekday,
            seasonal: seasonal,
            inflowChannels: channels,
            topMenus: Array(menus),
            savedCount: Int.random(in: 60...520, using: &rng),
            totalVisitsThisMonth: visitsThisMonth,
            estimatedRevenueThisMonth: revenueThisMonth,
            visitsDeltaPercent: visitsDelta,
            revenueDeltaPercent: revenueDelta,
            aiSummary: summary,
            aiHighlight: highlight
        )
    }

    private static func seasonalFactor(month: Int, category: StoreCategory) -> Double {
        switch category {
        case .cafe:        return [0.85, 0.90, 1.05, 1.20, 1.15, 1.00, 0.95, 0.95, 1.18, 1.25, 1.05, 0.90][month - 1]
        case .restaurant:  return [1.05, 1.00, 1.05, 1.10, 1.10, 1.00, 0.95, 0.95, 1.05, 1.10, 1.15, 1.20][month - 1]
        case .attraction:  return [0.80, 0.85, 1.10, 1.30, 1.25, 1.05, 0.95, 0.95, 1.20, 1.30, 1.00, 0.85][month - 1]
        case .festival:    return [0.70, 0.75, 1.00, 1.10, 1.15, 1.20, 1.35, 1.45, 1.25, 1.10, 0.90, 0.80][month - 1]
        case .date:        return [0.95, 1.10, 1.05, 1.20, 1.15, 1.05, 1.00, 1.00, 1.15, 1.20, 1.10, 1.05][month - 1]
        case .family:      return [0.85, 0.90, 1.05, 1.20, 1.25, 1.15, 1.30, 1.30, 1.15, 1.10, 0.95, 0.90][month - 1]
        case .experience:  return [0.85, 0.90, 1.15, 1.25, 1.20, 1.00, 0.85, 0.85, 1.15, 1.25, 1.05, 0.95][month - 1]
        case .nightSpot:   return [1.20, 1.05, 1.00, 1.10, 1.10, 1.25, 1.30, 1.30, 1.10, 1.10, 1.20, 1.30][month - 1]
        case .bar:         return [1.20, 1.05, 1.00, 1.10, 1.10, 1.25, 1.30, 1.30, 1.10, 1.10, 1.20, 1.30][month - 1]
        case .shop:        return [0.95, 0.95, 1.00, 1.05, 1.05, 1.00, 0.95, 0.95, 1.05, 1.10, 1.20, 1.30][month - 1]
        case .workshop:    return [0.85, 0.90, 1.15, 1.25, 1.20, 1.00, 0.85, 0.85, 1.15, 1.25, 1.05, 0.95][month - 1]
        case .culture:     return [0.95, 0.95, 1.10, 1.20, 1.15, 1.00, 0.90, 0.90, 1.15, 1.25, 1.10, 1.00][month - 1]
        case .walkSpot:    return [0.80, 0.85, 1.10, 1.30, 1.25, 1.05, 0.95, 0.95, 1.20, 1.30, 1.00, 0.85][month - 1]
        }
    }

    private static func hourlyWeight(hour: Int, category: StoreCategory) -> Double {
        switch category {
        case .cafe:
            return [0,0,0,0,0,0,0.1,0.3,0.6,0.9,1.2,1.4,1.5,1.6,1.7,1.5,1.2,0.9,0.6,0.4,0.2,0.1,0,0][hour]
        case .restaurant:
            return [0,0,0,0,0,0,0,0.2,0.5,0.7,1.0,1.6,1.8,1.4,0.6,0.5,0.6,1.2,1.7,1.5,0.9,0.4,0.1,0][hour]
        case .attraction:
            return [0,0,0,0,0,0,0.2,0.5,0.9,1.1,1.2,1.2,1.0,1.0,1.1,1.3,1.5,1.4,1.0,0.6,0.3,0.1,0,0][hour]
        case .festival:
            return [0.4,0.2,0,0,0,0,0,0,0.1,0.2,0.4,0.7,0.9,1.0,1.1,1.3,1.6,1.9,2.1,2.2,2.0,1.6,1.0,0.6][hour]
        case .date:
            return [0.1,0,0,0,0,0,0,0.1,0.3,0.5,0.8,1.0,1.1,1.1,1.2,1.3,1.5,1.8,2.0,1.8,1.4,0.8,0.3,0.1][hour]
        case .family:
            return [0,0,0,0,0,0,0.1,0.3,0.7,1.0,1.3,1.5,1.5,1.4,1.3,1.1,0.8,0.4,0.2,0.1,0,0,0,0][hour]
        case .experience:
            return [0,0,0,0,0,0,0,0,0.2,0.6,1.0,1.2,1.2,1.4,1.6,1.6,1.4,1.0,0.6,0.3,0.1,0,0,0][hour]
        case .nightSpot:
            return [0.2,0.1,0,0,0,0,0,0,0,0,0,0.1,0.2,0.3,0.4,0.6,0.9,1.2,1.5,1.8,2.0,1.9,1.4,0.8][hour]
        case .bar:
            return [0.2,0.1,0,0,0,0,0,0,0,0,0,0.1,0.2,0.3,0.4,0.6,0.9,1.2,1.5,1.8,2.0,1.9,1.4,0.8][hour]
        case .shop:
            return [0,0,0,0,0,0,0,0,0.2,0.5,0.9,1.2,1.3,1.3,1.4,1.5,1.5,1.4,1.2,0.9,0.5,0.2,0,0][hour]
        case .workshop:
            return [0,0,0,0,0,0,0,0,0.2,0.6,1.0,1.2,1.2,1.4,1.6,1.6,1.4,1.0,0.6,0.3,0.1,0,0,0][hour]
        case .culture:
            return [0,0,0,0,0,0,0,0,0.1,0.4,0.8,1.1,1.2,1.3,1.4,1.6,1.7,1.5,1.2,0.9,0.5,0.2,0,0][hour]
        case .walkSpot:
            return [0,0,0,0,0,0,0.2,0.5,0.9,1.1,1.2,1.2,1.0,1.0,1.1,1.3,1.5,1.4,1.0,0.6,0.3,0.1,0,0][hour]
        }
    }

    private static func formatDelta(_ v: Double) -> String {
        let sign = v >= 0 ? "+" : ""
        return "\(sign)\(String(format: "%.1f", v))%"
    }

    private static func stableSeed(from id: String) -> UInt64 {
        var hash: UInt64 = 1469598103934665603
        for byte in id.utf8 {
            hash ^= UInt64(byte)
            hash = hash &* 1099511628211
        }
        return hash
    }
}

// MARK: - Deterministic RNG

struct SeededRNG: RandomNumberGenerator {
    private var state: UInt64
    init(seed: UInt64) { self.state = seed == 0 ? 0xdeadbeef : seed }
    mutating func next() -> UInt64 {
        state ^= state << 13
        state ^= state >> 7
        state ^= state << 17
        return state
    }
}
