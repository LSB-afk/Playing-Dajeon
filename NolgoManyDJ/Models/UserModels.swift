import Foundation

struct CodableCoordinate: Codable, Hashable {
    let latitude: Double
    let longitude: Double
}

// MARK: - User Saved Store
struct UserSavedStore: Identifiable, Codable {
    let id: String
    let userId: String
    let storeId: String
    let createdAt: Date
}

// MARK: - User Saved Course
struct UserSavedCourse: Identifiable, Codable {
    let id: String
    let userId: String
    let courseId: String
    let createdAt: Date
}

// MARK: - User Visit
struct UserVisit: Identifiable, Codable {
    let id: String
    let userId: String
    let storeId: String
    let visitedAt: Date
    let verificationType: VerificationType
    let note: String?
    let coordinate: CodableCoordinate?
}

enum VerificationType: String, Codable {
    case manual = "manual"
    case qr = "qr"
    case location = "location"
}

enum AgeGroup: String, Codable, CaseIterable, Identifiable {
    case teens = "10대"
    case twenties = "20대"
    case thirties = "30대"
    case forties = "40대"
    case fiftyPlus = "50대 이상"

    var id: String { rawValue }
}

enum CourseVisibility: String, Codable {
    case privateOnly = "private"
    case publicOpen = "public"
    case linkOnly = "link"
}

enum TagCategory: String, Codable, CaseIterable {
    case festival = "축제"
    case district = "동네"
    case mood = "분위기"
    case food = "먹거리"
    case activity = "활동"
    case season = "시즌"
}

struct KeywordTag: Identifiable, Codable, Hashable {
    let id: String
    let name: String
    let category: TagCategory
    let usageCount: Int
}

enum BadgeType: String, Codable, CaseIterable, Hashable {
    case firstCourse = "첫 코스 완주"
    case fiveCourses = "5코스 탐험가"
    case tenCourses = "10코스 마스터"
    case eunhaengMaster = "은행동 전문가"
    case daeheungMaster = "대흥동 전문가"
    case sunhwaMaster = "선화동 전문가"
    case nightOwl = "야행성 탐험가"
    case rainyDayWalker = "비의 낭만"
    case foodHunter = "대전 미식가"
    case breadFestival2026 = "빵축제 2026"
    case cherryBlossom2026 = "벚꽃 시즌 2026"

    var icon: String {
        switch self {
        case .firstCourse: return "star.fill"
        case .fiveCourses: return "star.circle.fill"
        case .tenCourses: return "crown.fill"
        case .eunhaengMaster, .daeheungMaster, .sunhwaMaster: return "building.2.fill"
        case .nightOwl: return "moon.stars.fill"
        case .rainyDayWalker: return "umbrella.fill"
        case .foodHunter: return "fork.knife.circle.fill"
        case .breadFestival2026: return "birthday.cake.fill"
        case .cherryBlossom2026: return "leaf.fill"
        }
    }

    var description: String {
        switch self {
        case .firstCourse: return "첫 번째 코스를 완주했어요!"
        case .fiveCourses: return "5개 코스를 완주한 진정한 탐험가"
        case .tenCourses: return "10개 코스 완주! 대전의 달인이네요"
        case .eunhaengMaster: return "은행동 가게를 3곳 이상 방문했어요"
        case .daeheungMaster: return "대흥동 가게를 3곳 이상 방문했어요"
        case .sunhwaMaster: return "선화동 가게를 3곳 이상 방문했어요"
        case .nightOwl: return "야간 감성 코스를 꾸준히 즐겼어요"
        case .rainyDayWalker: return "비 오는 날에도 탐방을 멈추지 않은 당신"
        case .foodHunter: return "맛집 코스를 따라 대전의 맛을 모았어요"
        case .breadFestival2026: return "빵축제 감성 코스를 탐험했어요"
        case .cherryBlossom2026: return "벚꽃 시즌 코스를 즐겼어요"
        }
    }
}

struct StampRecord: Identifiable, Codable, Hashable {
    let id: String
    let storeId: String
    let courseId: String?
    let verifiedAt: Date
    let verificationType: VerificationType
    let coordinate: CodableCoordinate
}

