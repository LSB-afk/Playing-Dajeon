# 놀거많은대?전 — 대전 로컬 탐방 앱 종합 설계 명세서

> 작성일: 2026-04-03
> 현황 갱신: 2026-07-15
> 대상: 지원사업 발표 및 개발 가이드
> 현재 코드베이스 기반 실현 가능한 MVP + 확장 구조

---

## Part 1. 요구사항 분석

### 1.1 현재 앱 상태 (As-Is)

| 영역 | 현재 상태 | 한계 |
|------|-----------|------|
| 데이터 | MockData 22개 장소, 에디터 코스 6개, 공유 경로 예시 5개 | 램프의진희 외 대부분은 시연용 데이터, Supabase 미연동 |
| 지도 | 대전 기본 영역, 지역 우선 MKLocalSearch, 장소·타슈 탐색 | 사용자 현재 위치에 따라 대전 외로 이동 가능, 행정구역 강제 필터 미구현 |
| 이동수단 | 도보·타슈 모드, MapKit 도로 기준 ETA·순서 재계산 | 타슈 대여소·잔여 대수는 정적 예시 데이터 |
| 보상 | 로컬 방문·스탬프·뱃지·시즌 진행도 | 수동 방문 기록 기반, GPS 지오펜스 인증 미구현 |
| 코스 | 에디터 코스 6개, 공유 경로 피드·저장·상세 | 사용자 생성·게시·신고 백엔드 미구현 |
| 이미지 | 램프의진희 점주 제공 에셋 8장, Unsplash 예시 이미지, 선택적 Kakao API 보완 | 장소별 권리·일치성 검수와 점주 에셋 확보 필요 |

### 1.2 목표 상태 (To-Be)

| 영역 | MVP (4주) | 확장 (8주+) |
|------|-----------|-------------|
| 지역제한 | 대전 바운딩박스 + 주소 필터 | 행정구역 API 연동 |
| 이동수단 | 도보 + 타슈 (도보거리 기반 ETA) | 타슈 대여소 실시간 연동 |
| 보상 | GPS 지오펜스 방문 인증 + 스탬프 | 시즌 챌린지/랭킹/교환 |
| 코스공유 | 사용자 코스 생성/저장/공개 | 좋아요/정렬/키워드/연령대별 |
| 백엔드 | Supabase 기본 연동 | RLS, Edge Functions, 실시간 |

---

## Part 2. 데이터 모델 설계

### 2.1 Store (기존 수정)

```swift
// 변경 없음 - 현재 Store.swift 구조 유지
// 추가 필드만 확장
struct Store: Identifiable, Codable, Hashable {
    // ... 기존 필드 유지 ...

    // [추가] 타슈 대여소 연동
    let nearestTashuStationId: String?  // MVP: nil, 확장: 연동
}
```

**District 확장** — 현재 3개(은행동/대흥동/선화동) → 대전 5개 구 + 세부 동 추가:

```swift
enum DaejeonGu: String, Codable, CaseIterable, Identifiable {
    case jung = "중구"
    case dong = "동구"
    case seo = "서구"
    case yuseong = "유성구"
    case daedeok = "대덕구"
    var id: String { rawValue }
}

// District는 DaejeonGu 아래 세부 동네 (기존 유지 + 확장)
enum District: String, Codable, CaseIterable, Identifiable {
    case eunhaeng = "은행동"
    case daeheung = "대흥동"
    case sunhwa = "선화동"
    // [확장] 추가 동네
    case yongmun = "용문동"
    case dunsandong = "둔산동"
    case gungdong = "궁동"
    case wonam = "원남동"

    var id: String { rawValue }

    var gu: DaejeonGu {
        switch self {
        case .eunhaeng, .daeheung, .sunhwa, .yongmun, .wonam: return .jung
        case .dunsandong: return .seo
        case .gungdong: return .yuseong
        }
    }
}
```

### 2.2 Course (이동수단 개편)

```swift
// Course.swift — 이동수단 필드 추가
struct Course: Identifiable, Codable, Hashable {
    let id: String
    let title: String
    let slug: String
    let theme: CourseTheme
    let durationMinutes: Int          // 도보 기준 총 소요시간
    let tashuDurationMinutes: Int?    // [추가] 타슈 기준 총 소요시간
    let district: District
    let description: String
    let coverImageURL: String
    let isFeatured: Bool
    let stops: [CourseStop]
    let tags: [String]                // [추가] 대전 키워드 태그
    let authorId: String?             // [추가] nil = 에디터 제작, 값 = 사용자 제작
    let isPublic: Bool                // [추가] 공개 여부
    let createdAt: Date

    var durationLabel: String {
        if durationMinutes >= 120 { return "2시간" }
        else if durationMinutes >= 90 { return "90분" }
        else { return "\(durationMinutes)분" }
    }

    // [추가] 타슈 소요시간 라벨
    var tashuDurationLabel: String? {
        guard let mins = tashuDurationMinutes else { return nil }
        if mins >= 120 { return "2시간" }
        else if mins >= 60 { return "1시간 \(mins - 60)분" }
        else { return "\(mins)분" }
    }

    var storeCount: Int { stops.count }
    var isUserGenerated: Bool { authorId != nil }
}
```

### 2.3 CourseStop (ETA 이중 표시)

```swift
struct CourseStop: Identifiable, Codable, Hashable {
    let id: String
    let courseId: String
    let storeId: String
    let stopOrder: Int
    let stayMinutes: Int
    let note: String?

    // [추가] 다음 정류장까지 이동 정보
    let walkingDistanceMeters: Double?    // 도보 거리 (미터)
    let walkingDurationSeconds: Double?   // 도보 소요시간 (초)
    let tashuDurationSeconds: Double?     // 타슈 소요시간 (초, 계산값)
}
```

### 2.4 UserGeneratedCourse (신규)

```swift
// 사용자 제작 코스 — Course와 구조 공유하되 추가 메타데이터
struct UserGeneratedCourse: Identifiable, Codable {
    let id: String
    let authorId: String
    let authorNickname: String
    let authorAgeGroup: AgeGroup?
    let title: String
    let description: String
    let coverImageURL: String?
    let theme: CourseTheme
    let district: District
    let tags: [String]              // 대전 키워드 태그
    let stops: [UserCourseStop]
    let visibility: CourseVisibility
    let likeCount: Int
    let viewCount: Int
    let completionCount: Int        // 다른 사용자 완주 수
    let createdAt: Date
    let updatedAt: Date

    var estimatedWalkingMinutes: Int {
        stops.reduce(0) { $0 + $1.stayMinutes } +
        Int(stops.compactMap(\.walkingDurationSeconds).reduce(0, +) / 60)
    }
}

struct UserCourseStop: Identifiable, Codable {
    let id: String
    let storeId: String?             // 앱 내 등록 가게 (있으면)
    let placeName: String            // 가게명 또는 직접 입력
    let latitude: Double
    let longitude: Double
    let stopOrder: Int
    let stayMinutes: Int
    let note: String?
    let walkingDistanceMeters: Double?
    let walkingDurationSeconds: Double?
    let tashuDurationSeconds: Double?
}

enum CourseVisibility: String, Codable {
    case privateOnly = "private"    // 나만 보기
    case publicOpen = "public"      // 전체 공개
    case linkOnly = "link"          // 링크 공유만
}

enum AgeGroup: String, Codable, CaseIterable, Identifiable {
    case teens = "10대"
    case twenties = "20대"
    case thirties = "30대"
    case forties = "40대"
    case fiftyPlus = "50대 이상"
    var id: String { rawValue }
}
```

### 2.5 CourseLike (신규)

```swift
struct CourseLike: Identifiable, Codable {
    let id: String
    let userId: String
    let courseId: String             // UserGeneratedCourse.id
    let createdAt: Date
}
```

### 2.6 RewardProgress (신규 — 보상 시스템)

