import SwiftUI
import MapKit
import CoreLocation

struct MapExploreView: View {
    @Environment(AppState.self) private var appState
    @State private var locationManager = MapLocationManager()
    @State private var searchController = MapSearchController()

    @State private var cameraPosition: MapCameraPosition = .region(Self.defaultRegion)
    @State private var visibleRegion: MKCoordinateRegion?
    @State private var selectedCategory: StoreCategory?
    @State private var selectedMapSelection: MapSelection?
    @State private var detailItem: MapDetailItem?
    @State private var droppedPin: DroppedPin?
    @State private var route: MKRoute?
    @State private var lookAroundScene: MKLookAroundScene?
    @State private var mapStyle: ExploreMapStyle = .standard
    @State private var transportMode: RouteTransportMode = .tashu
    @State private var showsTraffic = true
    @State private var showsNearbyRadius = true
    @State private var showsTashuStations = true
    @State private var showsTashuSheet = false
    @State private var isDropPinMode = false
    @State private var isLoadingRoute = false
    @State private var isLoadingLookAround = false
    @State private var hasCenteredOnUser = false
    @State private var plannerStops: [RoutePlannerStop] = []
    @State private var plannerResult: RoutePlannerResult?
    @State private var isPlanningRoute = false
    @State private var routeDepartureDate = Date()
    @State private var useCurrentLocationAsStart = true
    @State private var showsTopOverlay = true
    @State private var showsPlaceCards = false
    @State private var selectedTashuStation: TashuStation?
    @State private var mapHeading: CLLocationDirection = 0
    @State private var mapPitch: CGFloat = 0
    @State private var mapDistance: CLLocationDistance = 1200

    private let stores = MockData.stores
    private let tashuStations = MockData.tashuStations

