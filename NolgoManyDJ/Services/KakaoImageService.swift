import Foundation

// MARK: - Kakao Image Search API Service
// 카카오 이미지 검색 API를 통해 가게 관련 실제 이미지를 가져옴

@MainActor
@Observable
final class KakaoImageService {
    static let shared = KakaoImageService()

    private var imageCache: [String: [KakaoImage]] = [:]
    private var loadingStores: Set<String> = []

    private var restAPIKey: String? {
        if let environmentKey = ProcessInfo.processInfo.environment["KAKAO_REST_API_KEY"],
           !environmentKey.isEmpty {
            return environmentKey
        }

        guard let bundledKey = Bundle.main.object(forInfoDictionaryKey: "KAKAO_REST_API_KEY") as? String,
              !bundledKey.isEmpty,
              !bundledKey.contains("$(") else {
            return nil
        }

        return bundledKey
    }

    struct KakaoImage: Identifiable {
        let id = UUID()
        let imageURL: String
        let thumbnailURL: String
        let width: Int
        let height: Int
    }

    // MARK: - Public API

    /// 가게에 대한 카카오 이미지를 가져옴 (캐시 우선)
    func images(for store: Store) -> [KakaoImage] {
        imageCache[store.id] ?? []
    }

    /// 가게 이미지를 카카오 API에서 로드
    func loadImages(for store: Store) async {
        guard imageCache[store.id] == nil, !loadingStores.contains(store.id) else { return }
        loadingStores.insert(store.id)
        defer { loadingStores.remove(store.id) }

        // 1차: 가게명 + 지역으로 검색
        let specificQuery = "대전 \(store.district.rawValue) \(store.name)"
        var results = await searchImages(query: specificQuery, size: 8)

        // 2차: 결과 부족 시 카테고리로 검색
        if results.count < 3 {
            let categoryQuery = "대전 \(store.district.rawValue) \(store.category.rawValue)"
            let fallback = await searchImages(query: categoryQuery, size: 8)
            results.append(contentsOf: fallback)
            // 중복 제거
            var seen = Set<String>()
            results = results.filter { seen.insert($0.imageURL).inserted }
        }

        imageCache[store.id] = results
    }

    /// 캐시에 이미지가 있는지 확인
    func hasImages(for storeId: String) -> Bool {
        imageCache[storeId] != nil
    }

    /// 커버 이미지 URL (첫 번째 이미지)
    func coverImageURL(for store: Store) -> String? {
        imageCache[store.id]?.first?.imageURL
    }

    /// 썸네일 이미지 URL
    func thumbnailURL(for store: Store) -> String? {
        imageCache[store.id]?.first?.thumbnailURL
    }

    /// 갤러리 이미지들 (첫 번째 제외)
    func galleryImages(for store: Store) -> [KakaoImage] {
        guard let images = imageCache[store.id], images.count > 1 else { return [] }
        return Array(images.dropFirst())
    }

    // MARK: - Kakao Image Search API

    private func searchImages(query: String, size: Int) async -> [KakaoImage] {
        guard let restAPIKey,
              let encoded = query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
              let url = URL(string: "https://dapi.kakao.com/v2/search/image?query=\(encoded)&size=\(size)&page=1") else {
            return []
        }

        var request = URLRequest(url: url)
        request.setValue("KakaoAK \(restAPIKey)", forHTTPHeaderField: "Authorization")
        request.timeoutInterval = 10

        do {
            let (data, response) = try await URLSession.shared.data(for: request)

            guard let httpResponse = response as? HTTPURLResponse,
                  httpResponse.statusCode == 200 else {
                return []
            }

            let apiResponse = try JSONDecoder().decode(ImageSearchResponse.self, from: data)
            return apiResponse.documents.map {
                KakaoImage(
                    imageURL: $0.image_url,
                    thumbnailURL: $0.thumbnail_url,
                    width: $0.width,
                    height: $0.height
                )
            }
        } catch {
            return []
        }
    }
}

// MARK: - API Response Models

private struct ImageSearchResponse: Codable {
    let meta: ImageSearchMeta
    let documents: [ImageDocument]
}

private struct ImageSearchMeta: Codable {
    let total_count: Int
    let pageable_count: Int
    let is_end: Bool
}

private struct ImageDocument: Codable {
    let collection: String
    let thumbnail_url: String
    let image_url: String
    let width: Int
    let height: Int
    let display_sitename: String
    let doc_url: String
    let datetime: String
}