```swift
// 사용자 보상 진행 상태
struct RewardProgress: Identifiable, Codable {
    let id: String
    let userId: String
    var stamps: [StampRecord]        // 스탬프 기록
    var badges: [BadgeRecord]        // 획득 뱃지
    var totalVisits: Int             // 총 방문 수
    var totalCoursesCompleted: Int   // 총 코스 완주 수
    var currentSeasonId: String?     // 현재 참여 시즌
    var seasonProgress: Int          // 시즌 진행도 (0~100)
}

struct StampRecord: Identifiable, Codable {
    let id: String
    let storeId: String
    let courseId: String?            // 코스 일부로 방문했으면
    let verifiedAt: Date
    let verificationType: VerificationType
    let coordinate: CodableCoordinate  // 인증 위치
}

struct BadgeRecord: Identifiable, Codable {
    let id: String
    let badgeType: BadgeType
    let earnedAt: Date
    let courseId: String?            // 어떤 코스 완주로 획득했는지
}

enum BadgeType: String, Codable, CaseIterable {
    // 코스 완주 뱃지
    case firstCourse = "첫 코스 완주"
    case fiveCourses = "5코스 탐험가"
    case tenCourses = "10코스 마스터"

    // 지역 뱃지
    case eunhaengMaster = "은행동 전문가"
    case daeheungMaster = "대흥동 전문가"
    case sunhwaMaster = "선화동 전문가"

    // 테마 뱃지
    case nightOwl = "야행성 탐험가"      // 야간 코스 3개 완주
    case rainyDayWalker = "비의 낭만"    // 비오는날 코스 2개 완주
    case foodHunter = "대전 미식가"      // 맛집 코스 3개 완주

    // 시즌 뱃지
    case breadFestival2026 = "빵축제 2026"
    case cherryBlossom2026 = "벚꽃 시즌 2026"

    var icon: String {
        switch self {
        case .firstCourse: return "star.fill"
        case .fiveCourses: return "star.circle.fill"
        case .tenCourses: return "crown.fill"
        case .eunhaengMaster: return "building.2.fill"
        case .daeheungMaster: return "building.2.fill"
        case .sunhwaMaster: return "building.2.fill"
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
        case .eunhaengMaster: return "은행동 가게를 5곳 이상 방문했어요"
        case .daeheungMaster: return "대흥동 가게를 5곳 이상 방문했어요"
        case .sunhwaMaster: return "선화동 가게를 5곳 이상 방문했어요"
        case .nightOwl: return "야간 감성 코스 3개를 완주했어요"
        case .rainyDayWalker: return "비 오는 날에도 탐방을 멈추지 않은 당신"
        case .foodHunter: return "맛집 코스 3개 완주! 대전 미식가 인정"
        case .breadFestival2026: return "2026 대전 빵축제 기간 코스 완주"
        case .cherryBlossom2026: return "2026 벚꽃 시즌 코스 완주"
        }
    }
}

struct CodableCoordinate: Codable {
    let latitude: Double
    let longitude: Double
}
```

### 2.7 CompletionProof (신규 — 완수 인증)

```swift
struct CompletionProof: Identifiable, Codable {
    let id: String
    let userId: String
    let courseId: String
    let stopProofs: [StopProof]      // 각 정류장별 인증
    let isComplete: Bool             // 모든 정류장 인증 완료?
    let completedAt: Date?
    let startedAt: Date
}

struct StopProof: Identifiable, Codable {
    let id: String
    let storeId: String
    let verifiedAt: Date?
    let verificationType: VerificationType?
    let coordinate: CodableCoordinate?
    let isVerified: Bool
}
```

### 2.8 KeywordTag (신규 — 대전 특화 태그)

```swift
struct KeywordTag: Identifiable, Codable, Hashable {
    let id: String
    let name: String
    let category: TagCategory
    let usageCount: Int              // 사용 횟수 (인기순 정렬용)

    static func == (lhs: KeywordTag, rhs: KeywordTag) -> Bool { lhs.id == rhs.id }
    func hash(into hasher: inout Hasher) { hasher.combine(id) }
}

enum TagCategory: String, Codable, CaseIterable {
    case festival = "축제"     // 빵축제, 영시축제, 벚꽃축제
    case district = "동네"     // 대흥동, 은행동, 둔산동
    case mood = "분위기"       // 야경, 감성, 레트로, 빈티지
    case food = "먹거리"       // 빵, 국밥, 수제맥주, 한식
    case activity = "활동"     // 산책, 체험, 공방, 전시
    case season = "시즌"       // 봄, 여름, 가을, 겨울
}

// 대전 기본 태그 프리셋
struct DaejeonTags {
    static let presets: [KeywordTag] = [
        // 축제
        KeywordTag(id: "tag-bread-fest", name: "빵축제", category: .festival, usageCount: 0),
        KeywordTag(id: "tag-zero-fest", name: "0시축제", category: .festival, usageCount: 0),
        KeywordTag(id: "tag-cherry", name: "벚꽃축제", category: .festival, usageCount: 0),
        KeywordTag(id: "tag-science", name: "사이언스페스티벌", category: .festival, usageCount: 0),

        // 동네
        KeywordTag(id: "tag-eunhaeng", name: "은행동", category: .district, usageCount: 0),
        KeywordTag(id: "tag-daeheung", name: "대흥동", category: .district, usageCount: 0),
        KeywordTag(id: "tag-sunhwa", name: "선화동", category: .district, usageCount: 0),
        KeywordTag(id: "tag-dunsan", name: "둔산동", category: .district, usageCount: 0),
        KeywordTag(id: "tag-gungdong", name: "궁동", category: .district, usageCount: 0),

        // 분위기
        KeywordTag(id: "tag-night-view", name: "야경", category: .mood, usageCount: 0),
        KeywordTag(id: "tag-retro", name: "레트로", category: .mood, usageCount: 0),
        KeywordTag(id: "tag-quiet", name: "조용한", category: .mood, usageCount: 0),
        KeywordTag(id: "tag-sensibility", name: "감성", category: .mood, usageCount: 0),

        // 먹거리
        KeywordTag(id: "tag-bread", name: "빵", category: .food, usageCount: 0),
        KeywordTag(id: "tag-local-cafe", name: "로컬카페", category: .food, usageCount: 0),
        KeywordTag(id: "tag-bar", name: "감성술집", category: .food, usageCount: 0),
        KeywordTag(id: "tag-gukbap", name: "국밥", category: .food, usageCount: 0),
        KeywordTag(id: "tag-craft-beer", name: "수제맥주", category: .food, usageCount: 0),

        // 활동
        KeywordTag(id: "tag-walk", name: "골목산책", category: .activity, usageCount: 0),
        KeywordTag(id: "tag-workshop", name: "공방체험", category: .activity, usageCount: 0),
        KeywordTag(id: "tag-exhibition", name: "전시", category: .activity, usageCount: 0),
        KeywordTag(id: "tag-photo", name: "포토스팟", category: .activity, usageCount: 0),
    ]
}
```

### 2.9 TashuStation (신규)

```swift
struct TashuStation: Identifiable, Codable {
    let id: String
    let name: String
    let latitude: Double
    let longitude: Double
    let totalDocks: Int
    let availableBikes: Int?         // MVP: nil (정적), 확장: 실시간

    var coordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }
}
```

---

## Part 3. 지도/검색 처리 구조 — 대전 지역 제한

### 3.1 대전 바운딩 박스 정의

```swift
// DaejeonRegion.swift (신규 파일)
import MapKit

struct DaejeonRegion {
    // 대전광역시 전체 좌표 범위
    static let north = 36.4800    // 유성구 북단
    static let south = 36.2300    // 동구 남단
    static let east  = 127.5500   // 동구 동단
    static let west  = 127.2800   // 서구 서단

    // 중심점
    static let center = CLLocationCoordinate2D(
        latitude: 36.3504, longitude: 127.3845
    )

    // 원도심 중심 (앱 기본 포커스)
    static let downtownCenter = CLLocationCoordinate2D(
        latitude: 36.3270, longitude: 127.4230
    )

    // 검색/지도 기본 region
    static let defaultRegion = MKCoordinateRegion(
        center: downtownCenter,
        span: MKCoordinateSpan(latitudeDelta: 0.015, longitudeDelta: 0.015)
    )

    // 대전 전체 region (검색 범위 제한용)
    static let searchBounds = MKCoordinateRegion(
        center: center,
        span: MKCoordinateSpan(latitudeDelta: 0.26, longitudeDelta: 0.28)
    )

    /// 좌표가 대전 범위 안인지 확인
    static func contains(_ coordinate: CLLocationCoordinate2D) -> Bool {
        coordinate.latitude >= south &&
        coordinate.latitude <= north &&
        coordinate.longitude >= west &&
        coordinate.longitude <= east
    }

    /// 주소 문자열이 대전인지 확인
    static func isDaejeonAddress(_ address: String) -> Bool {
        let daejeonKeywords = ["대전", "대전광역시", "Daejeon"]
        return daejeonKeywords.contains { address.contains($0) }
    }

    /// MKMapItem이 대전 범위인지 확인 (좌표 + 주소 이중 체크)
    static func isInDaejeon(_ mapItem: MKMapItem) -> Bool {
        let coord = mapItem.placemark.coordinate
        // 1차: 좌표 바운딩 박스 체크
        if contains(coord) { return true }
        // 2차: 주소 문자열 체크 (좌표가 경계선에 있을 수 있음)
        if let address = mapItem.placemark.title, isDaejeonAddress(address) {
            return true
        }
        if let locality = mapItem.placemark.locality, isDaejeonAddress(locality) {
            return true
        }
        return false
    }
}
```