    private static let defaultRegion = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 36.3270, longitude: 127.4230),
        span: MKCoordinateSpan(latitudeDelta: 0.015, longitudeDelta: 0.015)
    )

    var body: some View {
        mapContent
        .background(Color.appBackground)
        .navigationTitle("지도 탐험")
        .navigationBarTitleDisplayMode(.inline)
        .overlay(alignment: .top) {
            if showsTopOverlay {
                topOverlay
                    .safeAreaPadding(.top)
                    .transition(.move(edge: .top).combined(with: .opacity))
            }
        }
        .overlay(alignment: .bottom) {
            bottomOverlay
                .safeAreaPadding(.bottom)
        }
        .sheet(item: $detailItem, onDismiss: clearTransientSelection) { item in
            MapSelectionSheet(
                item: item,
                route: route,
                lookAroundScene: lookAroundScene,
                transportMode: $transportMode,
                isLoadingRoute: isLoadingRoute,
                isLoadingLookAround: isLoadingLookAround,
                isPlannerFull: plannerStops.count >= 5,
                isInPlanner: plannerStops.contains(where: { $0.id == item.routePlannerStop.id }),
                openInMaps: { openInMaps(for: item) },
                recalculateRoute: { refreshRoute(for: item) },
                callPhone: { callPhoneNumber(for: item) },
                addToPlanner: { addToPlanner(item) }
            )
            .presentationDetents([.height(320), .fraction(0.58), .fraction(0.85)])
            .presentationDragIndicator(.visible)
            .presentationCornerRadius(AppRadius.xl)
        }
        .onAppear {
            locationManager.activate()
            searchController.updateRegion(visibleRegion ?? Self.defaultRegion)
            refreshVisiblePlaces()
        }
        .onChange(of: selectedMapSelection) { _, newValue in
            syncSelection(newValue)
        }
        .onChange(of: locationManager.region.map { "\($0.center.latitude),\($0.center.longitude)" }) { _, _ in
            guard let region = locationManager.region, !hasCenteredOnUser else { return }
            cameraPosition = .region(region)
            hasCenteredOnUser = true
        }
        .onChange(of: transportMode) { _, _ in
            if let detailItem {
                refreshRoute(for: detailItem)
            }
            if !plannerStops.isEmpty {
                calculatePlannerRoute()
            }
        }
        .onChange(of: selectedCategory) { _, _ in
            if searchController.query.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                refreshVisiblePlaces()
            }
        }
        .onChange(of: routeDepartureDate) { _, _ in
            if !plannerStops.isEmpty {
                calculatePlannerRoute()
            }
        }
        .onChange(of: useCurrentLocationAsStart) { _, _ in
            if !plannerStops.isEmpty {
                calculatePlannerRoute()
            }
        }
    }

    private var mapContent: some View {
        MapReader { proxy in
            Map(position: $cameraPosition, selection: $selectedMapSelection) {
                UserAnnotation()

                if showsNearbyRadius, let center = locationManager.region?.center {
                    MapCircle(center: center, radius: 450)
                        .foregroundStyle(Color.appAccent.opacity(0.12))
                }

                if showsTashuStations {
                    ForEach(displayedTashuStations) { station in
                        Annotation(station.name, coordinate: station.coordinate, anchor: .bottom) {
                            tashuStationPin(for: station, isSelected: selectedTashuStation?.id == station.id)
                        }
                        .tag(MapSelection.tashuStation(station.id))
                    }
                }

                ForEach(visibleStoresOnMap) { store in
                    Annotation(store.name, coordinate: store.coordinate, anchor: .bottom) {
                        storePin(for: store)
                    }
                    .tag(MapSelection.store(store.id))
                }

                ForEach(searchController.activeResults) { result in
                    Marker(result.title, systemImage: "magnifyingglass.circle.fill", coordinate: result.coordinate)
                        .tint(Color.appAccent)
                        .tag(MapSelection.search(result.id))
                }

                if let droppedPin {
                    Annotation("선택한 위치", coordinate: droppedPin.coordinate, anchor: .bottom) {
                        droppedPinView
                    }
                    .tag(MapSelection.droppedPin(droppedPin.id))
                }

                if let route {
                    MapPolyline(route.polyline)
                        .stroke(Color.appPrimary, lineWidth: 5)
                }

                if let plannerResult {
                    ForEach(Array(plannerResult.legs.enumerated()), id: \.offset) { index, leg in
                        if let route = leg.route {
                            MapPolyline(route.polyline)
                                .stroke(index == 0 ? Color.appSecondary : Color.appPrimary, style: StrokeStyle(lineWidth: 4, lineCap: .round, lineJoin: .round, dash: index == 0 ? [] : [10, 8]))
                        }
                    }
                }
            }
            .mapStyle(mapStyle.style(showsTraffic: showsTraffic))
            .mapControlVisibility(.hidden)
            .ignoresSafeArea(edges: .top)
            .onMapCameraChange(frequency: .onEnd) { context in
                visibleRegion = context.region
                searchController.updateRegion(context.region)
                mapHeading = context.camera.heading
                mapPitch = context.camera.pitch
                mapDistance = context.camera.distance
            }
            .simultaneousGesture(
                SpatialTapGesture()
                    .onEnded { value in
                        guard isDropPinMode else { return }
                        guard let coordinate = proxy.convert(value.location, from: .local) else { return }
                        dropPin(at: coordinate)
                    }
            )
        }
    }

    private var topOverlay: some View {
        VStack(spacing: AppSpacing.sm) {
            searchPanel
            if searchController.completions.isEmpty {
                if !searchController.activeResults.isEmpty {
                    resultCountBanner
                }
                categoryBar
                quickActionBar
                if shouldShowSearchAreaButton {
                    searchAreaButton
                }
            }
        }
        .padding(.horizontal, AppSpacing.md)
        .padding(.top, AppSpacing.sm)
    }

    private var bottomOverlay: some View {
        VStack(spacing: AppSpacing.sm) {
            if !plannerStops.isEmpty {
                plannerPanel
            } else if let selectedTashuStation {
                selectedTashuStationCard(selectedTashuStation)
            } else if let detailItem {
                selectionSummary(for: detailItem)
            } else if showsTashuSheet {
                tashuNearbySheet
            } else if showsPlaceCards && !searchController.activeResults.isEmpty {
                nearbyPlacesCarousel
            }

            HStack(alignment: .bottom) {
                Spacer()
                mapControlCluster
            }
        }
        .padding(.horizontal, AppSpacing.md)
        .padding(.bottom, AppSpacing.sm)
    }

    private var searchPanel: some View {
        VStack(spacing: AppSpacing.sm) {
            HStack(spacing: AppSpacing.sm) {
                Image(systemName: "magnifyingglass")
                    .foregroundStyle(.appTextSecondary)

                TextField(
                    "은행동 카페, 성심당, 대전역 근처...",
                    text: Binding(
                        get: { searchController.query },
                        set: { searchController.query = $0 }
                    )
                )
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
                .onSubmit {
                    refreshVisiblePlaces()
                }

                if searchController.isSearching {
                    ProgressView()
                        .controlSize(.small)
                } else if !searchController.query.isEmpty {
                    Button {
                        searchController.clear()
                        route = nil
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(.appTextTertiary)
                    }
                }
            }
            .padding(.horizontal, AppSpacing.md)
            .padding(.vertical, 14)
            .background(Color.appCardBackground)
            .clipShape(RoundedRectangle(cornerRadius: AppRadius.lg))
            .overlay(
                RoundedRectangle(cornerRadius: AppRadius.lg)
                    .stroke(Color.appDivider, lineWidth: 1)
            )
            .shadow(color: Color.appPrimary.opacity(0.08), radius: 16, y: 8)

            if !searchController.completions.isEmpty {
                ScrollView(.vertical, showsIndicators: false) {
                    VStack(spacing: 0) {
                        ForEach(searchController.completions.prefix(4), id: \.self) { completion in
                            Button {
                                searchController.query = completion.title
                                searchFromCompletion(completion)
                            } label: {
                                HStack(alignment: .top, spacing: AppSpacing.sm) {
                                    Image(systemName: "mappin.and.ellipse")
                                        .foregroundStyle(.appPrimary)
                                        .padding(.top, 2)

                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(completion.title)
                                            .font(AppFont.label(14))
                                            .foregroundStyle(.appTextPrimary)
                                            .frame(maxWidth: .infinity, alignment: .leading)

                                        if !completion.subtitle.isEmpty {
                                            Text(cleanAddress(completion.subtitle))
                                                .font(AppFont.caption(12))
                                                .foregroundStyle(.appTextSecondary)
                                                .frame(maxWidth: .infinity, alignment: .leading)
                                        }
                                    }
                                }
                                .padding(.horizontal, AppSpacing.md)
                                .padding(.vertical, 12)
                            }
                            .buttonStyle(.plain)

                            if completion != searchController.completions.prefix(4).last {
                                Divider()
                                    .padding(.leading, 44)
                            }
                        }
                    }
                }
                .frame(maxHeight: 240)
                .background(Color.appCardBackground)
                .clipShape(RoundedRectangle(cornerRadius: AppRadius.lg))
                .overlay(
                    RoundedRectangle(cornerRadius: AppRadius.lg)
                        .stroke(Color.appDivider, lineWidth: 1)
                )
                .shadow(color: Color.appPrimary.opacity(0.08), radius: 16, y: 8)
            }
        }
    }

    private var resultCountBanner: some View {
        HStack(spacing: AppSpacing.xs) {
            Image(systemName: "mappin.circle.fill")
            Text("실제 장소 \(searchController.activeResults.count)곳")
            if searchController.isLoadingNearby {
                ProgressView()
                    .controlSize(.small)
            }
        }
        .font(AppFont.caption(12))
        .foregroundStyle(.appPrimaryDark)
        .padding(.horizontal, AppSpacing.md)
        .padding(.vertical, 10)
        .background(Color.appCardBackground)
        .clipShape(Capsule())
        .overlay(Capsule().stroke(Color.appDivider, lineWidth: 1))
    }

    private var categoryBar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: AppSpacing.sm) {
                FilterChip(
                    label: "전체",
                    isSelected: selectedCategory == nil,
                    action: { selectedCategory = nil }
                )

                ForEach(StoreCategory.allCases) { category in
                    FilterChip(
                        label: category.rawValue,
                        icon: category.icon,
                        isSelected: selectedCategory == category,
                        action: { selectedCategory = category }
                    )
                }
            }
            .padding(.horizontal, AppSpacing.sm)
            .padding(.vertical, AppSpacing.sm)
        }
        .background(Color.appCardBackground)
        .clipShape(RoundedRectangle(cornerRadius: AppRadius.lg))
        .overlay(
            RoundedRectangle(cornerRadius: AppRadius.lg)
                .stroke(Color.appDivider, lineWidth: 1)
        )
    }

    private var quickActionBar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: AppSpacing.sm) {
                Menu {
                    Picker("지도 스타일", selection: $mapStyle) {
                        ForEach(ExploreMapStyle.allCases) { style in
                            Text(style.rawValue).tag(style)
                        }
                    }

                    Toggle("교통 정보", isOn: $showsTraffic)
                    Toggle("내 주변 반경", isOn: $showsNearbyRadius)
                } label: {
                    actionCapsuleLabel("지도 스타일", systemImage: mapStyle.icon)
                }

                Button {
                    withAnimation(.spring(response: 0.28, dampingFraction: 0.86)) {
                        showsTashuStations.toggle()
                        if showsTashuStations {
                            focusOnTashuStations()
                        } else {
                            selectedTashuStation = nil
                            selectedMapSelection = nil
                        }
                    }
                } label: {
                    actionCapsuleLabel(
                        showsTashuStations ? "타슈 대여소 숨기기" : "타슈 대여소",
                        systemImage: showsTashuStations ? "bicycle.circle.fill" : "bicycle.circle"
                    )
                }

                Button {
                    isDropPinMode.toggle()
                } label: {
                    actionCapsuleLabel(
                        isDropPinMode ? "핀 찍기 중" : "위치 찍기",
                        systemImage: isDropPinMode ? "mappin.circle.fill" : "mappin.circle"
                    )
                }
            }
        }
    }

    private var searchAreaButton: some View {
        Button {
            refreshVisiblePlaces()
        } label: {
            HStack(spacing: AppSpacing.xs) {
                Image(systemName: "arrow.clockwise")
                Text(searchController.query.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? "이 지도에서 실제 장소 찾기" : "이 지도에서 다시 검색")
            }
            .font(AppFont.label(13))
            .foregroundStyle(.white)
            .padding(.horizontal, AppSpacing.md)
            .padding(.vertical, 10)
            .background(Color.appPrimary)
            .clipShape(Capsule())
        }
    }

    private var mapControlCluster: some View {
        VStack(spacing: AppSpacing.sm) {
            mapControlButton(systemImage: "plus") {
                zoomMap(scale: 0.6)
            }

            mapControlButton(systemImage: "location.fill") {
                centerOnUser()
            }

            Button {
                resetHeading()
            } label: {
                Image(systemName: "location.north.line.fill")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(abs(mapHeading) > 1 ? Color.appPrimary : Color.appTextPrimary)
                    .rotationEffect(.degrees(mapHeading))
                    .frame(width: 22, height: 22)
                    .padding(12)
                    .background(.regularMaterial, in: RoundedRectangle(cornerRadius: AppRadius.md))
            }
            .buttonStyle(.plain)

            mapOptionsMenu

            mapControlButton(systemImage: "minus") {
                zoomMap(scale: 1.7)
            }
        }
    }

    private var mapOptionsMenu: some View {
        Menu {
            Button {
                withAnimation(.spring(response: 0.28, dampingFraction: 0.86)) {
                    showsTashuStations.toggle()
                    if showsTashuStations {
                        focusOnTashuStations()
                    } else {
                        selectedTashuStation = nil
                        selectedMapSelection = nil
                    }
                }
            } label: {
                Label(showsTashuStations ? "타슈 핀 숨기기" : "타슈 핀 보기", systemImage: "bicycle")
            }

            Button {
                withAnimation(.spring(response: 0.28, dampingFraction: 0.86)) {
                    showsTashuSheet.toggle()
                    if showsTashuSheet {
                        selectedTashuStation = nil
                    }
                }
            } label: {
                Label(showsTashuSheet ? "타슈 목록 접기" : "타슈 목록 열기", systemImage: "list.bullet.rectangle")
            }

            Divider()

            Button(action: togglePitch) {
                Label(mapPitch > 10 ? "2D로 보기" : "3D로 보기", systemImage: mapPitch > 10 ? "view.2d" : "view.3d")
            }

            Button {
                withAnimation(.spring(response: 0.28, dampingFraction: 0.86)) {
                    showsTopOverlay.toggle()
                }
            } label: {
                Label(showsTopOverlay ? "검색 도구 숨기기" : "검색 도구 보기", systemImage: "magnifyingglass")
            }

            Button {
                withAnimation(.spring(response: 0.28, dampingFraction: 0.86)) {
                    showsPlaceCards.toggle()
                }
            } label: {
                Label(showsPlaceCards ? "장소 카드 숨기기" : "장소 카드 보기", systemImage: "square.text.square")
            }
        } label: {
            Image(systemName: "slider.horizontal.3")
                .font(.system(size: 18, weight: .semibold))
                .foregroundStyle(Color.appTextPrimary)
                .frame(width: 22, height: 22)
                .padding(12)
                .background(
                    RoundedRectangle(cornerRadius: AppRadius.md)
                        .fill(Color.appCardBackground)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: AppRadius.md)
                        .stroke(Color.appDivider, lineWidth: 1)
                )
        }
        .buttonStyle(.plain)
    }

    private func mapControlButton(systemImage: String, isActive: Bool = false, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: systemImage)
                .font(.system(size: 18, weight: .semibold))
                .foregroundStyle(isActive ? Color.appPrimary : Color.appTextPrimary)
                .frame(width: 22, height: 22)
                .padding(12)
                .background(
                    RoundedRectangle(cornerRadius: AppRadius.md)
                        .fill(Color.appCardBackground)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: AppRadius.md)
                        .stroke(isActive ? Color.appPrimary.opacity(0.35) : Color.appDivider, lineWidth: 1)
                )
        }
        .buttonStyle(.plain)
    }

    private func selectionSummary(for item: MapDetailItem) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(item.title)
                .font(AppFont.label(14))
                .foregroundStyle(.appTextPrimary)

            Text(item.subtitle)
                .font(AppFont.caption(12))
                .foregroundStyle(.appTextSecondary)
                .lineLimit(2)

            if let route {
                Text(routeSummary(route))
                    .font(AppFont.caption(11))
                    .foregroundStyle(.appPrimary)
            }
        }
        .padding(.horizontal, AppSpacing.md)
        .padding(.vertical, 12)
        .background(Color.appCardBackground)
        .clipShape(RoundedRectangle(cornerRadius: AppRadius.lg))
        .overlay(
            RoundedRectangle(cornerRadius: AppRadius.lg)
                .stroke(Color.appDivider, lineWidth: 1)
        )
        .shadow(color: Color.appPrimary.opacity(0.08), radius: 16, y: 8)
        .frame(maxWidth: .infinity, alignment: .leading)
        .onTapGesture {
            detailItem = item
        }
    }

    private func actionCapsuleLabel(_ title: String, systemImage: String) -> some View {
        HStack(spacing: AppSpacing.xs) {
            Image(systemName: systemImage)
            Text(title)
        }
        .font(AppFont.label(13))
        .foregroundStyle(.appTextPrimary)
        .padding(.horizontal, AppSpacing.md)
        .padding(.vertical, 10)
        .background(Color.appCardBackground)
        .clipShape(Capsule())
        .overlay(Capsule().stroke(Color.appDivider, lineWidth: 1))
    }

    private func storePin(for store: Store) -> some View {
        VStack(spacing: 0) {
            Image(systemName: store.category.icon)
                .font(.system(size: 14, weight: .bold))
                .foregroundStyle(.white)
                .frame(width: 38, height: 38)
                .background(
                    Circle()
                        .fill(Color(hex: store.category.accentColor))
                        .shadow(color: .black.opacity(0.22), radius: 5, y: 3)
                )

            Triangle()
                .fill(Color(hex: store.category.accentColor))
                .frame(width: 12, height: 7)
        }
    }

    private func tashuStationPin(for station: TashuStation, isSelected: Bool) -> some View {
        VStack(spacing: 4) {
            ZStack(alignment: .topTrailing) {
                Circle()
                    .fill(isSelected ? Color.appPrimaryDark : Color(hex: station.availabilityAccentHex))
                    .frame(width: isSelected ? 42 : 38, height: isSelected ? 42 : 38)
                    .overlay(
                        Circle()
                            .stroke(Color.white, lineWidth: 3)
                    )
                    .shadow(color: Color.appPrimary.opacity(0.28), radius: 8, y: 4)

                Image(systemName: "bicycle")
                    .font(.system(size: 15, weight: .bold))
                    .foregroundStyle(.white)

                Text("\(station.availableBikes)")
                    .font(AppFont.caption(10))
                    .foregroundStyle(.appPrimaryDark)
                    .padding(.horizontal, 5)
                    .padding(.vertical, 2)
                    .background(Color.white, in: Capsule())
                    .offset(x: 10, y: -6)
            }

            if isSelected {
                Text(station.name)
                    .font(AppFont.caption(10))
                    .foregroundStyle(.appTextPrimary)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.appCardBackground, in: Capsule())
                    .overlay(Capsule().stroke(Color.appDivider, lineWidth: 1))
            }
        }
    }

    private var droppedPinView: some View {
        VStack(spacing: 0) {
            Image(systemName: "mappin")
                .font(.system(size: 16, weight: .bold))
                .foregroundStyle(.white)
                .frame(width: 38, height: 38)
                .background(
                    Circle()
                        .fill(Color.appPrimaryDark)
                        .shadow(color: .black.opacity(0.24), radius: 5, y: 3)
                )

            Triangle()
                .fill(Color.appPrimaryDark)
                .frame(width: 12, height: 7)
        }
    }

    private var tashuNearbySheet: some View {
        VStack(alignment: .leading, spacing: AppSpacing.md) {
            Capsule()
                .fill(Color.appDivider)
                .frame(width: 52, height: 5)
                .frame(maxWidth: .infinity)

            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("근처 타슈 대여소")
                        .font(AppFont.heading(20))
                        .foregroundStyle(.appTextPrimary)

                    Text("가까운 순으로 \(nearbyTashuStations.prefix(5).count)곳을 보여드려요")
                        .font(AppFont.caption(12))
                        .foregroundStyle(.appTextSecondary)
                }

                Spacer()

                HStack(spacing: AppSpacing.xs) {
                    summaryPill("\(nearbyBikeCount)대", systemImage: "bicycle.circle.fill")
                    summaryPill("\(nearbyDockCount)곳", systemImage: "parkingsign.circle.fill")
                }
            }

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: AppSpacing.sm) {
                    ForEach(nearbyTashuStations.prefix(5)) { station in
                        tashuStationCard(station)
                    }
                }
            }
        }
        .padding(AppSpacing.md)
        .background(Color.appCardBackground)
        .clipShape(RoundedRectangle(cornerRadius: AppRadius.xl))
        .overlay(
            RoundedRectangle(cornerRadius: AppRadius.xl)
                .stroke(Color.appDivider, lineWidth: 1)
        )
        .shadow(color: Color.appPrimary.opacity(0.08), radius: 16, y: 8)
    }

    private func selectedTashuStationCard(_ station: TashuStation) -> some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(station.name)
                        .font(AppFont.label(15))
                        .foregroundStyle(.appTextPrimary)

                    Text("\(station.district.rawValue) · \(station.note)")
                        .font(AppFont.caption(12))
                        .foregroundStyle(.appTextSecondary)
                        .lineLimit(2)
                }

                Spacer()

                Button {
                    selectedTashuStation = nil
                    selectedMapSelection = nil
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(.appTextTertiary)
                }
                .buttonStyle(.plain)
            }

            HStack(spacing: AppSpacing.xs) {
                summaryPill("자전거 \(station.availableBikes)대", systemImage: "bicycle")
                summaryPill("거치 \(station.availableDocks)곳", systemImage: "parkingsign")
                summaryPill("도보 \(walkMinutes(to: station.coordinate))분", systemImage: "figure.walk")
            }

            HStack(spacing: AppSpacing.sm) {
                Button {
                    focusCamera(on: [station.coordinate])
                    showsTashuSheet = false
                } label: {
                    Text("지도에서 보기")
                        .font(AppFont.label(13))
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(Color.appPrimary)
                        .clipShape(RoundedRectangle(cornerRadius: AppRadius.md))
                }
                .buttonStyle(.plain)

                Button {
                    openInMaps(for: station)
                } label: {
                    Text("길찾기")
                        .font(AppFont.label(13))
                        .foregroundStyle(.appPrimary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(Color.appPrimary.opacity(0.12))
                        .clipShape(RoundedRectangle(cornerRadius: AppRadius.md))
                }
                .buttonStyle(.plain)
            }
        }
        .padding(AppSpacing.md)
        .background(Color.appCardBackground)
        .clipShape(RoundedRectangle(cornerRadius: AppRadius.lg))
        .overlay(
            RoundedRectangle(cornerRadius: AppRadius.lg)
                .stroke(Color.appDivider, lineWidth: 1)
        )
        .shadow(color: Color.appPrimary.opacity(0.08), radius: 16, y: 8)
    }

    private func tashuStationCard(_ station: TashuStation) -> some View {
        Button {
            selectedTashuStation = station
            selectedMapSelection = .tashuStation(station.id)
            showsTashuSheet = false
            focusCamera(on: [station.coordinate])
        } label: {
            VStack(alignment: .leading, spacing: AppSpacing.sm) {
                HStack(spacing: AppSpacing.sm) {
                    ZStack {
                        RoundedRectangle(cornerRadius: AppRadius.md)
                            .fill(Color.appPrimary.opacity(0.12))
                            .frame(width: 52, height: 52)

                        Image(systemName: "bicycle.circle.fill")
                            .font(.system(size: 22, weight: .semibold))
                            .foregroundStyle(Color(hex: station.availabilityAccentHex))
                    }

                    VStack(alignment: .leading, spacing: 4) {
                        Text(station.name)
                            .font(AppFont.label(14))
                            .foregroundStyle(.appTextPrimary)
                            .lineLimit(2)

                        Text(station.district.rawValue)
                            .font(AppFont.caption(11))
                            .foregroundStyle(.appTextSecondary)
                    }

                    Spacer(minLength: 0)
                }

                HStack(spacing: AppSpacing.xs) {
                    stationInfoBadge("\(station.availableBikes)대", systemImage: "bicycle")
                    stationInfoBadge("\(station.availableDocks)곳", systemImage: "parkingsign")
                    stationInfoBadge("\(walkMinutes(to: station.coordinate))분", systemImage: "figure.walk")
                }

                Text(station.note)
                    .font(AppFont.caption(11))
                    .foregroundStyle(.appTextSecondary)
                    .lineLimit(2)
            }
            .frame(width: 264, alignment: .leading)
            .padding(AppSpacing.md)
            .background(Color.appSurfaceDim)
            .clipShape(RoundedRectangle(cornerRadius: AppRadius.lg))
            .overlay(
                RoundedRectangle(cornerRadius: AppRadius.lg)
                    .stroke(selectedTashuStation?.id == station.id ? Color.appPrimary.opacity(0.35) : Color.appDivider, lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }

    private func stationInfoBadge(_ text: String, systemImage: String) -> some View {
        HStack(spacing: 4) {
            Image(systemName: systemImage)
            Text(text)
        }
        .font(AppFont.caption(10))
        .foregroundStyle(.appPrimaryDark)
        .padding(.horizontal, 8)
        .padding(.vertical, 5)
        .background(Color.appCardBackground)
        .clipShape(Capsule())
        .overlay(Capsule().stroke(Color.appDivider, lineWidth: 1))
    }

    private var filteredStores: [Store] {
        if let category = selectedCategory {
            return stores.filter { $0.category == category }
        }
        return stores
    }

    private var displayedTashuStations: [TashuStation] {
        nearbyTashuStations
    }

    private var nearbyTashuStations: [TashuStation] {
        tashuStations.sorted {
            distance(from: mapReferenceCoordinate, to: $0.coordinate) < distance(from: mapReferenceCoordinate, to: $1.coordinate)
        }
    }

    private var nearbyBikeCount: Int {
        nearbyTashuStations.prefix(5).reduce(0) { $0 + $1.availableBikes }
    }

    private var nearbyDockCount: Int {
        nearbyTashuStations.prefix(5).reduce(0) { $0 + $1.availableDocks }
    }

    private var mapReferenceCoordinate: CLLocationCoordinate2D {
        locationManager.lastLocation?.coordinate ?? visibleRegion?.center ?? Self.defaultRegion.center
    }

    private var visibleStoresOnMap: [Store] {
        searchController.activeResults.isEmpty ? filteredStores : []
    }

    private var shouldShowSearchAreaButton: Bool {
        searchController.completions.isEmpty
    }

    private var plannerPanel: some View {
        VStack(alignment: .leading, spacing: AppSpacing.md) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("실시간 경로 플래너")
                        .font(AppFont.label(15))
                        .foregroundStyle(.appTextPrimary)

                    Text("실제 도로 ETA 기준으로 순서를 다시 추천합니다")
                        .font(AppFont.caption(12))
                        .foregroundStyle(.appTextSecondary)
                }

                Spacer()

                Button {
                    plannerStops.removeAll()
                    plannerResult = nil
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 18))
                        .foregroundStyle(.appTextTertiary)
                }
            }

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: AppSpacing.sm) {
                    ForEach(plannerStops) { stop in
                        HStack(spacing: AppSpacing.xs) {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(stop.title)
                                    .font(AppFont.caption(12))
                                    .foregroundStyle(.appTextPrimary)
                                    .lineLimit(1)

                                Text(stop.subtitle)
                                    .font(AppFont.caption(10))
                                    .foregroundStyle(.appTextSecondary)
                                    .lineLimit(1)
                            }

                            Button {
                                removePlannerStop(stop.id)
                            } label: {
                                Image(systemName: "minus.circle.fill")
                                    .foregroundStyle(.appPrimary)
                            }
                        }
                        .padding(.horizontal, AppSpacing.sm)
                        .padding(.vertical, 10)
                        .background(Color.appSurfaceDim.opacity(0.85))
                        .clipShape(RoundedRectangle(cornerRadius: AppRadius.md))
                    }
                }
            }

            ViewThatFits(in: .horizontal) {
                HStack(alignment: .center, spacing: AppSpacing.md) {
                    Toggle("현재 위치에서 시작", isOn: $useCurrentLocationAsStart)
                        .font(AppFont.caption(12))
                        .foregroundStyle(.appTextPrimary)

                    Spacer(minLength: 0)

                    DatePicker(
                        "출발 시간",
                        selection: $routeDepartureDate,
                        displayedComponents: [.date, .hourAndMinute]
                    )
                    .datePickerStyle(.compact)
                    .font(AppFont.caption(12))
                }

                VStack(alignment: .leading, spacing: AppSpacing.sm) {
                    Toggle("현재 위치에서 시작", isOn: $useCurrentLocationAsStart)
                        .font(AppFont.caption(12))
                        .foregroundStyle(.appTextPrimary)

                    DatePicker(
                        "출발 시간",
                        selection: $routeDepartureDate,
                        displayedComponents: [.date, .hourAndMinute]
                    )
                    .datePickerStyle(.compact)
                    .font(AppFont.caption(12))
                }
            }

            if let plannerResult {
                VStack(alignment: .leading, spacing: AppSpacing.sm) {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: AppSpacing.xs) {
                            summaryPill("총 \(plannerResult.orderedStops.count)곳", systemImage: "list.number")
                            summaryPill(routeTravelTime(plannerResult.totalTravelTime), systemImage: "clock.fill")
                            summaryPill(routeDistance(plannerResult.totalDistance), systemImage: transportMode.summaryIcon)
                            summaryPill(routeClockTime(plannerResult.startDate), systemImage: "play.circle.fill")
                            summaryPill(routeClockTime(plannerResult.endDate), systemImage: "flag.checkered")
                            if let etaBadgeText = transportMode.etaBadgeText {
                                summaryPill(etaBadgeText, systemImage: "bicycle.circle.fill")
                            }
                        }
                    }

                    if let plannerNotice = transportMode.plannerNotice {
                        Text(plannerNotice)
                            .font(AppFont.caption(11))
                            .foregroundStyle(.appTextSecondary)
                    }

                    ForEach(Array(plannerResult.legs.enumerated()), id: \.offset) { index, leg in
                        HStack(alignment: .top, spacing: AppSpacing.sm) {
                            Text("\(index + 1)")
                                .font(AppFont.caption(11))
                                .foregroundStyle(.white)
                                .frame(width: 22, height: 22)
                                .background(Circle().fill(Color.appPrimary))

                            VStack(alignment: .leading, spacing: 2) {
                                Text("\(leg.source?.title ?? "현재 위치") → \(leg.destination.title)")
                                    .font(AppFont.caption(12))
                                    .foregroundStyle(.appTextPrimary)
                                    .lineLimit(2)

                                Text("\(routeTravelTime(leg.expectedTravelTime)) · \(routeDistance(leg.distance)) · 체류 \(leg.destination.stayMinutes)분")
                                    .font(AppFont.caption(11))
                                    .foregroundStyle(.appTextSecondary)

                                Text("\(routeClockTime(leg.departureDate)) 출발 · \(routeClockTime(leg.arrivalDate)) 도착")
                                    .font(AppFont.caption(11))
                                    .foregroundStyle(.appPrimary)

                                if leg.destination.stayMinutes > 0 {
                                    Text("다음 이동 시작 \(routeClockTime(leg.nextDepartureDate))")
                                        .font(AppFont.caption(10))
                                        .foregroundStyle(.appTextSecondary)
                                }
                            }
                        }
                    }
                }
            } else if isPlanningRoute {
                HStack(spacing: AppSpacing.sm) {
                    ProgressView()
                    Text("실시간 교통과 거리 기준으로 추천 순서를 계산 중입니다")
                        .font(AppFont.caption(12))
                        .foregroundStyle(.appTextSecondary)
                }
            }
        }
        .padding(AppSpacing.md)
        .background(Color.appCardBackground)
        .clipShape(RoundedRectangle(cornerRadius: AppRadius.lg))
        .overlay(
            RoundedRectangle(cornerRadius: AppRadius.lg)
                .stroke(Color.appDivider, lineWidth: 1)
        )
        .shadow(color: Color.appPrimary.opacity(0.08), radius: 16, y: 8)
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var nearbyPlacesCarousel: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: AppSpacing.sm) {
                ForEach(searchController.activeResults.prefix(10)) { result in
                    Button {
                        selectedMapSelection = .search(result.id)
                        focusCamera(on: [result.coordinate])
                    } label: {
                        VStack(alignment: .leading, spacing: AppSpacing.xs) {
                            HStack(spacing: 6) {
                                Image(systemName: "mappin.circle.fill")
                                    .foregroundStyle(.appPrimary)

                                Text(result.title)
                                    .font(AppFont.label(14))
                                    .foregroundStyle(.appTextPrimary)
                                    .lineLimit(1)
                            }

                            Text(result.mapItem.pointOfInterestCategory?.displayName ?? "실제 장소")
                                .font(AppFont.caption(11))
                                .foregroundStyle(.appPrimary)

                            Text(result.subtitle.isEmpty ? (result.mapItem.placemark.title ?? "주소 정보 없음") : result.subtitle)
                                .font(AppFont.caption(11))
                                .foregroundStyle(.appTextSecondary)
                                .lineLimit(2)

                            if let phoneNumber = result.mapItem.phoneNumber {
                                Text(phoneNumber)
                                    .font(AppFont.caption(11))
                                    .foregroundStyle(.appTextTertiary)
                                    .lineLimit(1)
                            }
                        }
                        .frame(width: 220, alignment: .leading)
                        .padding(AppSpacing.md)
                        .background(Color.appCardBackground, in: RoundedRectangle(cornerRadius: AppRadius.lg))
                        .overlay(
                            RoundedRectangle(cornerRadius: AppRadius.lg)
                                .stroke(Color.appDivider, lineWidth: 1)
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    private func summaryPill(_ text: String, systemImage: String) -> some View {
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

    private func searchFromCompletion(_ completion: MKLocalSearchCompletion) {
        Task {
            await searchController.searchFromCompletion(completion)
            await MainActor.run {
                guard let first = searchController.activeResults.first else { return }
                selectedMapSelection = .search(first.id)
                focusCamera(on: searchController.activeResults.map(\.coordinate))
            }
        }
    }

    private func cleanAddress(_ address: String) -> String {
        var cleaned = address
        // 우편번호 제거 (앞쪽 5자리 숫자)
        cleaned = cleaned.replacingOccurrences(of: #"^\d{5}\s*"#, with: "", options: .regularExpression)
        // "대한민국 " 접두어 제거
        if cleaned.hasPrefix("대한민국 ") {
            cleaned = String(cleaned.dropFirst(5))
        }
        // 뒤쪽 우편번호 ", 12345" 제거
        cleaned = cleaned.replacingOccurrences(of: #",\s*\d{5}$"#, with: "", options: .regularExpression)
        return cleaned.trimmingCharacters(in: .whitespaces)
    }

    private func runSearch(for query: String) {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }

        let region = visibleRegion ?? locationManager.region ?? Self.defaultRegion
        Task {
            await searchController.search(for: trimmed, region: region)
            await MainActor.run {
                guard let first = searchController.activeResults.first else { return }
                selectedMapSelection = .search(first.id)
                focusCamera(on: searchController.activeResults.map(\.coordinate))
            }
        }
    }

    private func refreshVisiblePlaces() {
        let trimmed = searchController.query.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.isEmpty {
            let region = visibleRegion ?? locationManager.region ?? Self.defaultRegion
            Task {
                await searchController.searchNearby(category: selectedCategory, region: region)
                await MainActor.run { }
            }
        } else {
            runSearch(for: trimmed)
        }
    }

    private func dropPin(at coordinate: CLLocationCoordinate2D) {
        let pin = DroppedPin(coordinate: coordinate)
        droppedPin = pin
        selectedMapSelection = .droppedPin(pin.id)
        isDropPinMode = false
        focusCamera(on: [coordinate])
    }

    private func syncSelection(_ selection: MapSelection?) {
        guard let selection else {
            detailItem = nil
            return
        }

        switch selection {
        case .store(let id):
            selectedTashuStation = nil
            guard let store = stores.first(where: { $0.id == id }) else { return }
            detailItem = .store(store)
        case .search(let id):
            selectedTashuStation = nil
            guard let result = searchController.activeResults.first(where: { $0.id == id }) else { return }
            detailItem = .search(result)
        case .droppedPin(let id):
            selectedTashuStation = nil
            guard let droppedPin, droppedPin.id == id else { return }
            detailItem = .droppedPin(droppedPin)
        case .tashuStation(let id):
            detailItem = nil
            route = nil
            lookAroundScene = nil
            selectedTashuStation = tashuStations.first(where: { $0.id == id })
        }

        if let detailItem {
            refreshRoute(for: detailItem)
            refreshLookAround(for: detailItem)
        }
    }

    private func refreshRoute(for item: MapDetailItem) {
        guard locationManager.canRequestDirections else {
            route = nil
            isLoadingRoute = false
            return
        }

        isLoadingRoute = true
        route = nil

        let request = MKDirections.Request()
        request.source = locationManager.currentMapItem
        request.destination = item.mapItem
        request.transportType = transportMode.transportType
        request.requestsAlternateRoutes = false

        Task {
            let directions = MKDirections(request: request)
            let response = try? await directions.calculate()

            await MainActor.run {
                route = response?.routes.first
                isLoadingRoute = false

                if let route {
                    cameraPosition = .rect(route.polyline.boundingMapRect)
                }
            }
        }
    }

    private func refreshLookAround(for item: MapDetailItem) {
        lookAroundScene = nil
        isLoadingLookAround = true

        Task {
            let request = MKLookAroundSceneRequest(mapItem: item.mapItem)
            let scene = try? await request.scene

            await MainActor.run {
                lookAroundScene = scene
                isLoadingLookAround = false
            }
        }
    }

    private func openInMaps(for item: MapDetailItem) {
        item.mapItem.openInMaps(launchOptions: [
            MKLaunchOptionsDirectionsModeKey: transportMode.launchOption,
            MKLaunchOptionsMapTypeKey: mapStyle.mapType.rawValue,
            MKLaunchOptionsShowsTrafficKey: showsTraffic
        ])
    }

    private func openInMaps(for station: TashuStation) {
        let item = MKMapItem(placemark: MKPlacemark(coordinate: station.coordinate))
        item.name = station.name
        item.openInMaps(launchOptions: [
            MKLaunchOptionsDirectionsModeKey: MKLaunchOptionsDirectionsModeWalking,
            MKLaunchOptionsMapTypeKey: mapStyle.mapType.rawValue,
            MKLaunchOptionsShowsTrafficKey: showsTraffic
        ])
    }

    private func callPhoneNumber(for item: MapDetailItem) {
        guard let phoneNumber = item.phoneNumber else { return }
        let sanitized = phoneNumber
            .components(separatedBy: CharacterSet.decimalDigits.inverted)
            .joined()

        guard let url = URL(string: "tel://\(sanitized)"),
              UIApplication.shared.canOpenURL(url) else { return }

        UIApplication.shared.open(url)
    }

    private func addToPlanner(_ item: MapDetailItem) {
        let stop = item.routePlannerStop
        guard plannerStops.contains(where: { $0.id == stop.id }) == false else { return }
        guard plannerStops.count < 5 else { return }
        plannerStops.append(stop)
        calculatePlannerRoute()
    }

    private func removePlannerStop(_ id: String) {
        plannerStops.removeAll { $0.id == id }
        if plannerStops.isEmpty {
            plannerResult = nil
        } else {
            calculatePlannerRoute()
        }
    }

    private func calculatePlannerRoute() {
        guard plannerStops.count >= 2 else {
            plannerResult = nil
            return
        }

        isPlanningRoute = true
        let plannerStops = plannerStops
        let transportType = transportMode.transportType
        let departureDate = routeDepartureDate
        let start = useCurrentLocationAsStart && locationManager.canRequestDirections ? locationManager.currentMapItem : nil

        Task {
            let result = await RoutePlannerService.shared.recommendRoute(
                stops: plannerStops,
                transportType: transportType,
                departureDate: departureDate,
                start: start
            )

            await MainActor.run {
                plannerResult = result
                isPlanningRoute = false

                if let result {
                    focusCamera(on: result.orderedStops.map { $0.mapItem.placemark.coordinate })
                }
            }
        }
    }

    private func focusCamera(on coordinates: [CLLocationCoordinate2D]) {
        guard let rect = mapRect(for: coordinates) else { return }
        cameraPosition = .rect(rect)
    }

    private func focusOnTashuStations() {
        let coordinates = Array(nearbyTashuStations.prefix(4)).map(\.coordinate)
        guard coordinates.isEmpty == false else { return }
        focusCamera(on: coordinates)
    }

    private func zoomMap(scale: Double) {
        let region = visibleRegion ?? locationManager.region ?? Self.defaultRegion
        let adjusted = MKCoordinateRegion(
            center: region.center,
            span: MKCoordinateSpan(
                latitudeDelta: min(max(region.span.latitudeDelta * scale, 0.0015), 0.5),
                longitudeDelta: min(max(region.span.longitudeDelta * scale, 0.0015), 0.5)
            )
        )
        cameraPosition = .region(adjusted)
    }

    private func centerOnUser() {
        if let region = locationManager.region {
            cameraPosition = .region(region)
        } else {
            locationManager.activate()
        }
    }

    private func resetHeading() {
        let region = visibleRegion ?? locationManager.region ?? Self.defaultRegion
        cameraPosition = .camera(
            MapCamera(
                centerCoordinate: region.center,
                distance: resolvedCameraDistance(for: region),
                heading: 0,
                pitch: mapPitch
            )
        )
    }

    private func togglePitch() {
        let region = visibleRegion ?? locationManager.region ?? Self.defaultRegion
        cameraPosition = .camera(
            MapCamera(
                centerCoordinate: region.center,
                distance: resolvedCameraDistance(for: region),
                heading: mapHeading,
                pitch: mapPitch > 10 ? 0 : 55
            )
        )
    }

    private func resolvedCameraDistance(for region: MKCoordinateRegion) -> CLLocationDistance {
        if mapDistance > 0 {
            return mapDistance
        }

        let latMeters = region.span.latitudeDelta * 111_000
        let lonMeters = region.span.longitudeDelta * 111_000 * max(cos(region.center.latitude * .pi / 180), 0.2)
        return max(400, max(latMeters, lonMeters) * 1.8)
    }

    private func mapRect(for coordinates: [CLLocationCoordinate2D]) -> MKMapRect? {
        guard let first = coordinates.first else { return nil }

        return coordinates.dropFirst().reduce(
            MKMapRect(origin: MKMapPoint(first), size: MKMapSize(width: 1, height: 1))
        ) { partialResult, coordinate in
            partialResult.union(MKMapRect(origin: MKMapPoint(coordinate), size: MKMapSize(width: 1, height: 1)))
        }
    }

    private func routeSummary(_ route: MKRoute) -> String {
        "\(routeDistance(route.distance)) · \(routeTravelTime(route.expectedTravelTime))"
    }

    private func distance(from source: CLLocationCoordinate2D, to destination: CLLocationCoordinate2D) -> CLLocationDistance {
        CLLocation(latitude: source.latitude, longitude: source.longitude)
            .distance(from: CLLocation(latitude: destination.latitude, longitude: destination.longitude))
    }

    private func walkMinutes(to coordinate: CLLocationCoordinate2D) -> Int {
        let meters = distance(from: mapReferenceCoordinate, to: coordinate)
        return max(1, Int((meters / 75).rounded()))
    }

    private func routeDistance(_ distance: CLLocationDistance) -> String {
        if distance >= 1000 {
            return String(format: "%.1fkm", distance / 1000)
        }
        return "\(Int(distance))m"
    }

    private func routeTravelTime(_ time: TimeInterval) -> String {
        let formatter = DateComponentsFormatter()
        formatter.unitsStyle = .abbreviated
        formatter.allowedUnits = [.hour, .minute]
        return formatter.string(from: time) ?? "-"
    }

    private func routeClockTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ko_KR")
        formatter.dateFormat = "HH:mm"
        return formatter.string(from: date)
    }

    private func clearTransientSelection() {
        selectedMapSelection = nil
        selectedTashuStation = nil
    }
}

private struct MapSelectionSheet: View {
    let item: MapDetailItem
    let route: MKRoute?
    let lookAroundScene: MKLookAroundScene?
    @Binding var transportMode: RouteTransportMode
    let isLoadingRoute: Bool
    let isLoadingLookAround: Bool
    let isPlannerFull: Bool
    let isInPlanner: Bool
    let openInMaps: () -> Void
    let recalculateRoute: () -> Void
    let callPhone: () -> Void
    let addToPlanner: () -> Void

    @Environment(AppState.self) private var appState

    var body: some View {
        NavigationStack {
            ScrollView(.vertical, showsIndicators: false) {
                VStack(alignment: .leading, spacing: AppSpacing.lg) {
                    VStack(alignment: .leading, spacing: AppSpacing.xs) {
                        Text(item.title)
                            .font(AppFont.heading(20))
                            .foregroundStyle(.appTextPrimary)

                        Text(item.subtitle)
                            .font(AppFont.body(13))
                            .foregroundStyle(.appTextSecondary)
                    }

                    overviewSection
                    lookAroundSection
                    routeSection
                    actionSection
                }
                .padding(AppSpacing.lg)
            }
            .background(Color.appBackground)
            .navigationDestination(item: storeBinding) { store in
                StoreDetailView(store: store)
            }
        }
    }

    private var overviewSection: some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            sectionTitle("장소 정보")

            VStack(alignment: .leading, spacing: AppSpacing.sm) {
                infoPill(icon: "mappin.and.ellipse", text: item.addressText)

                if let categoryText = item.categoryText {
                    infoPill(icon: "tag.fill", text: categoryText)
                }

                if let phoneNumber = item.phoneNumber {
                    infoPill(icon: "phone.fill", text: phoneNumber)
                }

                if let website = item.websiteURL?.host {
                    infoPill(icon: "safari.fill", text: website)
                }
            }
            .padding(AppSpacing.md)
            .background(Color.appCardBackground)
            .clipShape(RoundedRectangle(cornerRadius: AppRadius.lg))
        }
    }

    @ViewBuilder
    private var lookAroundSection: some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            sectionTitle("Look Around")

            if let lookAroundScene {
                LookAroundPreview(initialScene: lookAroundScene)
                    .frame(height: 180)
                    .clipShape(RoundedRectangle(cornerRadius: AppRadius.lg))
            } else if isLoadingLookAround {
                loadingCard("주변 미리보기를 불러오는 중입니다")
            } else {
                emptyCard("이 위치는 Look Around 미리보기를 제공하지 않습니다")
            }
        }
    }

    @ViewBuilder
    private var routeSection: some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            sectionTitle("경로 정보")

            Picker("이동 수단", selection: $transportMode) {
                ForEach(RouteTransportMode.allCases) { mode in
                    Text(mode.rawValue).tag(mode)
                }
            }
            .pickerStyle(.segmented)

            if let route {
                VStack(alignment: .leading, spacing: AppSpacing.sm) {
                    infoPill(icon: "clock.fill", text: travelTime(route.expectedTravelTime))
                    infoPill(icon: transportMode.summaryIcon, text: distance(route.distance))

                    if let firstStep = route.steps.first(where: { !$0.instructions.isEmpty }) {
                        infoPill(icon: "arrow.triangle.turn.up.right.circle.fill", text: firstStep.instructions)
                    }
                }
                .padding(AppSpacing.md)
                .background(Color.appCardBackground)
                .clipShape(RoundedRectangle(cornerRadius: AppRadius.lg))
            } else if isLoadingRoute {
                loadingCard("현재 위치에서 경로를 계산하는 중입니다")
            } else {
                emptyCard("경로를 계산할 수 없었습니다. 위치 권한을 허용한 뒤 다시 시도해 보세요")
            }
        }
    }

    private var actionSection: some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            sectionTitle("빠른 작업")

            if let store = item.store {
                NavigationLink(value: store) {
                    actionButtonLabel("스토리 보기", systemImage: "book.fill", style: .filled)
                }
                .buttonStyle(.plain)

                Button {
                    appState.toggleSaveStore(store.id)
                } label: {
                    actionButtonLabel(
                        appState.isStoreSaved(store.id) ? "저장됨" : "저장",
                        systemImage: appState.isStoreSaved(store.id) ? "bookmark.fill" : "bookmark",
                        style: .soft
                    )
                }
                .buttonStyle(.plain)
            }

            Button(action: recalculateRoute) {
                actionButtonLabel("경로 다시 계산", systemImage: "arrow.trianglehead.clockwise", style: .soft)
            }
            .buttonStyle(.plain)

            Button(action: openInMaps) {
                actionButtonLabel("Apple 지도에서 열기", systemImage: "map.fill", style: .filled)
            }
            .buttonStyle(.plain)

            if !isInPlanner {
                Button(action: addToPlanner) {
                    actionButtonLabel(
                        isPlannerFull ? "플래너가 가득 찼습니다" : "경로 플래너에 추가",
                        systemImage: "point.3.filled.connected.trianglepath.dotted",
                        style: .soft
                    )
                }
                .buttonStyle(.plain)
                .disabled(isPlannerFull)
                .opacity(isPlannerFull ? 0.5 : 1)
            }

            if item.phoneNumber != nil {
                Button(action: callPhone) {
                    actionButtonLabel("전화하기", systemImage: "phone.fill", style: .soft)
                }
                .buttonStyle(.plain)
            }
        }
    }

    private var storeBinding: Binding<Store?> {
        Binding(
            get: { item.store },
            set: { _ in }
        )
    }

    private func sectionTitle(_ title: String) -> some View {
        Text(title)
            .font(AppFont.label(14))
            .foregroundStyle(.appTextPrimary)
    }

    private func loadingCard(_ text: String) -> some View {
        HStack(spacing: AppSpacing.sm) {
            ProgressView()
            Text(text)
                .font(AppFont.body(13))
                .foregroundStyle(.appTextSecondary)
        }
        .frame(maxWidth: .infinity, minHeight: 92)
        .background(Color.appCardBackground)
        .clipShape(RoundedRectangle(cornerRadius: AppRadius.lg))
    }

    private func emptyCard(_ text: String) -> some View {
        HStack(spacing: AppSpacing.sm) {
            Image(systemName: "eye.slash")
                .foregroundStyle(.appTextTertiary)
            Text(text)
                .font(AppFont.body(13))
                .foregroundStyle(.appTextSecondary)
        }
        .frame(maxWidth: .infinity, minHeight: 92)
        .background(Color.appCardBackground)
        .clipShape(RoundedRectangle(cornerRadius: AppRadius.lg))
    }

    private func infoPill(icon: String, text: String) -> some View {
        HStack(alignment: .top, spacing: AppSpacing.sm) {
            Image(systemName: icon)
                .foregroundStyle(.appPrimary)
                .frame(width: 18)

            Text(text)
                .font(AppFont.body(13))
                .foregroundStyle(.appTextPrimary)
        }
    }

    private func actionButtonLabel(_ title: String, systemImage: String, style: ActionButtonStyle) -> some View {
        HStack {
            Label(title, systemImage: systemImage)
                .font(AppFont.label(14))
                .foregroundStyle(style.foregroundColor)
            Spacer()
        }
        .padding(.horizontal, AppSpacing.md)
        .padding(.vertical, 14)
        .background(style.backgroundColor)
        .clipShape(RoundedRectangle(cornerRadius: AppRadius.md))
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

    private enum ActionButtonStyle {
        case filled
        case soft

        var foregroundColor: Color {
            switch self {
            case .filled: return .white
            case .soft: return .appPrimary
            }
        }

        var backgroundColor: Color {
            switch self {
            case .filled: return .appPrimary
            case .soft: return .appPrimary.opacity(0.12)
            }
        }
    }
}