struct BadgeRecord: Identifiable, Codable, Hashable {
    let id: String
    let badgeType: BadgeType
    let earnedAt: Date
    let courseId: String?
}

struct RewardProgress: Identifiable, Codable, Hashable {
    let id: String
    let userId: String
    var stamps: [StampRecord]
    var badges: [BadgeRecord]
    var totalVisits: Int
    var totalCoursesCompleted: Int
    var currentSeasonId: String?
    var seasonProgress: Int
}

struct UserCourseStop: Identifiable, Codable, Hashable {
    let id: String
    let storeId: String?
    let placeName: String
    let latitude: Double
    let longitude: Double
    let stopOrder: Int
    let stayMinutes: Int
    let note: String?
    let walkingDistanceMeters: Double?
    let walkingDurationSeconds: Double?
    let tashuDurationSeconds: Double?

    var coordinate: CodableCoordinate {
        CodableCoordinate(latitude: latitude, longitude: longitude)
    }
}

struct UserGeneratedCourse: Identifiable, Codable, Hashable {
    let id: String
    let authorId: String
    let authorNickname: String
    let authorAgeGroup: AgeGroup?
    let title: String
    let description: String
    let coverImageURL: String?
    let theme: CourseTheme
    let district: District
    let tags: [String]
    let stops: [UserCourseStop]
    let visibility: CourseVisibility
    let likeCount: Int
    let viewCount: Int
    let completionCount: Int
    let createdAt: Date
    let updatedAt: Date

    var estimatedWalkingMinutes: Int {
        stops.reduce(0) { $0 + $1.stayMinutes } +
        Int(stops.compactMap(\.walkingDurationSeconds).reduce(0, +) / 60)
    }

    var estimatedTashuMinutes: Int? {
        let total = stops.compactMap(\.tashuDurationSeconds).reduce(0, +)
        guard total > 0 else { return nil }
        return Int(total / 60) + stops.reduce(0) { $0 + $1.stayMinutes }
    }

    var stopCount: Int { stops.count }
}

struct CourseLike: Identifiable, Codable, Hashable {
    let id: String
    let userId: String
    let courseId: String
    let createdAt: Date
}

struct DaejeonTags {
    static let presets: [KeywordTag] = [
        KeywordTag(id: "tag-bread-fest", name: "빵축제", category: .festival, usageCount: 12),
        KeywordTag(id: "tag-zero-fest", name: "0시축제", category: .festival, usageCount: 8),
        KeywordTag(id: "tag-cherry", name: "벚꽃축제", category: .festival, usageCount: 9),
        KeywordTag(id: "tag-eunhaeng", name: "은행동", category: .district, usageCount: 20),
        KeywordTag(id: "tag-daeheung", name: "대흥동", category: .district, usageCount: 16),
        KeywordTag(id: "tag-sunhwa", name: "선화동", category: .district, usageCount: 11),
        KeywordTag(id: "tag-night-view", name: "야경", category: .mood, usageCount: 15),
        KeywordTag(id: "tag-sensibility", name: "감성", category: .mood, usageCount: 22),
        KeywordTag(id: "tag-bread", name: "빵", category: .food, usageCount: 18),
        KeywordTag(id: "tag-local-cafe", name: "로컬카페", category: .food, usageCount: 14),
        KeywordTag(id: "tag-bar", name: "감성술집", category: .food, usageCount: 13),
        KeywordTag(id: "tag-walk", name: "골목산책", category: .activity, usageCount: 17),
        KeywordTag(id: "tag-workshop", name: "공방체험", category: .activity, usageCount: 10),
        KeywordTag(id: "tag-exhibition", name: "전시", category: .activity, usageCount: 12)
    ]
}

// MARK: - Onboarding Theme
enum OnboardingTheme: String, CaseIterable, Identifiable {
    case sensitiveCafe = "감성 카페"
    case localFood = "로컬 맛집"
    case photoSpot = "사진 스팟"
    case quietWalk = "조용한 산책"
    case dateCourse = "데이트 코스"
    case rainyDay = "비 오는 날 코스"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .sensitiveCafe: return "☕️"
        case .localFood: return "🍜"
        case .photoSpot: return "📸"
        case .quietWalk: return "🌿"
        case .dateCourse: return "💕"
        case .rainyDay: return "☔️"
        }
    }
}