### 3.2 검색 필터링 방식 비교

| 방식 | 장점 | 단점 | MVP 채택 |
|------|------|------|----------|
| **좌표 바운딩 박스** | 구현 간단, 빠름 | 대전 경계 미세 오차 | **채택** |
| **행정구역 API (VWorld)** | 정확한 행정경계 | 외부 API 의존, 느림 | 확장 |
| **주소 문자열 보정** | 보조 필터로 유용 | 단독 사용 불가 | **보조 채택** |
| **MKLocalSearch region 제한** | MapKit 내장 | region 힌트일 뿐 강제 아님 | **채택** |

**MVP 전략**: `MKLocalSearch.region` + `바운딩 박스 후처리` + `주소 문자열 보조 체크`

### 3.3 MapSearchController 수정안

```swift
// MapExploreView.swift 내 MapSearchController 수정

func search(for query: String, region: MKCoordinateRegion) async {
    isSearching = true
    defer { isSearching = false }

    let request = MKLocalSearch.Request()
    request.naturalLanguageQuery = query
    request.resultTypes = [.pointOfInterest]
    // [핵심] region을 대전으로 강제 제한
    request.region = DaejeonRegion.searchBounds

    let search = MKLocalSearch(request: request)
    let response = try? await search.start()

    // [핵심] 대전 범위 밖 결과 필터링
    let filtered = (response?.mapItems ?? []).filter {
        DaejeonRegion.isInDaejeon($0)
    }
    results = normalizedResults(from: filtered)
    completions = []
}

func searchNearby(category: StoreCategory?, region: MKCoordinateRegion) async {
    isLoadingNearby = true
    defer { isLoadingNearby = false }

    let request = MKLocalSearch.Request()
    // [핵심] 대전 범위 안에서만 검색
    request.region = DaejeonRegion.searchBounds
    request.resultTypes = .pointOfInterest
    request.pointOfInterestFilter = category?.pointOfInterestFilter
        ?? .defaultNearbyFilter

    let search = MKLocalSearch(request: request)
    let response = try? await search.start()

    // [핵심] 후처리 필터
    let filtered = (response?.mapItems ?? []).filter {
        DaejeonRegion.isInDaejeon($0)
    }
    nearbyResults = normalizedResults(from: filtered)
}
```

### 3.4 MKLocalSearchCompleter 대전 제한

```swift
// MapSearchController init에서:
override init() {
    super.init()
    completer.delegate = self
    completer.resultTypes = [.pointOfInterest]
    // [핵심] 자동완성 범위를 대전으로 제한
    completer.region = DaejeonRegion.searchBounds
    if #available(iOS 18.0, *) {
        completer.regionPriority = .required  // iOS 18+: 필수로 적용
    }
}
```

### 3.5 대전 외 검색 시 UX

```
검색: "강남 카페"
→ 결과 0건
→ 빈 상태 문구: "대전 밖의 장소는 표시되지 않아요 🗺️
   이 앱은 대전 원도심 특화 탐방 앱이에요.
   '은행동 카페' 또는 '대흥동 맛집'으로 검색해 보세요."
```

---

## Part 4. 코스 ETA 계산 구조 — 도보 + 타슈

### 4.1 이동수단 개편

```swift
// 기존 RouteTransportMode 교체
enum RouteTransportMode: String, CaseIterable, Identifiable {
    case walking = "도보"
    case tashu = "타슈"              // [변경] automobile/transit → tashu

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .walking: return "figure.walk"
        case .tashu: return "bicycle"    // SF Symbol 자전거
        }
    }

    // MapKit은 자전거 경로를 직접 지원하지 않으므로
    // 도보 경로를 가져온 후 속도만 보정
    var transportType: MKDirectionsTransportType {
        return .walking  // 타슈도 도보 경로 기반
    }

    // 타슈는 Apple Maps 길찾기 불가 → 도보로 대체
    var launchOption: String {
        return MKLaunchOptionsDirectionsModeWalking
    }
}
```

### 4.2 타슈 ETA 계산 로직

```swift
// TashuETACalculator.swift (신규 파일)
import Foundation

struct TashuETACalculator {
    // 타슈 평균 속도: 12 km/h (도심 기준 보수적 추정)
    static let tashuSpeedKmH: Double = 12.0
    // 도보 평균 속도: 4.5 km/h
    static let walkingSpeedKmH: Double = 4.5
    // 타슈 대여/반납 오버헤드: 2분 (잠금해제, 주차)
    static let tashuOverheadSeconds: TimeInterval = 120

    /// 도보 거리(미터)와 도보 소요시간(초)으로 타슈 ETA 계산
    static func calculateTashuETA(
        walkingDistanceMeters: Double,
        walkingDurationSeconds: TimeInterval
    ) -> TashuETAResult {
        // 방법 1: 거리 기반 (더 정확)
        let tashuRidingSeconds = (walkingDistanceMeters / 1000.0)
            / tashuSpeedKmH * 3600.0

        // 방법 2: 속도 비율 기반 (도보 시간 * 보정 계수)
        // let speedRatio = walkingSpeedKmH / tashuSpeedKmH  // 0.375
        // let tashuByRatio = walkingDurationSeconds * speedRatio

        let totalTashuSeconds = tashuRidingSeconds + tashuOverheadSeconds
        let timeSavedSeconds = walkingDurationSeconds - totalTashuSeconds

        return TashuETAResult(
            walkingDistanceMeters: walkingDistanceMeters,
            walkingDurationSeconds: walkingDurationSeconds,
            tashuDurationSeconds: max(totalTashuSeconds, 60), // 최소 1분
            tashuRidingSeconds: tashuRidingSeconds,
            overheadSeconds: tashuOverheadSeconds,
            timeSavedSeconds: max(timeSavedSeconds, 0)
        )
    }
}

struct TashuETAResult {
    let walkingDistanceMeters: Double
    let walkingDurationSeconds: TimeInterval
    let tashuDurationSeconds: TimeInterval      // 총 타슈 시간 (대여+이동+반납)
    let tashuRidingSeconds: TimeInterval         // 순수 라이딩 시간
    let overheadSeconds: TimeInterval            // 대여/반납 시간
    let timeSavedSeconds: TimeInterval           // 도보 대비 절약 시간

    var walkingLabel: String { formatDuration(walkingDurationSeconds) }
    var tashuLabel: String { formatDuration(tashuDurationSeconds) }
    var savedLabel: String { formatDuration(timeSavedSeconds) }

    private func formatDuration(_ seconds: TimeInterval) -> String {
        let minutes = Int(seconds / 60)
        if minutes < 1 { return "1분 미만" }
        if minutes >= 60 {
            return "\(minutes / 60)시간 \(minutes % 60)분"
        }
        return "\(minutes)분"
    }
}
```

### 4.3 ETA 표시 예시

```
[코스 카드]
┌─────────────────────────┐
│ 🚶 도보 90분  🚲 타슈 45분 │
│ 3곳 방문 · 은행동         │
└─────────────────────────┘

[코스 상세 — 구간별]
1. 골목다방 (30분 체류)
      ↓ 도보 8분 · 타슈 3분 (650m)
2. 활자공방 (40분 체류)
      ↓ 도보 5분 · 타슈 2분 (400m)
3. 소풍식탁 (20분 체류)
```