private struct Triangle: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.midX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.minY))
        path.closeSubpath()
        return path
    }
}

private enum MapSelection: Hashable {
    case store(String)
    case search(UUID)
    case droppedPin(UUID)
    case tashuStation(String)
}

private struct DroppedPin: Identifiable, Hashable {
    let id = UUID()
    let coordinate: CLLocationCoordinate2D

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }

    static func == (lhs: DroppedPin, rhs: DroppedPin) -> Bool {
        lhs.id == rhs.id
    }
}

private struct MapSearchResult: Identifiable, Hashable {
    let id = UUID()
    let title: String
    let subtitle: String
    let mapItem: MKMapItem

    var coordinate: CLLocationCoordinate2D {
        mapItem.placemark.coordinate
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }

    static func == (lhs: MapSearchResult, rhs: MapSearchResult) -> Bool {
        lhs.id == rhs.id
    }
}

private enum MapDetailItem: Identifiable, Hashable {
    case store(Store)
    case search(MapSearchResult)
    case droppedPin(DroppedPin)

    var id: String {
        switch self {
        case .store(let store):
            return "store-\(store.id)"
        case .search(let result):
            return "search-\(result.id.uuidString)"
        case .droppedPin(let pin):
            return "pin-\(pin.id.uuidString)"
        }
    }

