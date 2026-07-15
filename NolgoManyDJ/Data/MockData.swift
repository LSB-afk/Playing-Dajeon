import Foundation

// MARK: - Mock Data
// 대전 원도심과 주요 방문지를 기준으로 한 샘플 가게/장소 + 코스 데이터

// MARK: - Curated Imagery
// 대전 은행동/대흥동/선화동 분위기에 맞는 따뜻한 톤의 실제 가게/골목 사진
// (Unsplash CDN의 안정적인 ID를 사용)
enum LocalImagery {
    static let cafeInterior   = "https://images.unsplash.com/photo-1554118811-1e0d58224f24?w=900&q=80"
    static let coffeeTable    = "https://images.unsplash.com/photo-1495474472287-4d71bcdd2085?w=900&q=80"
    static let woodCafe       = "https://images.unsplash.com/photo-1517248135467-4c7edcad34c4?w=900&q=80"
    static let bakery         = "https://images.unsplash.com/photo-1509440159596-0249088772ff?w=900&q=80"
    static let pastries       = "https://images.unsplash.com/photo-1559339352-11d035aa65de?w=900&q=80"
    static let koreanFood     = "https://images.unsplash.com/photo-1498654896293-37aacf113fd9?w=900&q=80"
    static let koreanSoup     = "https://images.unsplash.com/photo-1569718212165-3a8278d5f624?w=900&q=80"
    static let homemadeMeal   = "https://images.unsplash.com/photo-1546069901-ba9599a7e63c?w=900&q=80"
    static let bookstore      = "https://images.unsplash.com/photo-1521587760476-6c12a4b040da?w=900&q=80"
    static let openBook       = "https://images.unsplash.com/photo-1457369804613-52c61a468e7d?w=900&q=80"
    static let typewriter     = "https://images.unsplash.com/photo-1455390582262-044cdead277a?w=900&q=80"
    static let ceramics       = "https://images.unsplash.com/photo-1493106641515-6b5631de4bb9?w=900&q=80"
    static let pottery        = "https://images.unsplash.com/photo-1565193566173-7a0ee3dbe261?w=900&q=80"
    static let craftBeer      = "https://images.unsplash.com/photo-1514933651103-005eec06c04b?w=900&q=80"
    static let wineBar        = "https://images.unsplash.com/photo-1510812431401-41d2bd2722f3?w=900&q=80"
    static let gallery        = "https://images.unsplash.com/photo-1545063328-c8e3faffa16f?w=900&q=80"
    static let alley          = "https://images.unsplash.com/photo-1526318896980-cf78c088247c?w=900&q=80"
    static let nightStreet    = "https://images.unsplash.com/photo-1551782450-a2132b4ba21d?w=900&q=80"
    static let warmStreet     = "https://images.unsplash.com/photo-1525755662778-989d0524087e?w=900&q=80"
    static let gardenCafe     = "https://images.unsplash.com/photo-1525610553991-2bede1a236e2?w=900&q=80"
    static let cityPark        = "https://images.unsplash.com/photo-1441974231531-c6227db76b6e?w=900&q=80"
    static let sciencePark     = "https://images.unsplash.com/photo-1535223289827-42f1e9919769?w=900&q=80"
    static let themePark       = "https://images.unsplash.com/photo-1513889961551-628c1e5e2ee9?w=900&q=80"
    static let lakeRoad        = "https://images.unsplash.com/photo-1500530855697-b586d89ba3ee?w=900&q=80"
    static let market          = "https://images.unsplash.com/photo-1533900298318-6b8da08a523e?w=900&q=80"
    static let festivalStreet  = "https://images.unsplash.com/photo-1506157786151-b8491531f063?w=900&q=80"
    static let lampJinheeFabric = "asset://lamp-jinhee-fabric"
    static let lampJinheePackages = "asset://lamp-jinhee-packages"
    static let lampJinheeEntrance = "asset://lamp-jinhee-entrance"
    static let lampJinheeHorse = "asset://lamp-jinhee-horse"
    static let lampJinheeShelf = "asset://lamp-jinhee-shelf"
    static let lampJinheeShop = "asset://lamp-jinhee-shop"
    static let lampJinheeCharacters = "asset://lamp-jinhee-characters"
    static let lampJinheeCalligraphy = "asset://lamp-jinhee-calligraphy"
}

struct MockData {

