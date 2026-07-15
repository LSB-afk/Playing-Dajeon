import Foundation
import MapKit

// MARK: - DataService Protocol
// Mock과 Supabase 구현을 쉽게 교체할 수 있도록 프로토콜 분리
protocol DataServiceProtocol {
    func fetchStores() async -> [Store]
    func fetchStore(byId id: String) async -> Store?
    func fetchStoreImages(storeId: String) async -> [StoreImage]
    func fetchCourses() async -> [Course]
    func fetchCourse(byId id: String) async -> Course?
    func fetchFeaturedCourses() async -> [Course]
    func fetchStores(district: District) async -> [Store]
    func fetchStores(category: StoreCategory) async -> [Store]
    func fetchCourses(theme: CourseTheme) async -> [Course]
    func fetchCourses(maxDuration: Int) async -> [Course]
}

// MARK: - Mock DataService
class MockDataService: DataServiceProtocol {
    func fetchStores() async -> [Store] {
        MockData.stores
    }

    func fetchStore(byId id: String) async -> Store? {
        MockData.store(byId: id)
    }

    func fetchStoreImages(storeId: String) async -> [StoreImage] {
        MockData.images(forStore: storeId)
    }

    func fetchCourses() async -> [Course] {
        MockData.courses
    }

    func fetchCourse(byId id: String) async -> Course? {
        MockData.courses.first { $0.id == id }
    }

    func fetchFeaturedCourses() async -> [Course] {
        MockData.courses.filter { $0.isFeatured }
    }

    func fetchStores(district: District) async -> [Store] {
        MockData.stores.filter { $0.district == district }
    }

    func fetchStores(category: StoreCategory) async -> [Store] {
        MockData.stores.filter { $0.category == category }
    }

    func fetchCourses(theme: CourseTheme) async -> [Course] {
        MockData.courses.filter { $0.theme == theme }
    }

    func fetchCourses(maxDuration: Int) async -> [Course] {
        MockData.courses.filter { $0.durationMinutes <= maxDuration }
    }
}

// MARK: - Service Container
// 추후 Supabase 서비스로 교체 시 여기만 변경
class ServiceContainer {
    static let shared = ServiceContainer()
    let dataService: DataServiceProtocol = MockDataService()
}

// MARK: - Route Planner
struct RoutePlannerStop: Identifiable, Hashable {
    let id: String
    let title: String
    let subtitle: String
    let mapItem: MKMapItem
    let stayMinutes: Int

    static func fromStore(_ store: Store, stayMinutes: Int = 0) -> RoutePlannerStop {
        let item = MKMapItem(placemark: MKPlacemark(coordinate: store.coordinate))
        item.name = store.name

        return RoutePlannerStop(
            id: store.id,
            title: store.name,
            subtitle: "\(store.category.rawValue) · \(store.address)",
            mapItem: item,
            stayMinutes: stayMinutes
        )
    }
}

struct RoutePlannerLeg {
    let source: RoutePlannerStop?
    let destination: RoutePlannerStop
    let route: MKRoute?
    let expectedTravelTime: TimeInterval
    let distance: CLLocationDistance
    let departureDate: Date
    let arrivalDate: Date
    let nextDepartureDate: Date
}

struct RoutePlannerResult {
    let orderedStops: [RoutePlannerStop]
    let legs: [RoutePlannerLeg]
    let totalTravelTime: TimeInterval
    let totalDistance: CLLocationDistance
    let totalStayTime: TimeInterval
    let startDate: Date
    let endDate: Date

    var totalDuration: TimeInterval {
        totalTravelTime + totalStayTime
    }
}