    var title: String {
        switch self {
        case .store(let store):
            return store.name
        case .search(let result):
            return result.title
        case .droppedPin:
            return "선택한 위치"
        }
    }

    var subtitle: String {
        switch self {
        case .store(let store):
            return "\(store.category.rawValue) · \(store.district.rawValue)"
        case .search(let result):
            return result.subtitle.isEmpty ? "Apple 지도 실제 검색 결과" : result.subtitle
        case .droppedPin(let pin):
            return String(format: "%.5f, %.5f", pin.coordinate.latitude, pin.coordinate.longitude)
        }
    }

    var addressText: String {
        switch self {
        case .store(let store):
            return store.address
        case .search(let result):
            return result.mapItem.placemark.title ?? result.subtitle
        case .droppedPin(let pin):
            return String(format: "위도 %.5f · 경도 %.5f", pin.coordinate.latitude, pin.coordinate.longitude)
        }
    }

    var categoryText: String? {
        switch self {
        case .store(let store):
            return store.category.rawValue
        case .search(let result):
            return result.mapItem.pointOfInterestCategory?.displayName
        case .droppedPin:
            return nil
        }
    }

    var store: Store? {
        if case .store(let store) = self {
            return store
        }
        return nil
    }

    var phoneNumber: String? {
        switch self {
        case .store(let store):
            return store.phone
        case .search(let result):
            return result.mapItem.phoneNumber
        case .droppedPin:
            return nil
        }
    }

