import Foundation
import CoreLocation

// MARK: - Store Category
enum StoreCategory: String, Codable, CaseIterable, Identifiable {
    case cafe = "카페"
    case restaurant = "식당"
    case attraction = "관광지"
    case festival = "축제"
    case date = "데이트"
    case family = "가족"
    case experience = "체험"
    case nightSpot = "야간명소"
    case bar = "술집"
    case shop = "소품샵"
    case workshop = "공방"
    case culture = "복합문화공간"
    case walkSpot = "산책 스팟"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .cafe: return "cup.and.saucer.fill"
        case .restaurant: return "fork.knife"
        case .attraction: return "camera.viewfinder"
        case .festival: return "sparkles"
        case .date: return "heart.fill"
        case .family: return "figure.2.and.child.holdinghands"
        case .experience: return "hand.raised.fill"
        case .nightSpot: return "moon.stars.fill"
        case .bar: return "wineglass.fill"
        case .shop: return "bag.fill"
        case .workshop: return "paintbrush.fill"
        case .culture: return "building.columns.fill"
        case .walkSpot: return "figure.walk"
        }
    }

    var accentColor: String {
        switch self {
        case .cafe: return "2E6BFF"
        case .restaurant: return "11B8D6"
        case .attraction: return "3156D4"
        case .festival: return "32E982"
        case .date: return "2E6BFF"
        case .family: return "0CA9C6"
        case .experience: return "11B8D6"
        case .nightSpot: return "061B52"
        case .bar: return "061B52"
        case .shop: return "32E982"
        case .workshop: return "0CA9C6"
        case .culture: return "3156D4"
        case .walkSpot: return "77DFF0"
        }
    }
}

// MARK: - District
enum District: String, Codable, CaseIterable, Identifiable {
    case eunhaeng = "은행동"
    case daeheung = "대흥동"
    case sunhwa = "선화동"
    case dunsan = "둔산동"
    case doryong = "도룡동"
    case sajeong = "사정동"
    case daecheong = "대덕구·동구"
    case bongmyeong = "봉명동"
    case wondong = "원동"

    var id: String { rawValue }
}

// MARK: - Store Model
struct Store: Identifiable, Codable, Hashable {
    let id: String
    let name: String
    let slug: String
    let category: StoreCategory
    let district: District
    let shortDescription: String
    let storyTitle: String
    let founderStory: String
    let signaturePoint: String
    let address: String
    let phone: String
    let openingHours: String
    let websiteURL: String?
    let instagramURL: String?
    let latitude: Double
    let longitude: Double
    let thumbnailURL: String
    let coverImageURL: String
    let menuItems: [MenuItem]
    let visitTip: String
    let nearestTashuStationId: String?
    let tags: [String]
    let createdAt: Date
    let updatedAt: Date

    init(
        id: String,
        name: String,
        slug: String,
        category: StoreCategory,
        district: District,
        shortDescription: String,
        storyTitle: String,
        founderStory: String,
        signaturePoint: String,
        address: String,
        phone: String,
        openingHours: String,
        websiteURL: String?,
        instagramURL: String?,
        latitude: Double,
        longitude: Double,
        thumbnailURL: String,
        coverImageURL: String,
        menuItems: [MenuItem],
        visitTip: String,
        nearestTashuStationId: String? = nil,
        tags: [String] = [],
        createdAt: Date,
        updatedAt: Date
    ) {
        self.id = id
        self.name = name
        self.slug = slug
        self.category = category
        self.district = district
        self.shortDescription = shortDescription
        self.storyTitle = storyTitle
        self.founderStory = founderStory
        self.signaturePoint = signaturePoint
        self.address = address
        self.phone = phone
        self.openingHours = openingHours
        self.websiteURL = websiteURL
        self.instagramURL = instagramURL
        self.latitude = latitude
        self.longitude = longitude
        self.thumbnailURL = thumbnailURL
        self.coverImageURL = coverImageURL
        self.menuItems = menuItems
        self.visitTip = visitTip
        self.nearestTashuStationId = nearestTashuStationId
        self.tags = tags
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }

    var coordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }

    var area: String { address }

    var imageUrl: String { coverImageURL }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }

    static func == (lhs: Store, rhs: Store) -> Bool {
        lhs.id == rhs.id
    }
}

// MARK: - MenuItem
struct MenuItem: Identifiable, Codable, Hashable {
    let id: String
    let name: String
    let price: String
    let isSignature: Bool
}

// MARK: - StoreImage
struct StoreImage: Identifiable, Codable {
    let id: String
    let storeId: String
    let imageURL: String
    let sortOrder: Int
    let caption: String?
}

// MARK: - Tashu Station
struct TashuStation: Identifiable, Codable, Hashable {
    let id: String
    let name: String
    let district: District
    let latitude: Double
    let longitude: Double
    let availableBikes: Int
    let availableDocks: Int
    let note: String

    var coordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }

    var availabilityAccentHex: String {
        switch availableBikes {
        case 0...2:
            return "79C8FF"
        case 3...5:
            return "67AAFF"
        default:
            return "266ACF"
        }
    }
}