actor RoutePlannerService {
    static let shared = RoutePlannerService()

    func recommendRoute(
        stops: [RoutePlannerStop],
        transportType: MKDirectionsTransportType,
        departureDate: Date,
        start: MKMapItem? = nil
    ) async -> RoutePlannerResult? {
        let uniqueStops = deduplicated(stops)
        guard !uniqueStops.isEmpty else { return nil }
        guard uniqueStops.count > 1 else {
            let totalStayTime = TimeInterval(uniqueStops.reduce(0) { $0 + $1.stayMinutes } * 60)
            return RoutePlannerResult(
                orderedStops: uniqueStops,
                legs: [],
                totalTravelTime: 0,
                totalDistance: 0,
                totalStayTime: totalStayTime,
                startDate: departureDate,
                endDate: departureDate.addingTimeInterval(totalStayTime)
            )
        }

        let permutations = allPermutations(of: Array(uniqueStops.indices))
        var bestIndices: [Int]?
        var bestTravelTime = TimeInterval.greatestFiniteMagnitude

        for permutation in permutations {
            let ordered = permutation.map { uniqueStops[$0] }
            let estimate = await estimateTravelTime(
                for: ordered,
                transportType: transportType,
                departureDate: departureDate,
                start: start
            )

            if estimate < bestTravelTime {
                bestTravelTime = estimate
                bestIndices = permutation
            }
        }

        guard let bestIndices else { return nil }
        let orderedStops = bestIndices.map { uniqueStops[$0] }
        let legs = await buildLegs(
            for: orderedStops,
            transportType: transportType,
            departureDate: departureDate,
            start: start
        )

        let totalTravelTime = legs.reduce(0) { $0 + $1.expectedTravelTime }
        let totalDistance = legs.reduce(0) { $0 + $1.distance }
        let totalStayTime = TimeInterval(orderedStops.reduce(0) { $0 + $1.stayMinutes } * 60)

        return RoutePlannerResult(
            orderedStops: orderedStops,
            legs: legs,
            totalTravelTime: totalTravelTime,
            totalDistance: totalDistance,
            totalStayTime: totalStayTime,
            startDate: departureDate,
            endDate: legs.last?.nextDepartureDate ?? departureDate.addingTimeInterval(totalTravelTime + totalStayTime)
        )
    }

    private func estimateTravelTime(
        for stops: [RoutePlannerStop],
        transportType: MKDirectionsTransportType,
        departureDate: Date,
        start: MKMapItem?
    ) async -> TimeInterval {
        var total = TimeInterval.zero
        var source = start

        for stop in stops {
            total += await travelEstimate(
                from: source,
                to: stop.mapItem,
                transportType: transportType,
                departureDate: departureDate
            )
            source = stop.mapItem
        }

        return total
    }

    private func buildLegs(
        for stops: [RoutePlannerStop],
        transportType: MKDirectionsTransportType,
        departureDate: Date,
        start: MKMapItem?
    ) async -> [RoutePlannerLeg] {
        var legs: [RoutePlannerLeg] = []
        var source = start
        var currentDeparture = departureDate

        for stop in stops {
            let route = await route(
                from: source,
                to: stop.mapItem,
                transportType: transportType,
                departureDate: departureDate
            )
            let expectedTravelTime = route?.expectedTravelTime ?? 0
            let distance = route?.distance ?? 0
            let arrivalDate = currentDeparture.addingTimeInterval(expectedTravelTime)
            let nextDepartureDate = arrivalDate.addingTimeInterval(TimeInterval(stop.stayMinutes * 60))

            legs.append(
                RoutePlannerLeg(
                    source: source.flatMap { sourceItem in
                        RoutePlannerStop(
                            id: sourceItem.name ?? UUID().uuidString,
                            title: sourceItem.name ?? "시작 위치",
                            subtitle: sourceItem.placemark.title ?? "",
                            mapItem: sourceItem,
                            stayMinutes: 0
                        )
                    },
                    destination: stop,
                    route: route,
                    expectedTravelTime: expectedTravelTime,
                    distance: distance,
                    departureDate: currentDeparture,
                    arrivalDate: arrivalDate,
                    nextDepartureDate: nextDepartureDate
                )
            )

            source = stop.mapItem
            currentDeparture = nextDepartureDate
        }

        return legs
    }

    private func travelEstimate(
        from source: MKMapItem?,
        to destination: MKMapItem,
        transportType: MKDirectionsTransportType,
        departureDate: Date
    ) async -> TimeInterval {
        guard let source else { return 0 }

        let request = MKDirections.Request()
        request.source = source
        request.destination = destination
        request.transportType = transportType
        request.departureDate = departureDate

        let directions = MKDirections(request: request)
        let response = try? await directions.calculateETA()
        return response?.expectedTravelTime ?? 0
    }

    private func route(
        from source: MKMapItem?,
        to destination: MKMapItem,
        transportType: MKDirectionsTransportType,
        departureDate: Date
    ) async -> MKRoute? {
        guard let source else { return nil }

        let request = MKDirections.Request()
        request.source = source
        request.destination = destination
        request.transportType = transportType
        request.departureDate = departureDate
        request.requestsAlternateRoutes = false

        let directions = MKDirections(request: request)
        let response = try? await directions.calculate()
        return response?.routes.first
    }

    private func deduplicated(_ stops: [RoutePlannerStop]) -> [RoutePlannerStop] {
        var seen = Set<String>()
        return stops.filter { stop in
            seen.insert(stop.id).inserted
        }
    }

    private func allPermutations(of indices: [Int]) -> [[Int]] {
        guard !indices.isEmpty else { return [[]] }
        if indices.count == 1 { return [indices] }

        var result: [[Int]] = []
        for (offset, value) in indices.enumerated() {
            var remainder = indices
            remainder.remove(at: offset)
            for permutation in allPermutations(of: remainder) {
                result.append([value] + permutation)
            }
        }
        return result
    }
}