    var websiteURL: URL? {
        switch self {
        case .store(let store):
            return store.websiteURL.flatMap(URL.init(string:))
        case .search(let result):
            return result.mapItem.url
        case .droppedPin:
            return nil
        }
    }

    var mapItem: MKMapItem {
        switch self {
        case .store(let store):
            let item = MKMapItem(placemark: MKPlacemark(coordinate: store.coordinate))
            item.name = store.name
            return item
        case .search(let result):
            return result.mapItem
        case .droppedPin(let pin):
            let item = MKMapItem(placemark: MKPlacemark(coordinate: pin.coordinate))
            item.name = "선택한 위치"
            return item
        }
    }

    var routePlannerStop: RoutePlannerStop {
        switch self {
        case .store(let store):
            return .fromStore(store, stayMinutes: 30)
        case .search(let result):
            return RoutePlannerStop(
                id: "search-\(result.id.uuidString)",
                title: result.title,
                subtitle: result.mapItem.placemark.title ?? result.subtitle,
                mapItem: result.mapItem,
                stayMinutes: 40
            )
        case .droppedPin(let pin):
            let mapItem = MKMapItem(placemark: MKPlacemark(coordinate: pin.coordinate))
            mapItem.name = "선택한 위치"

            return RoutePlannerStop(
                id: "pin-\(pin.id.uuidString)",
                title: "선택한 위치",
                subtitle: String(format: "%.5f, %.5f", pin.coordinate.latitude, pin.coordinate.longitude),
                mapItem: mapItem,
                stayMinutes: 10
            )
        }
    }
}