### 4.4 RoutePlannerService 수정

```swift
// DataService.swift — RoutePlannerService 수정

// buildLegs에서 타슈 ETA도 함께 계산
private func buildLegs(...) async -> [RoutePlannerLeg] {
    // ... 기존 MKDirections 도보 경로 계산 ...

    // [추가] 각 leg에 타슈 ETA 추가 계산
    let tashuETA = TashuETACalculator.calculateTashuETA(
        walkingDistanceMeters: route?.distance ?? 0,
        walkingDurationSeconds: route?.expectedTravelTime ?? 0
    )

    legs.append(RoutePlannerLeg(
        // ... 기존 필드 ...
        tashuDurationSeconds: tashuETA.tashuDurationSeconds  // [추가]
    ))
}
```

**RoutePlannerLeg 확장**:
```swift
struct RoutePlannerLeg {
    let source: RoutePlannerStop?
    let destination: RoutePlannerStop
    let route: MKRoute?
    let expectedTravelTime: TimeInterval       // 도보
    let tashuTravelTime: TimeInterval?         // [추가] 타슈
    let distance: CLLocationDistance
    let departureDate: Date
    let arrivalDate: Date
    let nextDepartureDate: Date
}
```

---

## Part 5. 완수 인증 로직

### 5.1 인증 방식 비교

| 방식 | 정확도 | 구현난이도 | 점주 개입 | 배터리 | MVP |
|------|--------|-----------|----------|--------|-----|
| **GPS 지오펜스 (50m)** | ★★★★ | 중 | 없음 | 중 | **채택** |
| GPS + 체류시간 (3분) | ★★★★★ | 중 | 없음 | 중 | **채택** |
| QR 코드 스캔 | ★★★★★ | 높 | **필요** | 낮 | 제외 |
| NFC 태깅 | ★★★★★ | 높 | **필요** | 낮 | 제외 |
| 방문 조합 (N곳 중 M곳) | ★★★ | 낮 | 없음 | 낮 | **보조 채택** |
| 사진 인증 + AI | ★★★ | 매우 높 | 없음 | 낮 | 확장 |

### 5.2 MVP 인증 플로우

```
사용자가 "코스 시작" 버튼 탭
    → CompletionProof 생성 (startedAt = now)
    → 각 StopProof 생성 (isVerified = false)

사용자가 가게 50m 반경 진입 (CLLocationManager 모니터링)
    → 3분 타이머 시작
    → 3분 경과 시:
        StopProof.isVerified = true
        StopProof.verifiedAt = now
        StopProof.coordinate = 현재좌표
        StopProof.verificationType = .location
    → 앱 내 "🎉 골목다방 방문 인증!" 토스트 표시

모든 StopProof.isVerified == true
    → CompletionProof.isComplete = true
    → CompletionProof.completedAt = now
    → BadgeRecord 생성 (조건 충족 시)
    → StampRecord 추가
    → "🏆 코스 완주! 뱃지를 획득했어요" 화면 표시
```

### 5.3 위치 인증 서비스

```swift
// LocationVerificationService.swift (신규)
import CoreLocation

@MainActor
@Observable
final class LocationVerificationService: NSObject, CLLocationManagerDelegate {
    static let shared = LocationVerificationService()

    private let manager = CLLocationManager()
    private let verificationRadius: CLLocationDistance = 50  // 50미터
    private let minimumStaySeconds: TimeInterval = 180      // 3분

    var activeProof: CompletionProof?
    var currentVerifications: [String: StopVerificationState] = [:]

    struct StopVerificationState {
        let storeId: String
        let coordinate: CLLocationCoordinate2D
        var enteredAt: Date?
        var isWithinRange: Bool = false
        var isVerified: Bool = false
    }

    /// 코스 시작 — 각 가게에 대한 지오펜스 등록
    func startCourseVerification(
        course: Course,
        stores: [(stop: CourseStop, store: Store)]
    ) {
        // 기존 모니터링 정리
        stopAllMonitoring()

        // CompletionProof 생성
        activeProof = CompletionProof(
            id: UUID().uuidString,
            userId: "local-user",
            courseId: course.id,
            stopProofs: stores.map { item in
                StopProof(
                    id: UUID().uuidString,
                    storeId: item.store.id,
                    verifiedAt: nil,
                    verificationType: nil,
                    coordinate: nil,
                    isVerified: false
                )
            },
            isComplete: false,
            completedAt: nil,
            startedAt: Date()
        )

        // 각 가게 지오펜스 등록
        for item in stores {
            let region = CLCircularRegion(
                center: item.store.coordinate,
                radius: verificationRadius,
                identifier: item.store.id
            )
            region.notifyOnEntry = true
            region.notifyOnExit = true
            manager.startMonitoring(for: region)

            currentVerifications[item.store.id] = StopVerificationState(
                storeId: item.store.id,
                coordinate: item.store.coordinate
            )
        }
    }

    /// CLLocationManager — 지오펜스 진입
    nonisolated func locationManager(
        _ manager: CLLocationManager,
        didEnterRegion region: CLRegion
    ) {
        Task { @MainActor in
            guard var state = currentVerifications[region.identifier] else { return }
            state.isWithinRange = true
            state.enteredAt = Date()
            currentVerifications[region.identifier] = state

            // 3분 후 자동 인증
            scheduleVerification(for: region.identifier)
        }
    }

    /// CLLocationManager — 지오펜스 이탈
    nonisolated func locationManager(
        _ manager: CLLocationManager,
        didExitRegion region: CLRegion
    ) {
        Task { @MainActor in
            guard var state = currentVerifications[region.identifier] else { return }
            state.isWithinRange = false
            state.enteredAt = nil
            currentVerifications[region.identifier] = state
        }
    }

    private func scheduleVerification(for storeId: String) {
        Task {
            try? await Task.sleep(for: .seconds(minimumStaySeconds))
            guard let state = currentVerifications[storeId],
                  state.isWithinRange,
                  !state.isVerified else { return }

            // 인증 완료!
            var updated = state
            updated.isVerified = true
            currentVerifications[storeId] = updated

            // CompletionProof 업데이트
            updateProof(storeId: storeId)
        }
    }

    private func updateProof(storeId: String) {
        guard var proof = activeProof else { return }
        var proofs = proof.stopProofs
        if let index = proofs.firstIndex(where: { $0.storeId == storeId }) {
            let location = manager.location
            proofs[index] = StopProof(
                id: proofs[index].id,
                storeId: storeId,
                verifiedAt: Date(),
                verificationType: .location,
                coordinate: location.map {
                    CodableCoordinate(
                        latitude: $0.coordinate.latitude,
                        longitude: $0.coordinate.longitude
                    )
                },
                isVerified: true
            )
        }
        // 모든 정류장 인증 완료 체크
        let allVerified = proofs.allSatisfy(\.isVerified)
        activeProof = CompletionProof(
            id: proof.id,
            userId: proof.userId,
            courseId: proof.courseId,
            stopProofs: proofs,
            isComplete: allVerified,
            completedAt: allVerified ? Date() : nil,
            startedAt: proof.startedAt
        )
    }

    func stopAllMonitoring() {
        for region in manager.monitoredRegions {
            manager.stopMonitoring(for: region)
        }
        currentVerifications.removeAll()
    }
}
```

### 5.4 보상 엔진

```swift
// RewardEngine.swift (신규)
struct RewardEngine {
    /// 코스 완주 후 뱃지 검사
    static func checkBadges(
        for userId: String,
        progress: RewardProgress,
        completedCourse: Course
    ) -> [BadgeType] {
        var newBadges: [BadgeType] = []
        let existingTypes = Set(progress.badges.map(\.badgeType))

        // 코스 완주 수 기반
        let total = progress.totalCoursesCompleted + 1
        if total >= 1 && !existingTypes.contains(.firstCourse) {
            newBadges.append(.firstCourse)
        }
        if total >= 5 && !existingTypes.contains(.fiveCourses) {
            newBadges.append(.fiveCourses)
        }
        if total >= 10 && !existingTypes.contains(.tenCourses) {
            newBadges.append(.tenCourses)
        }

        // 테마 기반 (야간 3개, 비오는날 2개, 맛집 3개)
        // → visits와 courses를 조합해서 카운트

        // 지역 기반 (은행동 5곳 이상 방문)
        // → stamps에서 해당 district 가게 카운트

        // 시즌 뱃지 (기간 내 특정 코스 완주)
        let now = Date()
        // 예: 빵축제 2026.04.01 ~ 2026.04.30
        // if 빵축제 기간 && 빵축제 코스 완주 → .breadFestival2026

        return newBadges
    }
}
```