    // MARK: - Stores
    static let stores: [Store] = [
        // === 은행동 ===
        Store(
            id: "store-001", name: "골목다방", slug: "golmok-dabang",
            category: .cafe, district: .eunhaeng,
            shortDescription: "성심당 골목 뒤, 1970년대 다방을 재해석한 레트로 카페",
            storyTitle: "할머니의 찻잔에서 시작된 공간",
            founderStory: "서울에서 10년 넘게 광고 일을 하던 사장님이 어느 날 대전 할머니 집을 정리하다 오래된 찻잔 세트를 발견했습니다. 그 찻잔에 커피를 따라 마시던 순간, '이 감성을 공간으로 만들고 싶다'는 생각이 들었대요. 퇴사 후 할머니가 살던 은행동 골목에 자리 잡아, 70년대 다방의 따뜻함을 현대적으로 재해석한 공간을 만들었습니다.",
            signaturePoint: "할머니가 쓰던 실제 찻잔으로 커피를 내어주는 '추억 한 잔' 메뉴가 시그니처. 벽면에는 대전 원도심의 옛 사진이 전시되어 있어요.",
            address: "대전 중구 은행동 145-3", phone: "042-123-4567",
            openingHours: "화~일 11:00 - 21:00 (월요일 휴무)",
            websiteURL: nil, instagramURL: "https://instagram.com/golmok_dabang",
            latitude: 36.3275, longitude: 127.4272,
            thumbnailURL: "\(LocalImagery.woodCafe)",
            coverImageURL: "\(LocalImagery.woodCafe)",
            menuItems: [
                MenuItem(id: "m1", name: "추억 한 잔 (핸드드립)", price: "6,500원", isSignature: true),
                MenuItem(id: "m2", name: "다방 밀크티", price: "5,500원", isSignature: false),
                MenuItem(id: "m3", name: "쌍화차 라떼", price: "6,000원", isSignature: true),
                MenuItem(id: "m4", name: "레트로 카스테라", price: "4,500원", isSignature: false),
            ],
            visitTip: "2층 창가 자리에서 은행동 골목을 내려다보며 마시는 커피가 최고예요. 오후 3시 이후가 한적합니다.",
            createdAt: Date(), updatedAt: Date()
        ),
        Store(
            id: "store-002", name: "소풍식탁", slug: "sopung-table",
            category: .restaurant, district: .eunhaeng,
            shortDescription: "엄마표 한식을 정갈하게, 은행동의 작은 밥집",
            storyTitle: "30년 경력 엄마의 밥상이 식당이 되기까지",
            founderStory: "결혼 후 30년간 가족 밥상만 차려온 사장님이, 아이들이 독립한 후 '이 손맛을 동네 사람들과 나누고 싶다'며 시작한 식당입니다. 메뉴는 단 4가지. 매일 아침 시장에서 직접 장을 보고, 그날그날 반찬이 달라져요.",
            signaturePoint: "매일 다른 반찬 구성과 직접 담근 된장찌개. 혼밥 손님에게도 따뜻하게 대해주시는 사장님 인심이 이 집의 진짜 시그니처.",
            address: "대전 중구 은행동 152-8", phone: "042-234-5678",
            openingHours: "월~토 11:00 - 15:00, 17:00 - 20:00 (일요일 휴무)",
            websiteURL: nil, instagramURL: nil,
            latitude: 36.3280, longitude: 127.4265,
            thumbnailURL: "\(LocalImagery.homemadeMeal)",
            coverImageURL: "\(LocalImagery.homemadeMeal)",
            menuItems: [
                MenuItem(id: "m5", name: "오늘의 정식", price: "9,000원", isSignature: true),
                MenuItem(id: "m6", name: "된장찌개 백반", price: "8,000원", isSignature: true),
                MenuItem(id: "m7", name: "제육볶음 정식", price: "9,500원", isSignature: false),
                MenuItem(id: "m8", name: "계절 비빔밥", price: "8,500원", isSignature: false),
            ],
            visitTip: "점심시간에는 줄을 설 수 있어요. 11시 30분 전에 방문하면 여유롭게 앉을 수 있습니다.",
            createdAt: Date(), updatedAt: Date()
        ),
        Store(
            id: "store-003", name: "활자공방", slug: "hwalja-workshop",
            category: .workshop, district: .eunhaeng,
            shortDescription: "납활자로 나만의 문장을 찍어보는 활판인쇄 공방",
            storyTitle: "사라지는 활판인쇄를 지키는 사람",
            founderStory: "인쇄소를 운영하던 아버지가 디지털 시대에 폐업한 후, 창고에 남겨진 수만 개의 납활자를 보며 사장님은 결심했습니다. '이걸 버릴 수 없다.' 아버지의 활자를 하나하나 정리해 공방을 열고, 방문객이 직접 활자를 골라 자기만의 문장을 인쇄하는 체험을 만들었습니다.",
            signaturePoint: "직접 납활자를 골라 엽서나 포스터를 만드는 체험 프로그램. 대전에서만 할 수 있는 유일한 활판인쇄 경험입니다.",
            address: "대전 중구 은행동 138-12", phone: "042-345-6789",
            openingHours: "수~일 13:00 - 19:00 (월·화 휴무)",
            websiteURL: nil, instagramURL: "https://instagram.com/hwalja_workshop",
            latitude: 36.3270, longitude: 127.4280,
            thumbnailURL: "\(LocalImagery.openBook)",
            coverImageURL: "\(LocalImagery.openBook)",
            menuItems: [
                MenuItem(id: "m9", name: "활판인쇄 엽서 체험", price: "15,000원", isSignature: true),
                MenuItem(id: "m10", name: "나만의 포스터 만들기", price: "25,000원", isSignature: true),
                MenuItem(id: "m11", name: "활자 키링 체험", price: "12,000원", isSignature: false),
            ],
            visitTip: "체험은 예약제로 운영돼요. 인스타그램 DM으로 미리 예약하세요.",
            createdAt: Date(), updatedAt: Date()
        ),
        // === 대흥동 ===
        Store(
            id: "store-004", name: "느린우체통", slug: "slow-postbox",
            category: .cafe, district: .daeheung,
            shortDescription: "1년 뒤의 나에게 편지를 보내는 타임캡슐 카페",
            storyTitle: "느리게 도착하는 마음을 파는 곳",
            founderStory: "여행 중 우연히 들른 일본의 '미래 우체국'에서 영감을 받아 시작한 카페입니다. 사장님은 '빠른 것만 좋은 세상에서, 천천히 도착하는 마음이 있으면 좋겠다'고 생각했대요. 커피를 마시며 1년 뒤 자신에게 편지를 쓸 수 있고, 정확히 1년 후 우편으로 배달됩니다.",
            signaturePoint: "1년 후 배달되는 '느린 편지' 서비스. 매장 곳곳에 놓인 빈티지 우편함과 편지지 컬렉션도 볼거리입니다.",
            address: "대전 중구 대흥동 480-5", phone: "042-456-7890",
            openingHours: "매일 10:00 - 22:00 (연중무휴)",
            websiteURL: nil, instagramURL: "https://instagram.com/slow_postbox",
            latitude: 36.3240, longitude: 127.4220,
            thumbnailURL: "\(LocalImagery.typewriter)",
            coverImageURL: "\(LocalImagery.typewriter)",
            menuItems: [
                MenuItem(id: "m12", name: "느린 편지 세트 (음료 + 편지지)", price: "8,500원", isSignature: true),
                MenuItem(id: "m13", name: "회상 라떼", price: "5,500원", isSignature: false),
                MenuItem(id: "m14", name: "시간여행 에이드", price: "6,000원", isSignature: true),
            ],
            visitTip: "편지 쓸 시간 여유를 가지고 방문하세요. 30분 정도면 충분합니다.",
            createdAt: Date(), updatedAt: Date()
        ),
        Store(
            id: "store-005", name: "대흥양조장", slug: "daeheung-brewery",
            category: .bar, district: .daeheung,
            shortDescription: "전통 양조 방식으로 빚은 대전 로컬 수제맥주 바",
            storyTitle: "대전 물로 빚는 동네 맥주",
            founderStory: "대기업 맥주 회사를 퇴사한 사장님이 '우리 동네 물로 우리 동네 맥주를 만들고 싶다'며 시작한 수제맥주 바입니다. 대전의 깨끗한 지하수를 사용하고, 한국 전통 누룩을 블렌딩한 독특한 레시피가 특징이에요.",
            signaturePoint: "대전 지하수 + 전통 누룩으로 만든 '대흥 에일'. 양조장을 직접 볼 수 있는 바 좌석이 인기.",
            address: "대전 중구 대흥동 493-7", phone: "042-567-8901",
            openingHours: "화~일 17:00 - 01:00 (월요일 휴무)",
            websiteURL: nil, instagramURL: "https://instagram.com/daeheung_brewery",
            latitude: 36.3235, longitude: 127.4215,
            thumbnailURL: "\(LocalImagery.craftBeer)",
            coverImageURL: "\(LocalImagery.craftBeer)",
            menuItems: [
                MenuItem(id: "m16", name: "대흥 에일 (생맥주)", price: "7,000원", isSignature: true),
                MenuItem(id: "m17", name: "원도심 IPA", price: "8,000원", isSignature: true),
                MenuItem(id: "m18", name: "누룩 바이젠", price: "7,500원", isSignature: false),
            ],
            visitTip: "금요일 저녁에는 라이브 공연이 있어요. 야외 테라스 자리 추천!",
            createdAt: Date(), updatedAt: Date()
        ),
        Store(
            id: "store-006", name: "사물의 온도", slug: "temperature-of-things",
            category: .shop, district: .daeheung,
            shortDescription: "대전 작가들의 소품과 생활 도자기를 모은 편집숍",
            storyTitle: "만든 사람의 온도가 느껴지는 물건들",
            founderStory: "도예를 전공한 사장님이 졸업 후 작품 활동을 하면서, 대전 지역 작가들의 좋은 작품이 알려지지 않는 현실이 안타까웠습니다. '좋은 물건은 쓰일 때 완성된다'는 철학으로, 대전·충남 지역 작가 30여 명의 도자기, 목공예, 섬유 소품을 큐레이션하는 편집숍을 열었어요.",
            signaturePoint: "모든 상품에 만든 작가의 이름과 짧은 이야기가 적힌 카드가 함께 제공됩니다.",
            address: "대전 중구 대흥동 467-2", phone: "042-678-9012",
            openingHours: "수~일 12:00 - 20:00 (월·화 휴무)",
            websiteURL: nil, instagramURL: "https://instagram.com/temp_of_things",
            latitude: 36.3245, longitude: 127.4225,
            thumbnailURL: "\(LocalImagery.ceramics)",
            coverImageURL: "\(LocalImagery.ceramics)",
            menuItems: [
                MenuItem(id: "m20", name: "핸드메이드 도자 머그컵", price: "18,000~35,000원", isSignature: true),
                MenuItem(id: "m21", name: "대전 작가 캔들", price: "15,000원", isSignature: false),
            ],
            visitTip: "구경만 해도 괜찮아요. 사장님이 각 작가의 이야기를 들려주세요.",
            createdAt: Date(), updatedAt: Date()
        ),
        Store(
            id: "store-007", name: "빛 갤러리", slug: "bit-gallery",
            category: .culture, district: .daeheung,
            shortDescription: "폐건물을 개조한 복합문화공간 겸 갤러리 카페",
            storyTitle: "버려진 건물에 다시 빛을 켜다",
            founderStory: "건축을 전공한 사장님 부부가 대흥동에서 10년 넘게 방치된 3층 건물을 발견하고, '이 공간에 다시 사람이 모이게 하고 싶다'며 리노베이션을 시작했습니다. 1층은 갤러리, 2층은 카페, 3층은 소규모 공연장으로 운영하며, 지역 예술가들에게 전시 공간을 무료로 대여합니다.",
            signaturePoint: "매달 바뀌는 지역 작가 전시와 옥상 테라스. 건물 자체가 하나의 작품처럼 설계되어 있어요.",
            address: "대전 중구 대흥동 501-3", phone: "042-789-0123",
            openingHours: "화~일 11:00 - 22:00 (월요일 휴무)",
            websiteURL: "https://bit-gallery.kr",
            instagramURL: "https://instagram.com/bit_gallery_dj",
            latitude: 36.3250, longitude: 127.4230,
            thumbnailURL: "\(LocalImagery.gallery)",
            coverImageURL: "\(LocalImagery.gallery)",
            menuItems: [
                MenuItem(id: "m23", name: "전시 관람 (무료)", price: "무료", isSignature: true),
                MenuItem(id: "m24", name: "갤러리 아메리카노", price: "4,500원", isSignature: false),
                MenuItem(id: "m25", name: "옥상 선셋 세트", price: "12,000원", isSignature: true),
            ],
            visitTip: "해질 무렵 옥상 테라스에서 보는 대흥동 풍경이 압권이에요.",
            createdAt: Date(), updatedAt: Date()
        ),
        Store(
            id: "store-013", name: "램프의진희", slug: "lamp-jinhee",
            category: .workshop, district: .daeheung,
            shortDescription: "대흥동 문화거리에서 14년째 이어온 그림과 감성 소품 공간",
            storyTitle: "일상 속 작은 빛이 되어 마음의 불을 켜고 그리다",
            founderStory: "램프의진희는 2012년 8월 16일 대흥동 문화거리에 공예 소품샵으로 문을 열었습니다. 작은 변화를 거치며 2026년 현재까지 14년째 같은 동네에서 그림 전시와 판매, 그림 공방, 개성 있는 소품 판매를 이어오고 있어요. 이름의 '램프'는 소망을 이루어주는 마법의 램프를 뜻하고, '진희'는 작가의 이름이자 참됨과 진정성을 담은 마음을 의미합니다. 이곳은 각자의 내면에 따뜻한 빛을 밝히는 공간을 지향하며, 직접 그린 그림과 손으로 고른 소품을 통해 유쾌하고 따뜻한 예술 경험을 전합니다.",
            signaturePoint: "작가가 직접 그린 그림과 캐릭터 작품, 따뜻한 예술 감성이 담긴 소품을 함께 만날 수 있습니다. 방문객은 전시를 보는 데서 그치지 않고, 그림 공방과 소품 구경을 통해 나만의 감성과 향기를 발견할 수 있어요.",
            address: "대전 중구 대흥동 문화거리", phone: "방문 전 문의",
            openingHours: "전시·공방 일정에 따라 운영 (방문 전 확인 권장)",
            websiteURL: nil, instagramURL: nil,
            latitude: 36.3246, longitude: 127.4222,
            thumbnailURL: LocalImagery.lampJinheeShop,
            coverImageURL: LocalImagery.lampJinheeShop,
            menuItems: [
                MenuItem(id: "m42", name: "그림 전시 관람", price: "무료", isSignature: true),
                MenuItem(id: "m43", name: "작가 그림 소품", price: "상품별 상이", isSignature: true),
                MenuItem(id: "m44", name: "그림 공방 클래스", price: "문의", isSignature: false),
                MenuItem(id: "m45", name: "캐릭터·공예 소품", price: "상품별 상이", isSignature: false),
            ],
            visitTip: "작가의 전시 일정과 공방 운영 시간이 달라질 수 있어요. 작품을 천천히 보고 싶다면 평일 낮 시간 방문을 추천합니다.",
            tags: ["대흥동", "공방", "그림", "소품", "체험", "전시", "데이트", "램프의진희"],
            createdAt: Date(), updatedAt: Date()
        ),
        Store(
            id: "store-008", name: "삼대국밥", slug: "samdae-gukbap",
            category: .restaurant, district: .daeheung,
            shortDescription: "할아버지부터 3대째 이어온 소머리국밥",
            storyTitle: "3대가 지켜온 한 그릇의 정성",
            founderStory: "1968년 할아버지가 대흥동 시장 앞에서 소머리국밥 한 가마솥으로 시작한 식당입니다. 아버지를 거쳐 현재 3대째 운영 중인 사장님은 '할아버지의 레시피에서 단 하나도 바꾸지 않았다'고 말합니다. 새벽 4시부터 끓이는 사골 육수의 깊은 맛은 50년이 넘은 세월의 맛이에요.",
            signaturePoint: "새벽 4시부터 12시간 끓인 사골 육수. 할아버지 때부터 쓰던 가마솥이 아직도 주방에 있습니다.",
            address: "대전 중구 대흥동 458-1", phone: "042-890-1234",
            openingHours: "매일 06:00 - 15:00 (국물 소진 시 조기 마감)",
            websiteURL: nil, instagramURL: nil,
            latitude: 36.3238, longitude: 127.4210,
            thumbnailURL: "\(LocalImagery.koreanSoup)",
            coverImageURL: "\(LocalImagery.koreanSoup)",
            menuItems: [
                MenuItem(id: "m26", name: "소머리국밥", price: "9,000원", isSignature: true),
                MenuItem(id: "m27", name: "수육 (소)", price: "25,000원", isSignature: false),
            ],
            visitTip: "아침 일찍 방문하면 갓 끓인 진한 첫 국물을 맛볼 수 있어요.",
            createdAt: Date(), updatedAt: Date()
        ),
        // === 선화동 ===
        Store(
            id: "store-009", name: "먹물서점", slug: "mukmul-bookstore",
            category: .culture, district: .sunhwa,
            shortDescription: "15년째 선화동을 지키는 독립서점 겸 북카페",
            storyTitle: "동네에서 가장 오래된 비밀 아지트",
            founderStory: "대학 시절 문학을 전공한 사장님이 '대전에도 독립서점이 필요하다'며 2010년에 문을 열었습니다. 대형 서점에서 만나기 어려운 독립출판물, 소규모 출판사 책, 지역 작가의 작품을 큐레이션합니다. 15년간 같은 자리를 지키며, 선화동의 문화 아지트가 되었어요.",
            signaturePoint: "사장님이 직접 고른 '이달의 대전 책' 코너와 매주 토요일 열리는 소규모 독서 모임.",
            address: "대전 중구 선화동 302-7", phone: "042-901-2345",
            openingHours: "화~일 12:00 - 21:00 (월요일 휴무)",
            websiteURL: nil, instagramURL: "https://instagram.com/mukmul_books",
            latitude: 36.3300, longitude: 127.4190,
            thumbnailURL: "\(LocalImagery.bookstore)",
            coverImageURL: "\(LocalImagery.bookstore)",
            menuItems: [
                MenuItem(id: "m29", name: "드립 커피", price: "4,500원", isSignature: false),
                MenuItem(id: "m30", name: "책방 밀크티", price: "5,500원", isSignature: true),
            ],
            visitTip: "2층 다락방 같은 공간에서 책 읽기 좋아요.",
            createdAt: Date(), updatedAt: Date()
        ),
        Store(
            id: "store-010", name: "흙과 불", slug: "heuk-gwa-bul",
            category: .workshop, district: .sunhwa,
            shortDescription: "도예 체험과 소품 구매를 한 번에, 선화동 도자기 공방",
            storyTitle: "흙을 만지면 마음이 편해지더라고요",
            founderStory: "IT 회사에서 번아웃을 겪은 사장님이 치료 목적으로 시작한 도예가 인생을 바꿨습니다. '흙을 만지는 동안만큼은 모든 걱정이 사라진다'는 경험을 나누고 싶어 공방을 열었어요. 초보자도 1시간 안에 나만의 그릇을 만들 수 있는 원데이 클래스가 인기입니다.",
            signaturePoint: "완전 초보도 가능한 1시간 도자기 원데이 클래스. 만든 작품은 2주 후 택배로 받을 수 있어요.",
            address: "대전 중구 선화동 287-4", phone: "042-012-3456",
            openingHours: "수~일 11:00 - 19:00 (월·화 휴무)",
            websiteURL: nil, instagramURL: "https://instagram.com/heuk_bul",
            latitude: 36.3305, longitude: 127.4195,
            thumbnailURL: "\(LocalImagery.pottery)",
            coverImageURL: "\(LocalImagery.pottery)",
            menuItems: [
                MenuItem(id: "m32", name: "원데이 도자기 클래스", price: "30,000원", isSignature: true),
                MenuItem(id: "m33", name: "물레 체험", price: "35,000원", isSignature: true),
            ],
            visitTip: "예약 필수! 체험 후 근처 먹물서점과 함께 방문하면 좋은 코스가 됩니다.",
            createdAt: Date(), updatedAt: Date()
        ),
        Store(
            id: "store-011", name: "선화와인바", slug: "sunhwa-winebar",
            category: .bar, district: .sunhwa,
            shortDescription: "골목 안 숨은 내추럴 와인 바, 조용한 어른들의 아지트",
            storyTitle: "좁은 골목 끝에서 만나는 작은 유럽",
            founderStory: "프랑스에서 소믈리에 과정을 마치고 돌아온 사장님이 '대전에서도 좋은 와인을 편하게 즐겼으면' 하는 마음으로 열었습니다. 12석뿐인 아담한 공간입니다.",
            signaturePoint: "사장님이 직접 고른 내추럴 와인 30여 종과, 와인에 맞춘 소량 안주 페어링.",
            address: "대전 중구 선화동 310-9", phone: "042-567-0123",
            openingHours: "수~일 18:00 - 00:00 (월·화 휴무)",
            websiteURL: nil, instagramURL: "https://instagram.com/sunhwa_wine",
            latitude: 36.3310, longitude: 127.4200,
            thumbnailURL: "\(LocalImagery.wineBar)",
            coverImageURL: "\(LocalImagery.wineBar)",
            menuItems: [
                MenuItem(id: "m35", name: "오늘의 내추럴 와인 (글라스)", price: "12,000원", isSignature: true),
                MenuItem(id: "m36", name: "치즈 플레이트", price: "18,000원", isSignature: false),
                MenuItem(id: "m37", name: "사장님 추천 페어링 세트", price: "35,000원", isSignature: true),
            ],
            visitTip: "12석뿐이라 주말에는 예약 추천. 첫 방문이면 사장님 추천 와인을 드셔보세요.",
            createdAt: Date(), updatedAt: Date()
        ),
        Store(
            id: "store-012", name: "빵굽는 정원", slug: "baking-garden",
            category: .cafe, district: .sunhwa,
            shortDescription: "정원이 있는 베이커리 카페, 직접 키운 허브로 만든 빵",
            storyTitle: "정원에서 식탁까지, 자연이 만드는 빵",
            founderStory: "원래 정원사였던 사장님이 '내가 키운 허브와 꽃으로 음식을 만들면 어떨까'라는 호기심에서 시작했습니다. 선화동 주택을 개조해 1층은 정원, 2층은 베이커리로 운영해요. 로즈마리 포카치아, 라벤더 스콘 등 정원에서 바로 딴 허브가 빵이 됩니다.",
            signaturePoint: "매장 정원에서 직접 재배한 허브로 만드는 시즌별 빵. 정원에서 먹는 브런치가 인기.",
            address: "대전 중구 선화동 295-1", phone: "042-678-0123",
            openingHours: "목~월 10:00 - 18:00 (화·수 휴무)",
            websiteURL: nil, instagramURL: "https://instagram.com/baking_garden_dj",
            latitude: 36.3295, longitude: 127.4185,
            thumbnailURL: "\(LocalImagery.gardenCafe)",
            coverImageURL: "\(LocalImagery.gardenCafe)",
            menuItems: [
                MenuItem(id: "m38", name: "로즈마리 포카치아", price: "5,500원", isSignature: true),
                MenuItem(id: "m39", name: "라벤더 스콘", price: "4,500원", isSignature: true),
                MenuItem(id: "m40", name: "가든 브런치 플레이트", price: "16,000원", isSignature: true),
                MenuItem(id: "m41", name: "허브 레모네이드", price: "6,000원", isSignature: false),
            ],
            visitTip: "날씨 좋은 날 정원 테이블 추천. 오전에 방문하면 갓 구운 빵을 만날 수 있어요.",
            createdAt: Date(), updatedAt: Date()
        ),
        // === 대전 대표 스팟 ===
        Store(
            id: "store-014", name: "성심당 본점", slug: "sungsimdang-main",
            category: .restaurant, district: .eunhaeng,
            shortDescription: "대전을 대표하는 빵집으로 튀김소보로와 부추빵이 유명한 장소",
            storyTitle: "대전을 여행한다면 가장 먼저 떠오르는 빵집",
            founderStory: "성심당 본점은 은행동을 대표하는 대전의 상징적인 맛집입니다. 튀김소보로, 부추빵, 명란바게트처럼 지역을 넘어 사랑받는 메뉴가 많아 대전 여행의 시작점으로 자주 선택됩니다.",
            signaturePoint: "대전역과 원도심 코스에 자연스럽게 연결되는 대표 빵집. 짧은 방문에도 대전다운 먹거리 경험을 만들 수 있습니다.",
            address: "대전 중구 은행동", phone: "방문 전 확인",
            openingHours: "매일 운영 (방문 전 확인 권장)",
            websiteURL: nil, instagramURL: nil,
            latitude: 36.3277, longitude: 127.4272,
            thumbnailURL: LocalImagery.bakery,
            coverImageURL: LocalImagery.bakery,
            menuItems: [
                MenuItem(id: "m46", name: "튀김소보로", price: "매장 확인", isSignature: true),
                MenuItem(id: "m47", name: "부추빵", price: "매장 확인", isSignature: true),
            ],
            visitTip: "주말에는 대기 줄이 길 수 있어요. 은행동 산책 코스와 함께 잡으면 기다리는 시간이 덜 부담됩니다.",
            tags: ["대전대표", "빵집", "성심당", "은행동", "맛집", "튀김소보로", "부추빵"],
            createdAt: Date(), updatedAt: Date()
        ),
        Store(
            id: "store-015", name: "한밭수목원", slug: "hanbat-arboretum",
            category: .attraction, district: .dunsan,
            shortDescription: "산책과 피크닉이 좋은 도심 수목원",
            storyTitle: "도심 한가운데서 만나는 대전의 초록 쉼표",
            founderStory: "한밭수목원은 둔산동 도심권에서 가볍게 걷고 쉬기 좋은 대전 대표 수목원입니다. 계절별 식물과 넓은 산책로가 있어 혼자 걷기, 데이트, 가족 나들이 모두에 잘 맞습니다.",
            signaturePoint: "도심 접근성이 좋고 사진 찍기 좋은 산책 동선이 많아 반나절 코스로 부담 없이 방문할 수 있습니다.",
            address: "대전 서구 둔산동", phone: "방문 전 확인",
            openingHours: "시설별 상이",
            websiteURL: nil, instagramURL: nil,
            latitude: 36.3673, longitude: 127.3884,
            thumbnailURL: LocalImagery.cityPark,
            coverImageURL: LocalImagery.cityPark,
            menuItems: [
                MenuItem(id: "m48", name: "수목원 산책", price: "무료", isSignature: true),
                MenuItem(id: "m49", name: "피크닉 코스", price: "개별 준비", isSignature: false),
            ],
            visitTip: "햇빛이 강한 날에는 모자와 물을 챙기면 좋아요. 봄·가을 오후 산책을 추천합니다.",
            tags: ["한밭수목원", "관광지", "둔산동", "산책", "피크닉", "데이트", "가족"],
            createdAt: Date(), updatedAt: Date()
        ),
        Store(
            id: "store-016", name: "엑스포과학공원", slug: "expo-science-park",
            category: .attraction, district: .doryong,
            shortDescription: "대전의 과학도시 이미지를 대표하는 명소",
            storyTitle: "과학도시 대전을 가장 직관적으로 보여주는 공간",
            founderStory: "엑스포과학공원은 대전이 가진 과학도시 이미지를 경험하기 좋은 대표 명소입니다. 주변의 문화시설, 강변 산책, 야간 경관과 함께 묶으면 가족 여행과 데이트 코스로도 활용하기 좋습니다.",
            signaturePoint: "대전의 상징적인 과학·문화 자산을 한 번에 느낄 수 있어 처음 대전을 찾는 사용자에게 추천하기 좋습니다.",
            address: "대전 유성구 도룡동", phone: "방문 전 확인",
            openingHours: "시설별 상이",
            websiteURL: nil, instagramURL: nil,
            latitude: 36.3767, longitude: 127.3848,
            thumbnailURL: LocalImagery.sciencePark,
            coverImageURL: LocalImagery.sciencePark,
            menuItems: [
                MenuItem(id: "m50", name: "과학공원 산책", price: "무료", isSignature: true),
                MenuItem(id: "m51", name: "야간 경관 감상", price: "무료", isSignature: false),
            ],
            visitTip: "저녁에는 주변 야경과 함께 보기 좋아요. 과학관·미술관 일정과 함께 확인해보세요.",
            tags: ["엑스포", "엑스포과학공원", "관광지", "도룡동", "과학", "가족", "데이트", "야간명소"],
            createdAt: Date(), updatedAt: Date()
        ),
        Store(
            id: "store-017", name: "대전오월드", slug: "daejeon-oworld",
            category: .family, district: .sajeong,
            shortDescription: "가족 단위 방문객에게 적합한 테마파크",
            storyTitle: "아이와 함께 하루를 보내기 좋은 대전 테마파크",
            founderStory: "대전오월드는 동물원, 놀이시설, 플라워랜드를 함께 즐길 수 있는 가족형 테마파크입니다. 아이와 함께하는 여행, 주말 가족 나들이, 체험형 코스를 찾는 사용자에게 적합합니다.",
            signaturePoint: "한 공간에서 동물 관람과 놀이시설, 계절 꽃길을 함께 경험할 수 있습니다.",
            address: "대전 중구 사정동", phone: "방문 전 확인",
            openingHours: "시즌별 상이",
            websiteURL: nil, instagramURL: nil,
            latitude: 36.2888, longitude: 127.3978,
            thumbnailURL: LocalImagery.themePark,
            coverImageURL: LocalImagery.themePark,
            menuItems: [
                MenuItem(id: "m52", name: "가족 나들이", price: "시설 확인", isSignature: true),
                MenuItem(id: "m53", name: "동물원·플라워랜드", price: "시설 확인", isSignature: false),
            ],
            visitTip: "아이와 함께라면 이동 동선을 짧게 잡고, 날씨가 좋은 날 일찍 방문하는 편이 좋습니다.",
            tags: ["대전오월드", "오월드", "가족", "테마파크", "사정동", "아이와", "체험"],
            createdAt: Date(), updatedAt: Date()
        ),
        Store(
            id: "store-018", name: "대청호 오백리길", slug: "daecheongho-trail",
            category: .attraction, district: .daecheong,
            shortDescription: "드라이브와 산책에 좋은 자연 명소",
            storyTitle: "물길을 따라 천천히 쉬어가는 대전 자연 코스",
            founderStory: "대청호 오백리길은 대전과 주변 지역의 자연 풍경을 여유롭게 즐길 수 있는 길입니다. 드라이브, 산책, 사진 촬영을 함께 즐기기 좋아 도심과 다른 분위기의 하루를 만들 수 있습니다.",
            signaturePoint: "호수 풍경과 길게 이어지는 산책 동선이 있어 조용한 자연 여행을 찾는 사용자에게 잘 맞습니다.",
            address: "대전 대덕구·동구", phone: "방문 전 확인",
            openingHours: "상시 이용 가능",
            websiteURL: nil, instagramURL: nil,
            latitude: 36.3760, longitude: 127.4750,
            thumbnailURL: LocalImagery.lakeRoad,
            coverImageURL: LocalImagery.lakeRoad,
            menuItems: [
                MenuItem(id: "m54", name: "호수 산책", price: "무료", isSignature: true),
                MenuItem(id: "m55", name: "드라이브 코스", price: "개별 이동", isSignature: false),
            ],
            visitTip: "차량 이동이 편한 코스입니다. 해 질 무렵 방문하면 사진 찍기 좋습니다.",
            tags: ["대청호", "오백리길", "관광지", "드라이브", "산책", "자연", "데이트", "가족"],
            createdAt: Date(), updatedAt: Date()
        ),
        Store(
            id: "store-019", name: "으능정이 문화의거리", slug: "euneungjeongi-street",
            category: .date, district: .eunhaeng,
            shortDescription: "야간 조명과 먹거리를 즐기기 좋은 거리",
            storyTitle: "은행동 밤 산책을 시작하기 좋은 문화거리",
            founderStory: "으능정이 문화의거리는 은행동의 먹거리, 쇼핑, 야간 조명을 함께 즐길 수 있는 거리입니다. 성심당, 중앙로, 원도심 골목과 이어져 짧은 데이트 코스나 친구 모임 코스로 활용하기 좋습니다.",
            signaturePoint: "야간 조명과 거리 분위기가 살아 있어 저녁 시간대 대전 원도심을 경험하기 좋습니다.",
            address: "대전 중구 은행동", phone: "방문 전 확인",
            openingHours: "상시 이용 가능",
            websiteURL: nil, instagramURL: nil,
            latitude: 36.3276, longitude: 127.4285,
            thumbnailURL: LocalImagery.nightStreet,
            coverImageURL: LocalImagery.nightStreet,
            menuItems: [
                MenuItem(id: "m56", name: "야간 거리 산책", price: "무료", isSignature: true),
                MenuItem(id: "m57", name: "원도심 먹거리 코스", price: "개별 이용", isSignature: false),
            ],
            visitTip: "저녁 식사 후 산책 코스로 잡으면 좋아요. 성심당 본점과 함께 묶기 좋습니다.",
            tags: ["으능정이", "문화의거리", "데이트", "은행동", "야간명소", "먹거리", "성심당"],
            createdAt: Date(), updatedAt: Date()
        ),
        Store(
            id: "store-020", name: "유성온천거리", slug: "yuseong-hot-spring-street",
            category: .experience, district: .bongmyeong,
            shortDescription: "온천과 족욕 체험을 즐길 수 있는 장소",
            storyTitle: "도심에서 가볍게 쉬어가는 온천 체험 거리",
            founderStory: "유성온천거리는 대전의 대표적인 온천 관광지입니다. 족욕 체험과 주변 맛집, 카페를 함께 즐길 수 있어 여행 중 쉬어가는 코스로 적합합니다.",
            signaturePoint: "짧은 시간에도 온천 분위기를 느낄 수 있는 족욕 체험이 매력입니다.",
            address: "대전 유성구 봉명동", phone: "방문 전 확인",
            openingHours: "시설별 상이",
            websiteURL: nil, instagramURL: nil,
            latitude: 36.3535, longitude: 127.3413,
            thumbnailURL: LocalImagery.warmStreet,
            coverImageURL: LocalImagery.warmStreet,
            menuItems: [
                MenuItem(id: "m58", name: "족욕 체험", price: "시설 확인", isSignature: true),
                MenuItem(id: "m59", name: "온천 거리 산책", price: "무료", isSignature: false),
            ],
            visitTip: "걷는 일정 사이에 넣으면 피로를 줄이기 좋습니다. 겨울철 방문 만족도가 높습니다.",
            tags: ["유성온천", "온천", "족욕", "체험", "봉명동", "힐링", "데이트"],
            createdAt: Date(), updatedAt: Date()
        ),
        Store(
            id: "store-021", name: "중앙시장", slug: "jungang-market",
            category: .restaurant, district: .wondong,
            shortDescription: "로컬 먹거리와 전통시장 분위기를 느낄 수 있는 곳",
            storyTitle: "대전 로컬 먹거리의 밀도를 느끼는 전통시장",
            founderStory: "중앙시장은 대전 원도심의 생활감과 먹거리를 가까이에서 느낄 수 있는 전통시장입니다. 간단한 간식부터 식사 메뉴까지 선택지가 넓어 맛집 탐방 코스로 활용하기 좋습니다.",
            signaturePoint: "로컬 상권의 생동감과 다양한 먹거리를 한 번에 경험할 수 있습니다.",
            address: "대전 동구 원동", phone: "방문 전 확인",
            openingHours: "점포별 상이",
            websiteURL: nil, instagramURL: nil,
            latitude: 36.3293, longitude: 127.4334,
            thumbnailURL: LocalImagery.market,
            coverImageURL: LocalImagery.market,
            menuItems: [
                MenuItem(id: "m60", name: "시장 먹거리 탐방", price: "점포별 상이", isSignature: true),
                MenuItem(id: "m61", name: "전통시장 산책", price: "무료", isSignature: false),
            ],
            visitTip: "현금과 카드 모두 준비하면 편합니다. 점심 전후로 방문하면 먹거리 선택지가 많습니다.",
            tags: ["중앙시장", "맛집", "시장", "원동", "로컬먹거리", "전통시장", "대전역"],
            createdAt: Date(), updatedAt: Date()
        ),
        Store(
            id: "store-022", name: "대전 0시 축제 거리", slug: "daejeon-midnight-festival-street",
            category: .festival, district: .eunhaeng,
            shortDescription: "대전 원도심을 무대로 열리는 대표 도심형 축제 스팟",
            storyTitle: "대전의 밤과 원도심을 축제로 연결하는 거리",
            founderStory: "대전 0시 축제 거리는 은행동과 중앙로 일대의 원도심 분위기를 축제로 확장해 보여주는 장소입니다. 공연, 먹거리, 야간 거리 분위기를 함께 경험하고 싶은 사용자에게 적합합니다.",
            signaturePoint: "축제 기간에는 대전 원도심의 이동 동선과 먹거리, 공연 콘텐츠가 한 번에 연결됩니다.",
            address: "대전 중구 중앙로·은행동 일대", phone: "축제 일정 확인",
            openingHours: "축제 기간별 상이",
            websiteURL: nil, instagramURL: nil,
            latitude: 36.3287, longitude: 127.4257,
            thumbnailURL: LocalImagery.festivalStreet,
            coverImageURL: LocalImagery.festivalStreet,
            menuItems: [
                MenuItem(id: "m62", name: "거리 공연", price: "축제별 상이", isSignature: true),
                MenuItem(id: "m63", name: "야간 먹거리", price: "점포별 상이", isSignature: false),
            ],
            visitTip: "축제 기간에는 대중교통 이용을 추천합니다. 은행동·중앙시장 코스와 함께 보기 좋습니다.",
            tags: ["축제", "대전0시축제", "은행동", "중앙로", "야간명소", "먹거리", "데이트"],
            createdAt: Date(), updatedAt: Date()
        ),
    ]