private extension MKPointOfInterestCategory {
    var displayName: String {
        switch self {
        case .cafe: return "카페"
        case .restaurant: return "식당"
        case .bakery: return "베이커리"
        case .brewery: return "양조장"
        case .nightlife: return "야간 스팟"
        case .store: return "상점"
        case .museum: return "문화 공간"
        case .library: return "서점/도서관"
        case .park: return "공원"
        default: return "주변 장소"
        }
    }
}

private extension MKMapRect {
    var centerCoordinate: CLLocationCoordinate2D {
        MKCoordinateRegion(self).center
    }
}

private enum ExploreMapStyle: String, CaseIterable, Identifiable {
    case standard = "일반"
    case hybrid = "하이브리드"
    case imagery = "위성"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .standard: return "map"
        case .hybrid: return "square.3.layers.3d"
        case .imagery: return "globe.americas.fill"
        }
    }

    func style(showsTraffic: Bool) -> MapStyle {
        switch self {
        case .standard:
            return .standard(elevation: .realistic, showsTraffic: showsTraffic)
        case .hybrid:
            return .hybrid(elevation: .realistic, showsTraffic: showsTraffic)
        case .imagery:
            return .imagery(elevation: .realistic)
        }
    }

    var mapType: MKMapType {
        switch self {
        case .standard: return .standard
        case .hybrid: return .hybrid
        case .imagery: return .satellite
        }
    }
}