---

## Part 6. API / 데이터 계층 구조

### 6.1 계층 다이어그램

```
┌────────────────────────────────────────────┐
│                   View Layer               │
│  HomeView · MapExploreView · CourseDetail  │
│  StoreDetail · RewardView · ShareView      │
└─────────────────┬──────────────────────────┘
                  │
┌─────────────────▼──────────────────────────┐
│               ViewModel Layer              │
│  AppState · CourseViewModel                │
│  RewardViewModel · ShareViewModel          │
└─────────────────┬──────────────────────────┘
                  │
┌─────────────────▼──────────────────────────┐
│              Service Layer                 │
│  LocationVerificationService               │
│  TashuETACalculator                        │
│  KakaoImageService                         │
│  RewardEngine                              │
│  DaejeonRegion (검색 필터)                  │
└─────────────────┬──────────────────────────┘
                  │
┌─────────────────▼──────────────────────────┐
│             Repository Layer               │
│  DataServiceProtocol                       │
│   ├─ MockDataService (현재)                │
│   └─ SupabaseDataService (확장)            │
└─────────────────┬──────────────────────────┘
                  │
┌─────────────────▼──────────────────────────┐
│              Data Source                    │
│  MockData (정적)                            │
│  UserDefaults (로컬 저장)                   │
│  Supabase (확장: 원격 DB)                   │
│  MapKit (실제 장소 검색)                    │
│  Kakao API (이미지)                         │
│  타슈 API (확장: 실시간 대여현황)            │
└────────────────────────────────────────────┘
```

### 6.2 DataServiceProtocol 확장

```swift
protocol DataServiceProtocol {
    // 기존
    func fetchStores() async -> [Store]
    func fetchStore(byId id: String) async -> Store?
    func fetchCourses() async -> [Course]
    func fetchCourse(byId id: String) async -> Course?

    // [추가] 사용자 코스
    func fetchUserCourses(
        sortBy: CourseSortOption,
        tags: [String],
        ageGroup: AgeGroup?
    ) async -> [UserGeneratedCourse]
    func createUserCourse(_ course: UserGeneratedCourse) async throws
    func toggleLike(courseId: String, userId: String) async throws

    // [추가] 보상
    func fetchRewardProgress(userId: String) async -> RewardProgress?
    func saveCompletionProof(_ proof: CompletionProof) async throws
    func saveBadge(_ badge: BadgeRecord, userId: String) async throws

    // [추가] 타슈
    func fetchTashuStations() async -> [TashuStation]
}

enum CourseSortOption: String, CaseIterable {
    case popular = "인기순"
    case latest = "최신순"
    case mostCompleted = "완주순"
}
```

### 6.3 Supabase 테이블 구조 (확장 시)

```sql
-- 사용자 코스
CREATE TABLE user_courses (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    author_id UUID REFERENCES auth.users(id),
    author_nickname TEXT NOT NULL,
    author_age_group TEXT,
    title TEXT NOT NULL,
    description TEXT,
    cover_image_url TEXT,
    theme TEXT NOT NULL,
    district TEXT NOT NULL,
    tags TEXT[] DEFAULT '{}',
    visibility TEXT DEFAULT 'public',
    like_count INT DEFAULT 0,
    view_count INT DEFAULT 0,
    completion_count INT DEFAULT 0,
    created_at TIMESTAMPTZ DEFAULT now(),
    updated_at TIMESTAMPTZ DEFAULT now()
);

-- 코스 정류장
CREATE TABLE user_course_stops (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    course_id UUID REFERENCES user_courses(id) ON DELETE CASCADE,
    store_id TEXT,
    place_name TEXT NOT NULL,
    latitude DOUBLE PRECISION NOT NULL,
    longitude DOUBLE PRECISION NOT NULL,
    stop_order INT NOT NULL,
    stay_minutes INT DEFAULT 30,
    note TEXT,
    walking_distance_meters DOUBLE PRECISION,
    walking_duration_seconds DOUBLE PRECISION,
    tashu_duration_seconds DOUBLE PRECISION
);

-- 좋아요
CREATE TABLE course_likes (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES auth.users(id),
    course_id UUID REFERENCES user_courses(id) ON DELETE CASCADE,
    created_at TIMESTAMPTZ DEFAULT now(),
    UNIQUE(user_id, course_id)
);

-- 보상 진행
CREATE TABLE reward_progress (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES auth.users(id) UNIQUE,
    total_visits INT DEFAULT 0,
    total_courses_completed INT DEFAULT 0,
    current_season_id TEXT
);

-- 스탬프
CREATE TABLE stamps (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES auth.users(id),
    store_id TEXT NOT NULL,
    course_id TEXT,
    verified_at TIMESTAMPTZ DEFAULT now(),
    verification_type TEXT NOT NULL,
    latitude DOUBLE PRECISION,
    longitude DOUBLE PRECISION
);

-- 뱃지
CREATE TABLE badges (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES auth.users(id),
    badge_type TEXT NOT NULL,
    earned_at TIMESTAMPTZ DEFAULT now(),
    course_id TEXT,
    UNIQUE(user_id, badge_type)
);
```

---

## Part 7. SwiftUI 화면 반영 포인트

### 7.1 수정 대상 파일 매핑

| 파일 | 변경 내용 | 우선순위 |
|------|-----------|----------|
| `MapExploreView.swift` | DaejeonRegion 필터 적용, 이동수단 도보/타슈로 교체, 검색 UX | P0 |
| `CourseDetailView.swift` | transportMode picker 도보/타슈, 타슈 ETA 표시, 완주 시작 버튼 | P0 |
| `HomeView.swift` | 시즌 챌린지 배너, 인기 사용자 코스 섹션 추가 | P1 |
| `CoursesView.swift` | 사용자 코스 탭 추가, 태그 필터, 정렬 | P1 |
| `StoreDetailView.swift` | 방문 인증 상태 표시, 스탬프 아이콘 | P1 |
| `MyPageView.swift` | 뱃지 그리드, 스탬프 맵, 완주 기록, 나의 코스 | P1 |
| `AppState.swift` | RewardProgress, CompletionProof 상태 추가 | P0 |
| `DataService.swift` | 이동수단 개편, 타슈 ETA, 사용자 코스 프로토콜 | P0 |

### 7.2 신규 파일

| 파일 | 설명 |
|------|------|
| `DaejeonRegion.swift` | 대전 바운딩 박스, 좌표/주소 검증 |
| `TashuETACalculator.swift` | 타슈 ETA 계산 로직 |
| `LocationVerificationService.swift` | GPS 지오펜스 기반 방문 인증 |
| `RewardEngine.swift` | 뱃지 판정 로직 |
| `Views/Reward/RewardView.swift` | 뱃지/스탬프/랭킹 화면 |
| `Views/Reward/BadgeDetailView.swift` | 뱃지 상세 |
| `Views/Courses/CreateCourseView.swift` | 사용자 코스 만들기 |
| `Views/Courses/SharedCoursesView.swift` | 커뮤니티 코스 탐색 |
| `Views/Courses/CourseCompletionView.swift` | 완주 축하 화면 |
| `Components/TashuETALabel.swift` | 도보/타슈 ETA 비교 컴포넌트 |
| `Components/BadgeCard.swift` | 뱃지 표시 컴포넌트 |
| `Components/StampMapView.swift` | 스탬프 지도 컴포넌트 |
| `Components/ProgressRing.swift` | 코스 진행률 링 |

### 7.3 핵심 UI 컴포넌트