    // MARK: - Store Images
    static let storeImages: [StoreImage] = {
        let gallery: [String: [String]] = [
            "store-001": [LocalImagery.woodCafe, LocalImagery.coffeeTable, LocalImagery.cafeInterior, LocalImagery.alley],
            "store-002": [LocalImagery.homemadeMeal, LocalImagery.koreanFood, LocalImagery.warmStreet, LocalImagery.alley],
            "store-003": [LocalImagery.openBook, LocalImagery.typewriter, LocalImagery.bookstore, LocalImagery.warmStreet],
            "store-004": [LocalImagery.typewriter, LocalImagery.cafeInterior, LocalImagery.coffeeTable, LocalImagery.alley],
            "store-005": [LocalImagery.craftBeer, LocalImagery.wineBar, LocalImagery.nightStreet, LocalImagery.alley],
            "store-006": [LocalImagery.ceramics, LocalImagery.pottery, LocalImagery.gallery, LocalImagery.warmStreet],
            "store-007": [LocalImagery.gallery, LocalImagery.cafeInterior, LocalImagery.nightStreet, LocalImagery.alley],
            "store-013": [
                LocalImagery.lampJinheeShop,
                LocalImagery.lampJinheeShelf,
                LocalImagery.lampJinheeHorse,
                LocalImagery.lampJinheeCharacters,
                LocalImagery.lampJinheeFabric,
                LocalImagery.lampJinheePackages,
                LocalImagery.lampJinheeEntrance,
                LocalImagery.lampJinheeCalligraphy
            ],
            "store-008": [LocalImagery.koreanSoup, LocalImagery.homemadeMeal, LocalImagery.warmStreet, LocalImagery.alley],
            "store-009": [LocalImagery.bookstore, LocalImagery.openBook, LocalImagery.cafeInterior, LocalImagery.alley],
            "store-010": [LocalImagery.pottery, LocalImagery.ceramics, LocalImagery.gallery, LocalImagery.warmStreet],
            "store-011": [LocalImagery.wineBar, LocalImagery.nightStreet, LocalImagery.cafeInterior, LocalImagery.alley],
            "store-012": [LocalImagery.gardenCafe, LocalImagery.bakery, LocalImagery.pastries, LocalImagery.warmStreet],
        ]
        let lampJinheeCaptions = [
            "그림과 소품이 가득한 공간",
            "작가의 그림 소품 선반",
            "따뜻한 색감의 작품",
            "개성 있는 캐릭터 작품",
            "패브릭 개인작업",
            "성심당 협업 패키지",
            "대흥동 문화거리 전시",
            "작가의 손글씨 소개문"
        ]

        return stores.flatMap { store in
            let urls = gallery[store.id] ?? [LocalImagery.warmStreet, LocalImagery.alley, LocalImagery.cafeInterior, LocalImagery.coffeeTable]
            return urls.enumerated().map { (idx, url) in
                let caption: String?
                if store.id == "store-013", idx < lampJinheeCaptions.count {
                    caption = lampJinheeCaptions[idx]
                } else {
                    caption = idx == 0 ? "공간 전경" : idx == 1 ? "대표 메뉴" : idx == 2 ? "인테리어 디테일" : "골목 풍경"
                }

                return StoreImage(
                    id: "\(store.id)-img-\(idx + 1)",
                    storeId: store.id,
                    imageURL: url,
                    sortOrder: idx + 1,
                    caption: caption
                )
            }
        }
    }()

