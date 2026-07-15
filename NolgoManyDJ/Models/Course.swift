import Foundation

// MARK: - Course Theme
enum CourseTheme: String, Codable, CaseIterable, Identifiable {
    case date = "데이트"
    case solo = "혼자 걷기"
    case friends = "친구와 수다"
    case rainy = "비 오는 날"
    case night = "야간 감성"
    case photo = "사진 스팟"
    case food = "맛집 투어"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .date: return "heart.fill"
        case .solo: return "figure.walk"
        case .friends: return "person.2.fill"
        case .rainy: return "cloud.rain.fill"
        case .night: return "moon.stars.fill"
        case .photo: return "camera.fill"
        case .food: return "fork.knife"
        }
    }

    var emoji: String {
        switch self {
        case .date: return "💑"
        case .solo: return "🚶"
        case .friends: return "👯"
        case .rainy: return "🌧"
        case .night: return "🌙"
        case .photo: return "📸"
        case .food: return "🍽"
        }
    }
}

// MARK: - Course Duration
enum CourseDuration: Int, CaseIterable, Identifiable {
    case oneHour = 60
    case ninetyMin = 90
    case twoHours = 120

    var id: Int { rawValue }

    var label: String {
        switch self {
        case .oneHour: return "1시간"
        case .ninetyMin: return "90분"
        case .twoHours: return "2시간"
        }
    }
}

// MARK: - Course Model
struct Course: Identifiable, Codable, Hashable {
    let id: String
    let title: String
    let slug: String
    let theme: CourseTheme
    let durationMinutes: Int
    let tashuDurationMinutes: Int?
    let district: District
    let description: String
    let coverImageURL: String
    let isFeatured: Bool
    let stops: [CourseStop]
    let tags: [String]
    let authorId: String?
    let isPublic: Bool
    let createdAt: Date

    init(
        id: String,
        title: String,
        slug: String,
        theme: CourseTheme,
        durationMinutes: Int,
        tashuDurationMinutes: Int? = nil,
        district: District,
        description: String,
        coverImageURL: String,
        isFeatured: Bool,
        stops: [CourseStop],
        tags: [String] = [],
        authorId: String? = nil,
        isPublic: Bool = true,
        createdAt: Date
    ) {
        self.id = id
        self.title = title
        self.slug = slug
        self.theme = theme
        self.durationMinutes = durationMinutes
        self.tashuDurationMinutes = tashuDurationMinutes
        self.district = district
        self.description = description
        self.coverImageURL = coverImageURL
        self.isFeatured = isFeatured
        self.stops = stops
        self.tags = tags
        self.authorId = authorId
        self.isPublic = isPublic
        self.createdAt = createdAt
    }

    var durationLabel: String {
        if durationMinutes >= 120 { return "2시간" }
        else if durationMinutes >= 90 { return "90분" }
        else { return "1시간" }
    }

    var tashuDurationLabel: String? {
        guard let tashuDurationMinutes else { return nil }
        if tashuDurationMinutes >= 120 { return "2시간" }
        if tashuDurationMinutes >= 60 { return "1시간 \(tashuDurationMinutes - 60)분" }
        return "\(tashuDurationMinutes)분"
    }

    var storeCount: Int { stops.count }
    var isUserGenerated: Bool { authorId != nil }

    func hash(into hasher: inout Hasher) { hasher.combine(id) }
    static func == (lhs: Course, rhs: Course) -> Bool { lhs.id == rhs.id }
}

// MARK: - CourseStop
struct CourseStop: Identifiable, Codable, Hashable {
    let id: String
    let courseId: String
    let storeId: String
    let stopOrder: Int
    let stayMinutes: Int
    let note: String?
    let walkingDistanceMeters: Double?
    let walkingDurationSeconds: Double?
    let tashuDurationSeconds: Double?

    init(
        id: String,
        courseId: String,
        storeId: String,
        stopOrder: Int,
        stayMinutes: Int,
        note: String?,
        walkingDistanceMeters: Double? = nil,
        walkingDurationSeconds: Double? = nil,
        tashuDurationSeconds: Double? = nil
    ) {
        self.id = id
        self.courseId = courseId
        self.storeId = storeId
        self.stopOrder = stopOrder
        self.stayMinutes = stayMinutes
        self.note = note
        self.walkingDistanceMeters = walkingDistanceMeters
        self.walkingDurationSeconds = walkingDurationSeconds
        self.tashuDurationSeconds = tashuDurationSeconds
    }

    func hash(into hasher: inout Hasher) { hasher.combine(id) }
    static func == (lhs: CourseStop, rhs: CourseStop) -> Bool { lhs.id == rhs.id }
}