**TashuETALabel** — 도보/타슈 ETA 비교 표시:
```swift
struct TashuETALabel: View {
    let walkingMinutes: Int
    let tashuMinutes: Int?

    var body: some View {
        HStack(spacing: 12) {
            // 도보
            HStack(spacing: 4) {
                Image(systemName: "figure.walk")
                    .font(.system(size: 12))
                Text("\(walkingMinutes)분")
                    .font(AppFont.label(13))
            }
            .foregroundStyle(.appTextPrimary)

            // 타슈
            if let tashu = tashuMinutes {
                HStack(spacing: 4) {
                    Image(systemName: "bicycle")
                        .font(.system(size: 12))
                    Text("\(tashu)분")
                        .font(AppFont.label(13))
                }
                .foregroundStyle(.appPrimary)
            }
        }
    }
}
```

**ProgressRing** — 코스 진행률:
```swift
struct ProgressRing: View {
    let progress: Double  // 0.0 ~ 1.0
    let total: Int
    let completed: Int

    var body: some View {
        ZStack {
            Circle()
                .stroke(.appSurfaceDim, lineWidth: 6)
            Circle()
                .trim(from: 0, to: progress)
                .stroke(.appPrimary, style: StrokeStyle(
                    lineWidth: 6, lineCap: .round
                ))
                .rotationEffect(.degrees(-90))

            VStack(spacing: 2) {
                Text("\(completed)/\(total)")
                    .font(AppFont.heading(18))
                    .foregroundStyle(.appTextPrimary)
                Text("완료")
                    .font(AppFont.caption(11))
                    .foregroundStyle(.appTextSecondary)
            }
        }
        .frame(width: 72, height: 72)
    }
}
```

---

## Part 8. 서비스 기획

### 8.1 서비스 개선 방향 요약

> **핵심 가치**: "대전 골목을 걸으면 보상이 쌓인다"

| 방향 | 설명 | 사용자 가치 |
|------|------|------------|
| 대전 특화 | 모든 경험이 대전 안에서만 작동 | "이 앱은 대전을 진짜 잘 안다" |
| 탐방 보상 | 걸으면 스탬프, 완주하면 뱃지 | "한 곳 더 가볼까?" 동기부여 |
| 타슈 연동 | 대전만의 이동수단 | "대전답다" 차별화 |
| 코스 공유 | 내 코스를 자랑하고 남의 코스를 따라감 | 커뮤니티 + 재방문 |
| 시즌 이벤트 | 빵축제, 벚꽃 등 시즌 한정 | 앱 재방문율 + 바이럴 |

### 8.2 요구사항별 기능 정의

#### A. 참여 유도 장치

**스탬프**: 가게 방문 시 자동 수집 (GPS 인증)
- 사용자 액션: 코스 시작 → 걸어서 이동 → 가게 50m 반경 3분 체류 → 자동 인증
- 점주 액션: **없음** (점주 앱 설치, QR 부착 등 불필요)
- 운영 액션: 가게 좌표 등록만 하면 됨

**뱃지**: 조건 달성 시 자동 획득
- 1/5/10 코스 완주, 지역별 5곳 방문, 테마별 3코스 완주, 시즌 한정
- 마이페이지에 뱃지 그리드 표시

**시즌 챌린지**: 기간 한정 미션
- 예: "빵축제 시즌 (4.1~4.30) — 빵축제 코스 2개 완주하면 '빵 마스터' 뱃지!"
- 홈 화면 배너로 노출, 기간 종료 후 재획득 불가 (희소성)

**랭킹** (확장):
- 월간 완주 수 기준 상위 10명 노출
- "이달의 대전 탐험가" 타이틀

#### B. 지도/검색 대전 제한

**검색 정책**:
- 모든 MKLocalSearch에 `DaejeonRegion.searchBounds` 적용
- 검색 결과 후처리: 대전 바운딩 박스 밖 결과 제거
- 자동완성: `.pointOfInterest` + `.regionPriority = .required`
- 검색 placeholder: "은행동 카페, 대흥동 맛집, 성심당..."

**대전 외 검색 시 정책**:
- 결과 0건 → "대전 밖의 장소는 표시되지 않아요" 안내
- 지도 이동으로 대전 밖으로 나갈 때 → 소프트 제한 (경고 토스트 + 자동 복귀 유도)

**추천/코스 생성**:
- 사용자 코스 생성 시 가게 선택 → 대전 범위 안 가게만 검색 가능
- "대전 밖 가게를 선택하셨어요" → 불가 처리

#### C. 타슈 반영

**MVP**: 도보 경로 기반 추정
- MKDirections로 도보 거리 → 타슈 속도(12km/h)로 환산
- 대여/반납 오버헤드 2분 추가
- UI: 도보 시간 옆에 타슈 시간 병렬 표시

**확장**: 타슈 API 연동
- 대전시 타슈 공공데이터 API → 실시간 자전거 현황
- 가장 가까운 대여소 표시, 잔여 대수 표시
- 코스 경로에 타슈 대여소 자동 경유지 추가

#### D. 사용자 코스 공유

**코스 생성 플로우**:
1. "나만의 코스 만들기" 진입
2. 제목/설명 입력
3. 가게 검색하여 정류장 추가 (2~7곳)
4. 각 정류장 체류시간/메모 설정
5. 태그 선택 (대전 키워드 프리셋 + 직접 입력)
6. 공개 범위 선택 (나만 보기/전체 공개/링크 공유)
7. 저장 → 자동으로 도보/타슈 ETA 계산

**탐색/정렬**:
- 인기순 (좋아요 수), 최신순, 완주순
- 연령대별 필터 (20대 인기 코스)
- 키워드 태그 필터 (빵축제, 야경, 감성술집...)
- 테마 필터 (데이트, 혼자걷기, 맛집투어...)

### 8.3 MVP vs 확장 기능 구분

| 기능 | MVP (4주) | 확장 (8주+) |
|------|-----------|-------------|
| 대전 지역 제한 | 바운딩 박스 + 주소 필터 | VWorld 행정구역 API |
| 이동수단 | 도보/타슈 (추정 ETA) | 타슈 API 실시간 연동 |
| 방문 인증 | GPS 지오펜스 50m + 3분 | 사진 인증 옵션 추가 |
| 스탬프 | 로컬 저장 (UserDefaults) | Supabase 동기화 |
| 뱃지 | 코스완주/지역/테마 8종 | 시즌 뱃지, 동적 추가 |
| 사용자 코스 | 생성/저장/로컬 공개 | Supabase 연동, 좋아요, 랭킹 |
| 시즌 챌린지 | 정적 1개 (빵축제) | 동적 관리, 기간 자동화 |
| 랭킹 | 없음 | 월간 랭킹 보드 |
| 타슈 대여소 | 정적 좌표 데이터 | 실시간 잔여 대수 |

### 8.4 운영 정책

**데이터 정책**:
- 가게 데이터: 에디터가 수동 큐레이션 (품질 보장)
- 사용자 코스: 공개 코스는 신고 기능으로 관리
- 태그: 프리셋 기본 제공 + 사용자 추가 (운영 검수)
- 이미지: 카카오 이미지 검색 API (현재) → 직접 촬영 (확장)

**위치 정책**:
- GPS 권한: "앱 사용 중만" 기본 요청
- 코스 진행 중: "항상 허용" 요청 (백그라운드 지오펜스용)
- 위치 데이터: 인증용으로만 사용, 경로 추적 안함

**사용자 코스 정책**:
- 최소 정류장 2곳, 최대 7곳
- 대전 범위 안 가게만 추가 가능
- 부적절 코스 신고 → 관리자 검토 후 비공개 전환
- 좋아요 조작 방지: 1인 1좋아요, 취소 가능

### 8.5 KPI 제안

| KPI | 목표 | 측정 방법 |
|-----|------|-----------|
| DAU | 500명 (출시 3개월) | Firebase Analytics |
| 코스 완주율 | 시작 대비 40% | CompletionProof 완료율 |
| 평균 방문 가게 수 | 주 2곳 | StampRecord 주간 집계 |
| 사용자 코스 생성 | 월 50개 | user_courses 월간 생성수 |
| 코스 공유 클릭 | 완주 대비 20% | ShareLink 클릭 이벤트 |
| 재방문율 (D7) | 30% | 앱 실행 리텐션 |
| 시즌 챌린지 참여율 | 활성 사용자 대비 15% | 시즌 코스 시작 수 |

### 8.6 우선순위 로드맵