    // MARK: - Tashu Stations
    static let tashuStations: [TashuStation] = [
        TashuStation(
            id: "tashu-001",
            name: "성심당 본점 앞",
            district: .eunhaeng,
            latitude: 36.3279,
            longitude: 127.4270,
            availableBikes: 8,
            availableDocks: 4,
            note: "빵집 들른 뒤 바로 타기 좋은 대표 거점"
        ),
        TashuStation(
            id: "tashu-002",
            name: "중앙로역 2번 출구",
            district: .eunhaeng,
            latitude: 36.3287,
            longitude: 127.4255,
            availableBikes: 6,
            availableDocks: 7,
            note: "지하철에서 내려 원도심 코스로 이어지기 편한 지점"
        ),
        TashuStation(
            id: "tashu-003",
            name: "은행동 으능정이 거리",
            district: .eunhaeng,
            latitude: 36.3271,
            longitude: 127.4262,
            availableBikes: 5,
            availableDocks: 6,
            note: "은행동 가게 탐방 출발점으로 쓰기 좋음"
        ),
        TashuStation(
            id: "tashu-004",
            name: "대흥동 문화의거리",
            district: .daeheung,
            latitude: 36.3248,
            longitude: 127.4223,
            availableBikes: 9,
            availableDocks: 5,
            note: "전시, 술집, 로컬 상점 사이 이동이 편한 중심 스테이션"
        ),
        TashuStation(
            id: "tashu-005",
            name: "대흥양조장 인근",
            district: .daeheung,
            latitude: 36.3236,
            longitude: 127.4214,
            availableBikes: 3,
            availableDocks: 8,
            note: "야간 코스 전환용으로 좋은 대흥동 남측 거점"
        ),
        TashuStation(
            id: "tashu-006",
            name: "선화동 책방거리",
            district: .sunhwa,
            latitude: 36.3301,
            longitude: 127.4192,
            availableBikes: 7,
            availableDocks: 5,
            note: "선화동 산책 코스와 독립서점 탐방에 적합"
        ),
        TashuStation(
            id: "tashu-007",
            name: "대전천 산책길 입구",
            district: .daeheung,
            latitude: 36.3259,
            longitude: 127.4206,
            availableBikes: 4,
            availableDocks: 9,
            note: "대전천을 따라 이동하거나 야경 코스로 이어지기 좋음"
        ),
        TashuStation(
            id: "tashu-008",
            name: "선화교차로 생활권",
            district: .sunhwa,
            latitude: 36.3295,
            longitude: 127.4183,
            availableBikes: 2,
            availableDocks: 11,
            note: "선화동 권역 진입용 보조 스테이션"
        )
    ]