enum RouteTransportMode: String, CaseIterable, Identifiable {
    case walking = "도보"
    case tashu = "타슈"

    var id: String { rawValue }

    var transportType: MKDirectionsTransportType {
        switch self {
        case .walking: return .walking
        case .tashu: return .cycling
        }
    }

    var launchOption: String {
        switch self {
        case .walking: return MKLaunchOptionsDirectionsModeWalking
        case .tashu: return MKLaunchOptionsDirectionsModeCycling
        }
    }

    var summaryIcon: String {
        switch self {
        case .walking: return "figure.walk"
        case .tashu: return "bicycle"
        }
    }

    var etaBadgeText: String? {
        switch self {
        case .walking: return nil
        case .tashu: return "타슈 자전거 ETA"
        }
    }

    var plannerNotice: String? {
        switch self {
        case .walking:
            return nil
        case .tashu:
            return "타슈 모드는 Apple 지도 자전거 경로를 이용해 예상 시간을 계산합니다."
        }
    }
}

@MainActor
@Observable
private final class MapLocationManager: NSObject, @preconcurrency CLLocationManagerDelegate {
    var authorizationStatus: CLAuthorizationStatus
    var lastLocation: CLLocation?
    var region: MKCoordinateRegion?

    private let manager = CLLocationManager()