```
Week 1-2: 기반 구조
├── DaejeonRegion 필터링 적용
├── RouteTransportMode 도보/타슈 교체
├── TashuETACalculator 구현
├── 데이터 모델 확장 (Course, CourseStop ETA 필드)
└── CourseDetailView 이동수단 UI 교체

Week 3-4: 보상 시스템
├── LocationVerificationService (GPS 인증)
├── CompletionProof / StampRecord 저장
├── RewardEngine 뱃지 판정
├── RewardView (뱃지 그리드 + 스탬프 맵)
└── 코스 상세에 "코스 시작" 버튼 + 진행 상태

Week 5-6: 사용자 코스
├── CreateCourseView (코스 생성 화면)
├── 태그 선택 UI
├── 도보/타슈 ETA 자동 계산
├── SharedCoursesView (커뮤니티 탐색)
└── 로컬 저장 (UserDefaults)

Week 7-8: 시즌 & 공유
├── 시즌 챌린지 (정적 1개: 빵축제)
├── 좋아요 기능
├── 정렬/필터 (인기순, 태그별, 연령대별)
├── 코스 완주 축하 화면
└── 공유 링크 생성

Week 9+: 확장
├── Supabase 연동
├── 타슈 API 실시간 연동
├── 월간 랭킹 보드
├── 동적 시즌 관리
└── 사진 인증 옵션
```

### 8.7 실제 앱 문구 예시

**홈 화면**:
- 헤더: "놀거많은대?" / "대전 원도심 스토리 탐험"
- 시즌 배너: "🍞 빵축제 시즌 — 빵 코스 2개 완주하고 '빵 마스터' 뱃지 받기"
- 섹션: "오늘 은행동 한 바퀴 어때요?" / "타슈 타고 30분이면 충분해요"

**검색**:
- Placeholder: "은행동 카페, 대흥동 맛집, 성심당..."
- 빈 결과: "대전 밖의 장소는 표시되지 않아요 🗺️ 이 앱은 대전 원도심 특화 탐방 앱이에요."

**코스 카드**:
- "🚶 도보 90분 · 🚲 타슈 45분 · 3곳 방문"
- "은행동 감성 한 바퀴 — 성심당에서 빵 사고, 레트로 카페에서 쉬고"

**방문 인증**:
- 진입: "골목다방 근처에 왔어요! 잠시 머물면 자동으로 인증돼요 ⏱️"
- 완료: "🎉 골목다방 방문 인증 완료! (2/3)"
- 전체 완주: "🏆 코스 완주! '은행동 감성 한 바퀴'를 정복했어요. 뱃지를 확인해 보세요."

**뱃지 획득**:
- "✨ '첫 코스 완주' 뱃지를 획득했어요! 대전 탐험의 시작이에요."
- "🌙 '야행성 탐험가' 뱃지 — 야간 코스 3개를 완주한 진정한 밤의 탐험가"

**사용자 코스 만들기**:
- CTA: "나만의 대전 코스 만들기"
- 태그: "어떤 키워드가 어울리나요? #빵축제 #야경 #감성술집 #은행동..."
- 공개: "이 코스를 다른 탐험가들과 나눌까요?"
- 완료: "코스가 등록됐어요! 다른 탐험가들이 당신의 코스를 따라갈 거예요 🗺️"

**마이페이지**:
- 요약: "총 8곳 방문 · 3코스 완주 · 뱃지 4개"
- 스탬프맵: "내가 찍은 대전 지도 — 아직 안 가본 곳이 이렇게 많아요!"

---

## Part 9. UX/UI 설계

### 9.1 핵심 UX 방향

1. **"탐험 진행 중" 느낌**: 코스를 시작하면 게임처럼 진행률이 보이고, 하나씩 채워가는 재미
2. **"대전만 아는" 느낌**: 모든 문구, 이미지, 추천이 대전 맥락. 범용 지도 앱과 차별
3. **"타슈는 대전" 느낌**: 도보 옆에 항상 타슈가 있어서 "아, 대전이구나" 인식
4. **"내 코스 자랑" 느낌**: 만들고 공유하고 좋아요 받는 소셜 루프

### 9.2 주요 사용자 시나리오

**시나리오 A: 첫 방문자 탐방**
```
홈 진입 → 시즌 배너 "빵축제 코스" 클릭
→ 코스 상세 (도보 90분 / 타슈 45분)
→ "코스 시작" 탭
→ 첫 번째 가게로 도보 이동 (지도에 동선 표시)
→ 가게 50m 진입 → "근처에 왔어요!" 알림
→ 3분 체류 → "🎉 방문 인증!" 토스트
→ 두 번째 가게로 이동... (반복)
→ 마지막 가게 인증 → "🏆 코스 완주!" 풀스크린 축하
→ 뱃지 획득 → 공유 CTA → 인스타그램 스토리 공유
```

**시나리오 B: 코스 만들기**
```
마이페이지 → "나만의 코스 만들기"
→ 제목 "주말 대흥동 술 투어" 입력
→ 가게 검색 "대흥동 맥주" → 대흥양조장 추가
→ 가게 검색 "선화 와인" → 선화와인바 추가
→ 각 정류장 체류시간 설정 (50분, 40분)
→ 태그 선택: #감성술집 #대흥동 #야경
→ 공개 범위: "전체 공개"
→ 저장 → 자동으로 도보 12분/타슈 5분 계산
→ 커뮤니티에 노출 → 좋아요 받기
```

### 9.3 화면별 UI 설계

#### 지도 화면 (MapExploreView 수정)

**변경사항**:
1. 이동수단 Picker: `도보 | 자동차 | 대중교통` → `🚶 도보 | 🚲 타슈`
2. 검색 placeholder: `"은행동 카페, 성심당, 대전역 근처..."` (이미 대전 특화)
3. 대전 밖 이동 시: "대전 밖이에요. 돌아갈까요?" 토스트 + 복귀 버튼
4. 타슈 대여소 핀 (확장): 지도에 자전거 아이콘으로 표시

#### 코스 리스트 (CoursesView 수정)

**변경사항**:
1. 탭 추가: `추천 코스 | 커뮤니티 코스`
2. 커뮤니티 탭 내: 정렬 필터 (인기순/최신순/완주순)
3. 키워드 태그 가로 스크롤 필터
4. 코스 카드에 도보/타슈 ETA 이중 표시

```
┌─ 추천 코스 ─┬─ 커뮤니티 코스 ─┐
│                              │
│ [인기순 ▾] [#빵축제] [#야경] │
│                              │
│ ┌───────────────────────────┐│
│ │ 🍺 주말 대흥동 술 투어      ││
│ │ @대전소주러버 · 좋아요 23   ││
│ │ 🚶 40분 · 🚲 15분 · 2곳    ││
│ │ #감성술집 #대흥동 #야경     ││
│ └───────────────────────────┘│
```

#### 코스 상세 (CourseDetailView 수정)

**변경사항**:
1. 이동수단 Picker: `도보 | 타슈` 2개만
2. ETA 표시: 각 구간마다 "도보 8분 · 타슈 3분" 병렬
3. "코스 시작" CTA 버튼 추가 (GPS 인증 시작)
4. 진행 중 상태: ProgressRing + 체크리스트

```
[코스 시작 전]
┌─────────────────────────┐
│ 🚶 도보  |  🚲 타슈     │ ← Segmented Picker
├─────────────────────────┤
│ 1. 골목다방 (30분 체류)  │
│    ↓ 도보 8분 · 타슈 3분 │
│ 2. 활자공방 (40분 체류)  │
│    ↓ 도보 5분 · 타슈 2분 │
│ 3. 소풍식탁 (20분 체류)  │
├─────────────────────────┤
│ [🚀 코스 시작하기]       │
└─────────────────────────┘

[코스 진행 중]
┌─────────────────────────┐
│  ◉─────◉─────○          │ ← 진행 바 (2/3)
│ ✅ 골목다방   인증 완료   │
│ ✅ 활자공방   인증 완료   │
│ ⏳ 소풍식탁   이동 중...  │
│                          │
│ [📍 다음 가게로 안내]     │
└─────────────────────────┘
```

#### 코스 완주/보상 화면 (신규: CourseCompletionView)

