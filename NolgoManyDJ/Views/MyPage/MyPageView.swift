import SwiftUI

enum OwnerDashboardRoute: Hashable {
    case dashboard
}

struct MyPageView: View {
    @Environment(AppState.self) private var appState

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: AppSpacing.lg) {
                    // MARK: - Profile Section
                    profileSection

                    // MARK: - Owner Dashboard Entry
                    ownerDashboardEntry

                    // MARK: - Visit Stats
                    visitStatsSection

                    // MARK: - Visit History
                    visitHistorySection

                    // MARK: - Menu Items
                    menuSection
                }
                .padding(.vertical, AppSpacing.md)
            }
            .background(Color.appBackground)
            .navigationTitle("")
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Text("마이")
                        .font(AppFont.title(26))
                        .foregroundStyle(.appTextPrimary)
                }
            }
            .navigationDestination(for: Store.self) { store in
                StoreDetailView(store: store)
            }
            .navigationDestination(for: OwnerDashboardRoute.self) { _ in
                OwnerDashboardView()
            }
        }
    }

    // MARK: - Owner Dashboard Entry
    private var ownerDashboardEntry: some View {
        NavigationLink(value: OwnerDashboardRoute.dashboard) {
            HStack(spacing: AppSpacing.md) {
                ZStack {
                    LinearGradient(
                        colors: [Color.appPrimary, Color.appSecondary],
                        startPoint: .topLeading, endPoint: .bottomTrailing
                    )
                    .frame(width: 44, height: 44)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    Image(systemName: "chart.line.uptrend.xyaxis")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundStyle(.white)
                }

                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: 6) {
                        Text("사장님 대시보드")
                            .font(AppFont.subtitle(15))
                            .foregroundStyle(.appTextPrimary)
                        Text("AI")
                            .font(AppFont.caption(10))
                            .foregroundStyle(.white)
                            .padding(.horizontal, 6).padding(.vertical, 2)
                            .background(Color.appPrimary, in: Capsule())
                    }
                    Text("우리 가게 유입·매출·시간대 한눈에 보기")
                        .font(AppFont.caption(12))
                        .foregroundStyle(.appTextSecondary)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(.appTextTertiary)
            }
            .padding(AppSpacing.md)
            .background(Color.appCardBackground, in: RoundedRectangle(cornerRadius: AppRadius.lg))
            .overlay(
                RoundedRectangle(cornerRadius: AppRadius.lg)
                    .stroke(Color.appPrimary.opacity(0.18), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
        .padding(.horizontal, AppSpacing.md)
    }

    // MARK: - Profile
    private var profileSection: some View {
        VStack(spacing: AppSpacing.md) {
            Image(systemName: "person.circle.fill")
                .font(.system(size: 64))
                .foregroundStyle(.appPrimary.opacity(0.5))

            Text("탐험가")
                .font(AppFont.subtitle(18))
                .foregroundStyle(.appTextPrimary)

            Text("로그인하면 방문 기록이 저장됩니다")
                .font(AppFont.caption(13))
                .foregroundStyle(.appTextTertiary)

            Button {
                // TODO: 로그인 구현
            } label: {
                Text("로그인 / 회원가입")
                    .font(AppFont.label(14))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 10)
                    .background(Color.appPrimary)
                    .clipShape(Capsule())
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, AppSpacing.xl)
        .background(Color.appCardBackground)
        .clipShape(RoundedRectangle(cornerRadius: AppRadius.lg))
        .padding(.horizontal, AppSpacing.md)
    }

    // MARK: - Visit Stats
    private var visitStatsSection: some View {
        HStack(spacing: 0) {
            statItem(count: appState.savedStoreIds.count, label: "저장한 가게")
            Divider().frame(height: 40)
            statItem(count: appState.savedCourseIds.count, label: "저장한 코스")
            Divider().frame(height: 40)
            statItem(count: appState.visitedStoreIds.count, label: "방문한 곳")
        }
        .padding(.vertical, AppSpacing.lg)
        .background(Color.appCardBackground)
        .clipShape(RoundedRectangle(cornerRadius: AppRadius.lg))
        .padding(.horizontal, AppSpacing.md)
    }

    private func statItem(count: Int, label: String) -> some View {
        VStack(spacing: 4) {
            Text("\(count)")
                .font(AppFont.title(24))
                .foregroundStyle(.appPrimary)
            Text(label)
                .font(AppFont.caption(12))
                .foregroundStyle(.appTextTertiary)
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Visit History
    private var visitHistorySection: some View {
        VStack(alignment: .leading, spacing: AppSpacing.md) {
            SectionHeader(title: "방문 기록", subtitle: "내가 다녀온 가게들")

            if appState.visitedStoreIds.isEmpty {
                EmptyStateView(
                    icon: "figure.walk",
                    title: "아직 방문 기록이 없어요",
                    message: "가게를 방문하고 '방문 완료' 버튼을 눌러보세요"
                )
            } else {
                let visitedStores = MockData.stores.filter { appState.isVisited($0.id) }
                LazyVStack(spacing: AppSpacing.sm) {
                    ForEach(visitedStores) { store in
                        StoreCard(store: store, style: .compact)
                    }
                }
                .padding(.horizontal, AppSpacing.md)
            }
        }
    }

    // MARK: - Menu
    private var menuSection: some View {
        VStack(spacing: 0) {
            menuRow(icon: "gearshape", title: "설정")
            Divider().padding(.horizontal, AppSpacing.md)
            menuRow(icon: "envelope", title: "가게 제보하기")
            Divider().padding(.horizontal, AppSpacing.md)
            menuRow(icon: "questionmark.circle", title: "도움말")
            Divider().padding(.horizontal, AppSpacing.md)
            menuRow(icon: "info.circle", title: "앱 정보")
        }
        .background(Color.appCardBackground)
        .clipShape(RoundedRectangle(cornerRadius: AppRadius.lg))
        .padding(.horizontal, AppSpacing.md)
    }

    private func menuRow(icon: String, title: String) -> some View {
        HStack(spacing: AppSpacing.md) {
            Image(systemName: icon)
                .font(.system(size: 16))
                .foregroundStyle(.appTextSecondary)
                .frame(width: 24)
            Text(title)
                .font(AppFont.body(15))
                .foregroundStyle(.appTextPrimary)
            Spacer()
            Image(systemName: "chevron.right")
                .font(.system(size: 12))
                .foregroundStyle(.appTextTertiary)
        }
        .padding(.horizontal, AppSpacing.lg)
        .padding(.vertical, AppSpacing.md)
    }
}
