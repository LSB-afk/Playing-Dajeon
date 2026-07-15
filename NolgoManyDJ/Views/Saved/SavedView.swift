import SwiftUI

struct SavedView: View {
    @Environment(AppState.self) private var appState
    @State private var selectedTab = 0

    private var savedStores: [Store] {
        MockData.stores.filter { appState.isStoreSaved($0.id) }
    }

    private var savedEditorCourses: [Course] {
        MockData.courses.filter { appState.isCourseSaved($0.id) }
    }

    private var savedSharedCourses: [UserGeneratedCourse] {
        MockData.userGeneratedCourses.filter { appState.isCourseSaved($0.id) }
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                Picker("", selection: $selectedTab) {
                    Text("가게").tag(0)
                    Text("에디터").tag(1)
                    Text("공유").tag(2)
                }
                .pickerStyle(.segmented)
                .padding(.horizontal, AppSpacing.lg)
                .padding(.vertical, AppSpacing.md)

                switch selectedTab {
                case 0:
                    savedStoresList
                case 1:
                    savedEditorCoursesList
                default:
                    savedSharedCoursesList
                }
            }
            .background(Color.appBackground)
            .navigationTitle("")
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Text("저장")
                        .font(AppFont.title(26))
                        .foregroundStyle(.appTextPrimary)
                }
            }
            .navigationDestination(for: Store.self) { store in
                StoreDetailView(store: store)
            }
            .navigationDestination(for: Course.self) { course in
                CourseDetailView(course: course)
            }
            .navigationDestination(for: UserGeneratedCourse.self) { course in
                SharedCourseDetailView(course: course)
            }
        }
    }

    private var savedStoresList: some View {
        Group {
            if savedStores.isEmpty {
                EmptyStateView(
                    icon: "bookmark",
                    title: "저장한 가게가 없어요",
                    message: "마음에 드는 가게를 발견하면\n북마크 버튼을 눌러 저장해보세요"
                )
            } else {
                ScrollView {
                    LazyVStack(spacing: AppSpacing.md) {
                        ForEach(savedStores) { store in
                            StoreCard(store: store, style: .compact)
                                .padding(.horizontal, AppSpacing.md)
                        }
                    }
                    .padding(.vertical, AppSpacing.sm)
                }
            }
        }
    }

    private var savedEditorCoursesList: some View {
        Group {
            if savedEditorCourses.isEmpty {
                EmptyStateView(
                    icon: "point.topleft.down.to.point.bottomright.curvepath",
                    title: "저장한 에디터 코스가 없어요",
                    message: "검증된 대전 코스를 저장해두고\n나중에 따라가보세요"
                )
            } else {
                ScrollView {
                    LazyVStack(spacing: AppSpacing.lg) {
                        ForEach(savedEditorCourses) { course in
                            CourseCard(course: course, style: .standard)
                                .padding(.horizontal, AppSpacing.md)
                        }
                    }
                    .padding(.vertical, AppSpacing.sm)
                }
            }
        }
    }

    private var savedSharedCoursesList: some View {
        Group {
            if savedSharedCourses.isEmpty {
                EmptyStateView(
                    icon: "person.3.sequence.fill",
                    title: "저장한 공유 경로가 없어요",
                    message: "홈 대시보드에서 마음에 드는 유저 경로를 저장하면\n여기에서 다시 꺼내볼 수 있어요"
                )
            } else {
                ScrollView {
                    LazyVStack(spacing: AppSpacing.lg) {
                        ForEach(savedSharedCourses) { course in
                            SharedCourseCard(course: course)
                                .padding(.horizontal, AppSpacing.md)
                        }
                    }
                    .padding(.vertical, AppSpacing.sm)
                }
            }
        }
    }
}