```
┌─────────────────────────┐
│                          │
│     🏆                   │
│  코스 완주!               │
│                          │
│  "은행동 감성 한 바퀴"    │
│  3곳 방문 · 1시간 32분    │
│                          │
│  ┌─── 획득한 뱃지 ──────┐│
│  │ ⭐ 첫 코스 완주!      ││
│  │ 🏛️ 은행동 전문가      ││
│  └──────────────────────┘│
│                          │
│  [📱 친구에게 자랑하기]   │
│  [🏠 홈으로]              │
└─────────────────────────┘
```

#### 사용자 코스 등록 화면 (신규: CreateCourseView)

```
┌─────────────────────────┐
│ 나만의 코스 만들기        │
│                          │
│ 코스 이름                 │
│ ┌──────────────────────┐│
│ │ 주말 대흥동 술 투어    ││
│ └──────────────────────┘│
│                          │
│ 한 줄 소개               │
│ ┌──────────────────────┐│
│ │ 대흥동 맥주집부터...   ││
│ └──────────────────────┘│
│                          │
│ 테마 선택                │
│ [💑데이트] [🌙야간] [🍽맛집]│
│                          │
│ 정류장 (2/7)             │
│ ① 대흥양조장 · 50분 체류 │
│ ② 선화와인바 · 40분 체류 │
│ [+ 가게 추가]            │
│                          │
│ 태그                     │
│ [#감성술집] [#대흥동] [+] │
│                          │
│ 공개 범위                │
│ ○ 나만 보기 ● 전체 공개  │
│                          │
│ [코스 저장하기]           │
└─────────────────────────┘
```

#### 마이페이지 보상 섹션 (MyPageView 수정)

```
┌─────────────────────────┐
│ 내 탐험 기록              │
│                          │
│ 8곳 방문 · 3코스 · 4뱃지 │
│                          │
│ ─── 뱃지 ─────────────── │
│ [⭐][🏛️][🌙][🍽]         │
│ [🔒][🔒][🔒]...          │
│                          │
│ ─── 스탬프 맵 ────────── │
│ [대전 지도 + 방문한 곳 핀] │
│ "아직 선화동에 안 가봤네요"│
│                          │
│ ─── 나의 코스 ────────── │
│ [주말 대흥동 술 투어]     │
│ [나만의 은행동 산책]      │
│ [+ 새 코스 만들기]        │
└─────────────────────────┘
```

### 9.4 상태 설계

| 상태 | 화면 | 문구 |
|------|------|------|
| 빈 상태 (뱃지) | 뱃지 그리드 | "아직 뱃지가 없어요. 첫 코스를 완주해 보세요!" |
| 빈 상태 (커뮤니티) | 공유 코스 | "아직 공유된 코스가 없어요. 첫 번째 코스를 만들어 보세요!" |
| 로딩 (인증) | 코스 진행 | "위치를 확인하고 있어요..." |
| 완주 성공 | 완주 화면 | "🏆 코스 완주! 대전 탐험가의 길을 걷고 있어요" |
| 대전 밖 검색 | 검색 결과 | "대전 밖의 장소는 표시되지 않아요" |
| GPS 권한 거부 | 인증 시작 | "위치 권한이 필요해요. 설정에서 허용해 주세요." |
| 이미 완주 | 코스 상세 | "✅ 이미 완주한 코스예요! 다시 도전할까요?" |

---

## Part 10. 확장 포인트

### 10.1 타슈 API 실시간 연동

```
대전시 공공데이터 포털 → 타슈 대여소 API
- 엔드포인트: https://bikeapp.tashu.or.kr/app/station/list
- 데이터: 대여소 ID, 이름, 좌표, 잔여 대수, 총 거치대
- 갱신 주기: 5분
- fallback: 정적 대여소 좌표 JSON (앱 번들 포함)
```

### 10.2 Supabase 전환 체크리스트

1. `MockDataService` → `SupabaseDataService` 교체 (ServiceContainer만 변경)
2. UserDefaults → Supabase auth + RLS
3. 사용자 코스/좋아요/뱃지 → Supabase 테이블 동기화
4. Edge Functions: 좋아요 카운트 갱신, 뱃지 판정 서버사이드

### 10.3 사진 인증 (확장)

- GPS 인증 + 선택적 사진 첨부
- 사진은 Supabase Storage에 업로드
- AI 검증 (장소 매칭)은 최종 확장

### 10.4 커뮤니티 확장

- 코스 댓글
- 사용자 팔로우
- "이 코스를 따라갔어요" 기록
- 코스 리믹스 (다른 사용자 코스 기반 수정)

---

## Part 11. 예외 처리와 리스크

### 11.1 기술 리스크

| 리스크 | 영향 | 대응 |
|--------|------|------|
| MapKit 검색이 대전 결과 부족 | 검색 결과 빈약 | 앱 내 등록 가게 우선 검색 + MapKit 보조 |
| GPS 정확도 낮음 (실내) | 인증 실패 | 반경 50m + 수동 인증 폴백 |
| 타슈 API 불안정 | 실시간 데이터 누락 | 정적 대여소 데이터 폴백 |
| 카카오 이미지 API 무관련 이미지 | UX 저하 | 에디터 직접 촬영 이미지 우선 |
| iOS 백그라운드 위치 제한 | 지오펜스 미작동 | 앱 사용 중 인증 + 포그라운드 안내 |

### 11.2 운영 리스크

| 리스크 | 대응 |
|--------|------|
| 허위 GPS 인증 (위치 조작앱) | MVP: 신뢰 기반 / 확장: 이상 패턴 감지 |
| 부적절 사용자 코스 | 신고 기능 + 관리자 검토 |
| 가게 폐업/이전 | 정기 데이터 업데이트 (월 1회) |
| 시즌 챌린지 기간 착오 | 서버사이드 기간 관리 (확장) |

### 11.3 MapKit 제약사항

| 제약 | 설명 | 대응 |
|------|------|------|
| 자전거 경로 미지원 | MKDirections에 자전거 경로 없음 | 도보 경로 + 속도 보정 |
| region 제한은 힌트 | MKLocalSearch.region은 강제 아님 | 후처리 필터 필수 |
| 일일 API 호출 제한 | Apple 미공개이나 과다 호출 시 제한 | 캐시 + 요청 최소화 |
| 실시간 교통정보 | 도보에는 교통정보 무의미 | 타슈 ETA에 교통 반영 불필요 |

---

## 부록: 현재 코드 변경 요약

### 즉시 변경 (Breaking Changes)

1. **`RouteTransportMode`** (`MapExploreView.swift:1538-1560`)
   - `automobile`, `transit` 제거 → `tashu` 추가
   - `transportType`: 항상 `.walking` 반환

2. **`MapSearchController.init`** (`MapExploreView.swift:1640-1644`)
   - `completer.region = DaejeonRegion.searchBounds`
   - `completer.resultTypes = [.pointOfInterest]`

3. **`search(for:region:)`** (`MapExploreView.swift:1653-1667`)
   - `request.region = DaejeonRegion.searchBounds`
   - 결과 후처리: `DaejeonRegion.isInDaejeon()` 필터

4. **`searchNearby(category:region:)`** (`MapExploreView.swift:1669-1681`)
   - 동일하게 대전 범위 제한

5. **`CourseDetailView`** (`CourseDetailView.swift:91-96`)
   - `Picker` 선택지: `RouteTransportMode.allCases` (도보/타슈만)

6. **`Course` 모델** (`Course.swift`)
   - `tags: [String]` 필드 추가
   - `tashuDurationMinutes: Int?` 필드 추가
   - `authorId: String?`, `isPublic: Bool` 필드 추가

### 신규 파일 (6개)

| 파일 | 줄 수 (예상) | 설명 |
|------|-------------|------|
| `DaejeonRegion.swift` | ~60 | 대전 좌표/주소 검증 |
| `TashuETACalculator.swift` | ~50 | 타슈 ETA 계산 |
| `LocationVerificationService.swift` | ~150 | GPS 지오펜스 인증 |
| `RewardEngine.swift` | ~80 | 뱃지 판정 |
| `Views/Reward/RewardView.swift` | ~200 | 뱃지/스탬프 화면 |
| `Views/Courses/CreateCourseView.swift` | ~250 | 코스 생성 화면 |