    // MARK: - Courses
    static let courses: [Course] = [
        Course(
            id: "course-001",
            title: "성심당 이후, 은행동 감성 한 바퀴",
            slug: "eunhaeng-after-sungsimdang",
            theme: .date, durationMinutes: 90, tashuDurationMinutes: 72, district: .eunhaeng,
            description: "성심당에서 빵을 사고 나서 뭐 하지? 은행동 골목 안쪽으로 들어가면, 레트로 카페에서 쉬고, 활판인쇄 체험까지 할 수 있는 감성 코스가 숨어 있어요.",
            coverImageURL: "\(LocalImagery.warmStreet)",
            isFeatured: true,
            stops: [
                CourseStop(id: "cs-001", courseId: "course-001", storeId: "store-001", stopOrder: 1, stayMinutes: 30, note: "할머니 찻잔으로 커피 한 잔"),
                CourseStop(id: "cs-002", courseId: "course-001", storeId: "store-003", stopOrder: 2, stayMinutes: 40, note: "나만의 문장을 활판인쇄로"),
                CourseStop(id: "cs-003", courseId: "course-001", storeId: "store-002", stopOrder: 3, stayMinutes: 20, note: "따뜻한 정식으로 마무리"),
            ],
            tags: ["은행동", "감성", "빵", "골목산책"],
            createdAt: Date()
        ),
        Course(
            id: "course-002",
            title: "대흥동 야간 감성 투어",
            slug: "daeheung-night-tour",
            theme: .night, durationMinutes: 120, tashuDurationMinutes: 88, district: .daeheung,
            description: "해가 질 무렵 대흥동으로 향하세요. 갤러리 옥상에서 석양을 보고, 로컬 수제맥주 한 잔, 대흥동 거리의 밤을 즐기는 코스.",
            coverImageURL: "\(LocalImagery.nightStreet)",
            isFeatured: true,
            stops: [
                CourseStop(id: "cs-004", courseId: "course-002", storeId: "store-007", stopOrder: 1, stayMinutes: 40, note: "전시 감상 + 옥상 석양"),
                CourseStop(id: "cs-005", courseId: "course-002", storeId: "store-005", stopOrder: 2, stayMinutes: 50, note: "대전 로컬 수제맥주 한 잔"),
                CourseStop(id: "cs-006", courseId: "course-002", storeId: "store-006", stopOrder: 3, stayMinutes: 30, note: "작가 소품 구경하며 산책"),
            ],
            tags: ["대흥동", "야경", "감성술집", "수제맥주"],
            createdAt: Date()
        ),
        Course(
            id: "course-006",
            title: "대흥동 그림 소품 산책",
            slug: "daeheung-art-prop-walk",
            theme: .photo, durationMinutes: 90, tashuDurationMinutes: 70, district: .daeheung,
            description: "대흥동 문화거리에서 지역 작가의 전시를 보고, 직접 만든 소품과 그림을 천천히 둘러보는 감성 산책 코스.",
            coverImageURL: LocalImagery.lampJinheeShelf,
            isFeatured: true,
            stops: [
                CourseStop(id: "cs-016", courseId: "course-006", storeId: "store-007", stopOrder: 1, stayMinutes: 30, note: "지역 작가 전시로 시작"),
                CourseStop(id: "cs-017", courseId: "course-006", storeId: "store-013", stopOrder: 2, stayMinutes: 35, note: "그림과 감성 소품 둘러보기"),
                CourseStop(id: "cs-018", courseId: "course-006", storeId: "store-006", stopOrder: 3, stayMinutes: 25, note: "작가 소품 하나 데려가기"),
            ],
            tags: ["대흥동", "전시", "공방", "소품샵", "사진"],
            createdAt: Date()
        ),
        Course(
            id: "course-003",
            title: "선화동 조용한 혼자 산책",
            slug: "sunhwa-solo-walk",
            theme: .solo, durationMinutes: 90, tashuDurationMinutes: 68, district: .sunhwa,
            description: "혼자만의 시간이 필요할 때. 독립서점에서 책 한 권 고르고, 도자기 만들고, 정원 카페에서 빵 한 조각.",
            coverImageURL: "\(LocalImagery.alley)",
            isFeatured: false,
            stops: [
                CourseStop(id: "cs-007", courseId: "course-003", storeId: "store-009", stopOrder: 1, stayMinutes: 30, note: "사장님 추천 책 한 권"),
                CourseStop(id: "cs-008", courseId: "course-003", storeId: "store-010", stopOrder: 2, stayMinutes: 40, note: "나만의 도자기 만들기"),
                CourseStop(id: "cs-009", courseId: "course-003", storeId: "store-012", stopOrder: 3, stayMinutes: 20, note: "정원에서 허브 빵과 차"),
            ],
            tags: ["선화동", "조용한", "전시", "골목산책"],
            createdAt: Date()
        ),
        Course(
            id: "course-004",
            title: "비 오는 날, 대흥동 실내 데이트",
            slug: "daeheung-rainy-date",
            theme: .rainy, durationMinutes: 120, tashuDurationMinutes: 92, district: .daeheung,
            description: "비가 와도 괜찮아요. 느린 우체통에서 편지 쓰고, 갤러리에서 전시 보고, 따뜻한 국밥 한 그릇.",
            coverImageURL: "\(LocalImagery.gallery)",
            isFeatured: true,
            stops: [
                CourseStop(id: "cs-010", courseId: "course-004", storeId: "store-004", stopOrder: 1, stayMinutes: 40, note: "1년 뒤 나에게 편지 쓰기"),
                CourseStop(id: "cs-011", courseId: "course-004", storeId: "store-007", stopOrder: 2, stayMinutes: 40, note: "비 오는 날의 전시 감상"),
                CourseStop(id: "cs-012", courseId: "course-004", storeId: "store-008", stopOrder: 3, stayMinutes: 30, note: "따뜻한 소머리국밥"),
                CourseStop(id: "cs-013", courseId: "course-004", storeId: "store-006", stopOrder: 4, stayMinutes: 20, note: "작가 소품 하나 데려가기"),
            ],
            tags: ["대흥동", "비의 낭만", "실내데이트", "전시"],
            createdAt: Date()
        ),
        Course(
            id: "course-005",
            title: "1시간 빠른 은행동 맛투어",
            slug: "eunhaeng-quick-food",
            theme: .food, durationMinutes: 60, tashuDurationMinutes: 44, district: .eunhaeng,
            description: "시간 없어도 괜찮아! 은행동에서 1시간 안에 즐기는 알짜 맛집 코스.",
            coverImageURL: "\(LocalImagery.homemadeMeal)",
            isFeatured: false,
            stops: [
                CourseStop(id: "cs-014", courseId: "course-005", storeId: "store-002", stopOrder: 1, stayMinutes: 35, note: "엄마표 정식 한 끼"),
                CourseStop(id: "cs-015", courseId: "course-005", storeId: "store-001", stopOrder: 2, stayMinutes: 25, note: "식후 레트로 카페에서 커피 한 잔"),
            ],
            tags: ["은행동", "맛집", "국밥", "로컬카페"],
            createdAt: Date()
        ),
    ]

