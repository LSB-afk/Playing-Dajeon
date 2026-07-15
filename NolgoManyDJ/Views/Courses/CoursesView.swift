import SwiftUI

struct CoursesView: View {
    @State private var selectedDuration: CourseDuration? = nil
    @State private var selectedTheme: CourseTheme? = nil
    private let courses = MockData.courses

    var body: some View {
        NavigationStack {
            ScrollView(.vertical, showsIndicators: false) {
                VStack(spacing: AppSpacing.lg) {
                    // MARK: - Duration Filter
                    VStack(alignment: .leading, spacing: AppSpacing.md) {
                        SectionHeader(title: "소요 시간", subtitle: "여유 시간에 맞는 코스를 골라보세요")

                        HStack(spacing: AppSpacing.sm) {
                            durationButton(nil, label: "전체")
                            ForEach(CourseDuration.allCases) { duration in
                                durationButton(duration, label: duration.label)
                            }
                        }
                        .padding(.horizontal, AppSpacing.md)
                    }

                    // MARK: - Theme Filter
                    VStack(alignment: .leading, spacing: AppSpacing.md) {
                        SectionHeader(title: "테마", subtitle: "기분에 맞는 코스를 찾아보세요")

                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: AppSpacing.sm) {
                                FilterChip(
                                    label: "전체",
                                    isSelected: selectedTheme == nil,
                                    action: { selectedTheme = nil }
                                )
                                ForEach(CourseTheme.allCases) { theme in
                                    FilterChip(
                                        label: "\(theme.emoji) \(theme.rawValue)",
                                        isSelected: selectedTheme == theme,
                                        action: { selectedTheme = theme }
                                    )
                                }
                            }
                            .padding(.horizontal, AppSpacing.md)
                        }
                    }

                    // MARK: - Course List
                    LazyVStack(spacing: AppSpacing.lg) {
                        ForEach(filteredCourses) { course in
                            CourseCard(course: course, style: .standard)
                                .padding(.horizontal, AppSpacing.md)
                        }
                    }

                    if filteredCourses.isEmpty {
                        EmptyStateView(
                            icon: "point.topleft.down.to.point.bottomright.curvepath",
                            title: "코스가 없어요",
                            message: "다른 조건으로 검색해보세요"
                        )
                    }

                    Spacer(minLength: AppSpacing.xxl)
                }
            }
            .background(Color.appBackground)
            .navigationTitle("")
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Text("코스")
                        .font(AppFont.title(26))
                        .foregroundStyle(.appTextPrimary)
                }
            }
            .navigationDestination(for: Course.self) { course in
                CourseDetailView(course: course)
            }
            .navigationDestination(for: Store.self) { store in
                StoreDetailView(store: store)
            }
        }
    }

    // MARK: - Duration Button
    private func durationButton(_ duration: CourseDuration?, label: String) -> some View {
        Button {
            withAnimation { selectedDuration = duration }
        } label: {
            Text(label)
                .font(AppFont.label(14))
                .foregroundStyle(selectedDuration == duration ? .white : .appTextSecondary)
                .padding(.horizontal, 18)
                .padding(.vertical, 10)
                .background(selectedDuration == duration ? Color.appPrimary : Color.appSurfaceDim)
                .clipShape(RoundedRectangle(cornerRadius: AppRadius.md))
        }
    }

    // MARK: - Filtered Courses
    private var filteredCourses: [Course] {
        courses.filter { course in
            let durationMatch = selectedDuration == nil || course.durationMinutes <= selectedDuration!.rawValue
            let themeMatch = selectedTheme == nil || course.theme == selectedTheme
            return durationMatch && themeMatch
        }
    }
}