    override init() {
        authorizationStatus = manager.authorizationStatus
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyBest
        manager.distanceFilter = 25
    }

    var currentMapItem: MKMapItem {
        if let lastLocation {
            let item = MKMapItem(placemark: MKPlacemark(coordinate: lastLocation.coordinate))
            item.name = "현재 위치"
            return item
        }
        return .forCurrentLocation()
    }

    var canRequestDirections: Bool {
        authorizationStatus == .authorizedAlways || authorizationStatus == .authorizedWhenInUse
    }

    func activate() {
        authorizationStatus = manager.authorizationStatus

        switch authorizationStatus {
        case .notDetermined:
            manager.requestWhenInUseAuthorization()
        case .authorizedAlways, .authorizedWhenInUse:
            manager.startUpdatingLocation()
            manager.requestLocation()
        default:
            break
        }
    }

    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        authorizationStatus = manager.authorizationStatus
        activate()
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        lastLocation = location
        region = MKCoordinateRegion(
            center: location.coordinate,
            span: MKCoordinateSpan(latitudeDelta: 0.012, longitudeDelta: 0.012)
        )
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("Map location update failed: \(error.localizedDescription)")
    }
}

@MainActor
@Observable
private final class MapSearchController: NSObject, @preconcurrency MKLocalSearchCompleterDelegate {
    var query: String = "" {
        didSet { scheduleCompletionUpdate() }
    }
    var completions: [MKLocalSearchCompletion] = []
    var results: [MapSearchResult] = []
    var nearbyResults: [MapSearchResult] = []
    var isSearching = false
    var isLoadingNearby = false

    private let completer = MKLocalSearchCompleter()
    private var searchTask: Task<Void, Never>?

    override init() {
        super.init()
        completer.delegate = self
        completer.resultTypes = [.pointOfInterest]
    }

    func updateRegion(_ region: MKCoordinateRegion) {
        completer.region = region
        if #available(iOS 18.0, *) {
            completer.regionPriority = .required
        }
    }

    func search(for query: String, region: MKCoordinateRegion) async {
        isSearching = true
        defer { isSearching = false }

        let request = MKLocalSearch.Request()
        request.naturalLanguageQuery = query
        request.resultTypes = [.address, .pointOfInterest]
        request.region = region

        let search = MKLocalSearch(request: request)
        let response = try? await search.start()

        results = normalizedResults(from: response?.mapItems ?? [])
        completions = []
    }

    func searchFromCompletion(_ completion: MKLocalSearchCompletion) async {
        isSearching = true
        defer { isSearching = false }

        let request = MKLocalSearch.Request(completion: completion)
        request.resultTypes = [.pointOfInterest, .address]

        let search = MKLocalSearch(request: request)
        let response = try? await search.start()

        results = normalizedResults(from: response?.mapItems ?? [])
        completions = []
    }

    func searchNearby(category: StoreCategory?, region: MKCoordinateRegion) async {
        isLoadingNearby = true
        defer { isLoadingNearby = false }

        let request = MKLocalSearch.Request()
        request.region = region
        request.resultTypes = .pointOfInterest
        request.pointOfInterestFilter = category?.pointOfInterestFilter ?? .defaultNearbyFilter

        let search = MKLocalSearch(request: request)
        let response = try? await search.start()
        nearbyResults = normalizedResults(from: response?.mapItems ?? [])
    }

    var activeResults: [MapSearchResult] {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nearbyResults : results
    }

    func clear() {
        query = ""
        completions = []
        results = []
    }

    func completerDidUpdateResults(_ completer: MKLocalSearchCompleter) {
        completions = completer.results
    }

    func completer(_ completer: MKLocalSearchCompleter, didFailWithError error: Error) {
        print("Map search completer failed: \(error.localizedDescription)")
    }

    private func scheduleCompletionUpdate() {
        searchTask?.cancel()

        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            completions = []
            return
        }

        searchTask = Task { [weak self] in
            try? await Task.sleep(nanoseconds: 250_000_000)
            guard !Task.isCancelled else { return }
            await MainActor.run {
                self?.completer.queryFragment = trimmed
            }
        }
    }

    private func normalizedResults(from mapItems: [MKMapItem]) -> [MapSearchResult] {
        var seen = Set<String>()

        return mapItems.compactMap { mapItem in
            let key = [
                mapItem.name ?? "",
                mapItem.placemark.thoroughfare ?? "",
                String(mapItem.placemark.coordinate.latitude),
                String(mapItem.placemark.coordinate.longitude)
            ].joined(separator: "|")

            guard seen.insert(key).inserted else { return nil }

            return MapSearchResult(
                title: mapItem.name ?? "검색 결과",
                subtitle: mapItem.placemark.title ?? "",
                mapItem: mapItem
            )
        }
    }
}

private extension StoreCategory {
    var pointOfInterestFilter: MKPointOfInterestFilter {
        switch self {
        case .cafe:
            return MKPointOfInterestFilter(including: [.cafe, .bakery])
        case .restaurant:
            return MKPointOfInterestFilter(including: [.restaurant, .bakery])
        case .attraction:
            return MKPointOfInterestFilter(including: [.museum, .park])
        case .festival:
            return MKPointOfInterestFilter(including: [.theater, .nightlife, .park])
        case .date:
            return MKPointOfInterestFilter(including: [.cafe, .restaurant, .nightlife, .park])
        case .family:
            return MKPointOfInterestFilter(including: [.museum, .park])
        case .experience:
            return MKPointOfInterestFilter(including: [.store, .museum])
        case .nightSpot:
            return MKPointOfInterestFilter(including: [.nightlife, .theater])
        case .bar:
            return MKPointOfInterestFilter(including: [.nightlife, .brewery])
        case .shop:
            return MKPointOfInterestFilter(including: [.store])
        case .workshop:
            return MKPointOfInterestFilter(including: [.store])
        case .culture:
            return MKPointOfInterestFilter(including: [.museum, .library, .theater])
        case .walkSpot:
            return MKPointOfInterestFilter(including: [.park])
        }
    }
}

private extension MKPointOfInterestFilter {
    static let defaultNearbyFilter = MKPointOfInterestFilter(
        including: [.cafe, .restaurant, .bakery, .nightlife, .store, .museum, .library, .park]
    )
}