    static let userGeneratedCourses: [UserGeneratedCourse] = [
        UserGeneratedCourse(
            id: "ugc-001",
            authorId: "user-jiwon",
            authorNickname: "빵순이 지원",
            authorAgeGroup: .twenties,
            title: "성심당 오픈런 뒤, 빵축제 예열 코스",
            description: "줄 서서 빵 사고 끝내기 아쉬워서 만든 은행동 달콤 코스. 카페 쉬는 타이밍까지 딱 맞아요.",
            coverImageURL: "\(LocalImagery.bakery)",
            theme: .food,
            district: .eunhaeng,
            tags: ["빵축제", "은행동", "빵", "로컬카페"],
            stops: [
                UserCourseStop(id: "ugc-001-stop-1", storeId: "store-001", placeName: "골목다방", latitude: 36.3275, longitude: 127.4272, stopOrder: 1, stayMinutes: 25, note: "빵 먹으면서 잠깐 쉬기", walkingDistanceMeters: 380, walkingDurationSeconds: 360, tashuDurationSeconds: 180),
                UserCourseStop(id: "ugc-001-stop-2", storeId: "store-003", placeName: "활자공방", latitude: 36.3270, longitude: 127.4280, stopOrder: 2, stayMinutes: 35, note: "엽서 한 장 찍고 나가기", walkingDistanceMeters: 260, walkingDurationSeconds: 240, tashuDurationSeconds: 120),
                UserCourseStop(id: "ugc-001-stop-3", storeId: "store-002", placeName: "소풍식탁", latitude: 36.3280, longitude: 127.4265, stopOrder: 3, stayMinutes: 30, note: "마무리는 따뜻한 한식", walkingDistanceMeters: 420, walkingDurationSeconds: 420, tashuDurationSeconds: 210)
            ],
            visibility: .publicOpen,
            likeCount: 126,
            viewCount: 890,
            completionCount: 32,
            createdAt: Date().addingTimeInterval(-86_400 * 1),
            updatedAt: Date().addingTimeInterval(-86_400 * 1)
        ),
        UserGeneratedCourse(
            id: "ugc-002",
            authorId: "user-minho",
            authorNickname: "타슈민호",
            authorAgeGroup: .twenties,
            title: "대흥동 금요일 야경 + 수제맥주 타슈 코스",
            description: "도보보다 타슈가 훨씬 재밌는 야간 루트. 석양 보고 맥주까지 이어지는 금요일용 동선입니다.",
            coverImageURL: "\(LocalImagery.craftBeer)",
            theme: .night,
            district: .daeheung,
            tags: ["대흥동", "야경", "감성술집", "수제맥주", "타슈"],
            stops: [
                UserCourseStop(id: "ugc-002-stop-1", storeId: "store-007", placeName: "빛 갤러리", latitude: 36.3250, longitude: 127.4230, stopOrder: 1, stayMinutes: 35, note: "옥상에서 석양 보기", walkingDistanceMeters: 540, walkingDurationSeconds: 480, tashuDurationSeconds: 220),
                UserCourseStop(id: "ugc-002-stop-2", storeId: "store-005", placeName: "대흥양조장", latitude: 36.3235, longitude: 127.4215, stopOrder: 2, stayMinutes: 45, note: "첫 잔은 대흥 에일", walkingDistanceMeters: 720, walkingDurationSeconds: 620, tashuDurationSeconds: 260),
                UserCourseStop(id: "ugc-002-stop-3", storeId: "store-006", placeName: "사물의 온도", latitude: 36.3245, longitude: 127.4225, stopOrder: 3, stayMinutes: 25, note: "소품샵 둘러보고 마무리", walkingDistanceMeters: 390, walkingDurationSeconds: 360, tashuDurationSeconds: 150)
            ],
            visibility: .publicOpen,
            likeCount: 184,
            viewCount: 1220,
            completionCount: 48,
            createdAt: Date().addingTimeInterval(-86_400 * 3),
            updatedAt: Date().addingTimeInterval(-86_400 * 2)
        ),
        UserGeneratedCourse(
            id: "ugc-003",
            authorId: "user-sora",
            authorNickname: "산책하는 소라",
            authorAgeGroup: .thirties,
            title: "선화동 벚꽃 시즌 느린 혼자 걷기",
            description: "벚꽃철에 조용히 걷고 싶을 때 저장해두는 선화동 루트. 책 한 권, 도자기 한 점, 허브빵 하나로 마무리돼요.",
            coverImageURL: "\(LocalImagery.bookstore)",
            theme: .solo,
            district: .sunhwa,
            tags: ["벚꽃축제", "선화동", "골목산책", "조용한"],
            stops: [
                UserCourseStop(id: "ugc-003-stop-1", storeId: "store-009", placeName: "먹물서점", latitude: 36.3300, longitude: 127.4190, stopOrder: 1, stayMinutes: 30, note: "이번 달 추천 책 확인", walkingDistanceMeters: 310, walkingDurationSeconds: 300, tashuDurationSeconds: 130),
                UserCourseStop(id: "ugc-003-stop-2", storeId: "store-010", placeName: "흙과 불", latitude: 36.3305, longitude: 127.4195, stopOrder: 2, stayMinutes: 40, note: "소형 클래스 한 번", walkingDistanceMeters: 280, walkingDurationSeconds: 270, tashuDurationSeconds: 120),
                UserCourseStop(id: "ugc-003-stop-3", storeId: "store-012", placeName: "빵굽는 정원", latitude: 36.3295, longitude: 127.4185, stopOrder: 3, stayMinutes: 25, note: "라벤더 스콘 추천", walkingDistanceMeters: 460, walkingDurationSeconds: 410, tashuDurationSeconds: 170)
            ],
            visibility: .publicOpen,
            likeCount: 94,
            viewCount: 610,
            completionCount: 19,
            createdAt: Date().addingTimeInterval(-86_400 * 5),
            updatedAt: Date().addingTimeInterval(-86_400 * 4)
        ),
        UserGeneratedCourse(
            id: "ugc-004",
            authorId: "user-haneul",
            authorNickname: "하늘이의 로컬픽",
            authorAgeGroup: .twenties,
            title: "0시축제 전, 대흥동 감성 압축 코스",
            description: "공연 보기 전에 짧고 밀도 있게 도는 루트. 사진 남기기 좋고 친구랑 가기 딱 좋아요.",
            coverImageURL: "\(LocalImagery.gallery)",
            theme: .friends,
            district: .daeheung,
            tags: ["0시축제", "대흥동", "감성", "전시"],
            stops: [
                UserCourseStop(id: "ugc-004-stop-1", storeId: "store-004", placeName: "느린우체통", latitude: 36.3240, longitude: 127.4220, stopOrder: 1, stayMinutes: 30, note: "한 줄 편지 남기기", walkingDistanceMeters: 360, walkingDurationSeconds: 320, tashuDurationSeconds: 140),
                UserCourseStop(id: "ugc-004-stop-2", storeId: "store-007", placeName: "빛 갤러리", latitude: 36.3250, longitude: 127.4230, stopOrder: 2, stayMinutes: 35, note: "전시 한 바퀴", walkingDistanceMeters: 340, walkingDurationSeconds: 310, tashuDurationSeconds: 130),
                UserCourseStop(id: "ugc-004-stop-3", storeId: "store-006", placeName: "사물의 온도", latitude: 36.3245, longitude: 127.4225, stopOrder: 3, stayMinutes: 20, note: "기념 소품 하나", walkingDistanceMeters: 250, walkingDurationSeconds: 240, tashuDurationSeconds: 100)
            ],
            visibility: .publicOpen,
            likeCount: 152,
            viewCount: 970,
            completionCount: 26,
            createdAt: Date().addingTimeInterval(-86_400 * 2),
            updatedAt: Date().addingTimeInterval(-86_400 * 1)
        ),
        UserGeneratedCourse(
            id: "ugc-005",
            authorId: "user-arin",
            authorNickname: "아린픽",
            authorAgeGroup: .twenties,
            title: "20대가 저장한 은행동 데이트 국룰",
            description: "대화 흐름이 끊기지 않게 짠 데이트 동선. 식사, 카페, 체험이 밸런스 좋게 이어집니다.",
            coverImageURL: "\(LocalImagery.warmStreet)",
            theme: .date,
            district: .eunhaeng,
            tags: ["은행동", "감성", "데이트", "골목산책"],
            stops: [
                UserCourseStop(id: "ugc-005-stop-1", storeId: "store-002", placeName: "소풍식탁", latitude: 36.3280, longitude: 127.4265, stopOrder: 1, stayMinutes: 35, note: "식사 먼저", walkingDistanceMeters: 420, walkingDurationSeconds: 390, tashuDurationSeconds: 170),
                UserCourseStop(id: "ugc-005-stop-2", storeId: "store-001", placeName: "골목다방", latitude: 36.3275, longitude: 127.4272, stopOrder: 2, stayMinutes: 30, note: "레트로 사진 남기기", walkingDistanceMeters: 350, walkingDurationSeconds: 330, tashuDurationSeconds: 150),
                UserCourseStop(id: "ugc-005-stop-3", storeId: "store-003", placeName: "활자공방", latitude: 36.3270, longitude: 127.4280, stopOrder: 3, stayMinutes: 35, note: "같이 찍는 문장 체험", walkingDistanceMeters: 260, walkingDurationSeconds: 240, tashuDurationSeconds: 110)
            ],
            visibility: .publicOpen,
            likeCount: 211,
            viewCount: 1410,
            completionCount: 57,
            createdAt: Date().addingTimeInterval(-86_400 * 6),
            updatedAt: Date().addingTimeInterval(-86_400 * 3)
        )
    ]

    // MARK: - Helpers
    static func store(byId id: String) -> Store? {
        stores.first { $0.id == id }
    }

    static func images(forStore storeId: String) -> [StoreImage] {
        storeImages.filter { $0.storeId == storeId }.sorted { $0.sortOrder < $1.sortOrder }
    }

    static func storesForCourse(_ course: Course) -> [(stop: CourseStop, store: Store)] {
        course.stops
            .sorted { $0.stopOrder < $1.stopOrder }
            .compactMap { stop in
                guard let store = store(byId: stop.storeId) else { return nil }
                return (stop: stop, store: store)
            }
    }

    static func userGeneratedCourse(byId id: String) -> UserGeneratedCourse? {
        userGeneratedCourses.first { $0.id == id }
    }

    static func tashuStation(byId id: String) -> TashuStation? {
        tashuStations.first { $0.id == id }
    }

    static func storesForUserCourse(_ course: UserGeneratedCourse) -> [(stop: UserCourseStop, store: Store?)] {
        course.stops
            .sorted { $0.stopOrder < $1.stopOrder }
            .map { stop in
                let store = stop.storeId.flatMap(store(byId:))
                return (stop: stop, store: store)
            }
    }
}
