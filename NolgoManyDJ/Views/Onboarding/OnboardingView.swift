import SwiftUI

struct OnboardingView: View {
    @Environment(AppState.self) private var appState
    @State private var currentPage = 0
    @State private var selectedThemes: Set<OnboardingTheme> = []

    var body: some View {
        ZStack {
            Color.appBackground.ignoresSafeArea()

            VStack(spacing: 0) {
                // Page indicator
                HStack(spacing: 6) {
                    ForEach(0..<3, id: \.self) { index in
                        Capsule()
                            .fill(index == currentPage ? Color.appPrimary : Color.appDivider)
                            .frame(width: index == currentPage ? 24 : 8, height: 4)
                    }
                }
                .padding(.top, AppSpacing.lg)
                .animation(.easeInOut, value: currentPage)

                TabView(selection: $currentPage) {
                    // Page 1: 소개
                    onboardingPage1.tag(0)
                    // Page 2: 테마 선택
                    onboardingPage2.tag(1)
                    // Page 3: 시작
                    onboardingPage3.tag(2)
                }
                .tabViewStyle(.page(indexDisplayMode: .never))

                // Bottom button
                Button {
                    if currentPage < 2 {
                        withAnimation { currentPage += 1 }
                    } else {
                        appState.selectedThemes = selectedThemes
                        appState.completeOnboarding()
                    }
                } label: {
                    Text(currentPage < 2 ? "다음" : "탐험 시작하기")
                        .font(AppFont.label(16))
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(Color.appPrimary)
                        .clipShape(RoundedRectangle(cornerRadius: AppRadius.md))
                }
                .padding(.horizontal, AppSpacing.lg)
                .padding(.bottom, AppSpacing.xl)

                if currentPage < 2 {
                    Button("건너뛰기") {
                        appState.completeOnboarding()
                    }
                    .font(AppFont.caption(14))
                    .foregroundStyle(.appTextTertiary)
                    .padding(.bottom, AppSpacing.md)
                }
            }
        }
    }

    // MARK: - Page 1
    private var onboardingPage1: some View {
        VStack(spacing: AppSpacing.lg) {
            Spacer()

            Image(systemName: "map.fill")
                .font(.system(size: 64))
                .foregroundStyle(.appPrimary)
                .padding(.bottom, AppSpacing.md)

            Text("놀거많은대?전")
                .font(AppFont.title(36))
                .foregroundStyle(.appTextPrimary)

            Text("대전 놀거리 추천 탐험")
                .font(AppFont.subtitle(18))
                .foregroundStyle(.appPrimary)

            VStack(spacing: AppSpacing.sm) {
                Text("은행동 · 대흥동 · 선화동")
                    .font(AppFont.body(16))
                    .foregroundStyle(.appTextSecondary)

                Text("맛집, 카페, 축제, 체험 공간까지\n대전에서 오늘 갈 곳을 추천해드려요")
                    .font(AppFont.body(15))
                    .foregroundStyle(.appTextSecondary)
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)
            }
            .padding(.top, AppSpacing.sm)

            Spacer()
            Spacer()
        }
        .padding(.horizontal, AppSpacing.lg)
    }

    // MARK: - Page 2: 관심 테마 선택
    private var onboardingPage2: some View {
        VStack(spacing: AppSpacing.lg) {
            Spacer()

            Text("어떤 탐험이 끌리세요?")
                .font(AppFont.title(24))
                .foregroundStyle(.appTextPrimary)

            Text("관심 테마를 골라주세요 (복수 선택 가능)")
                .font(AppFont.body(14))
                .foregroundStyle(.appTextSecondary)

            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible()),
            ], spacing: AppSpacing.md) {
                ForEach(OnboardingTheme.allCases) { theme in
                    themeCard(theme)
                }
            }
            .padding(.horizontal, AppSpacing.sm)

            Spacer()
            Spacer()
        }
        .padding(.horizontal, AppSpacing.md)
    }

    // MARK: - Page 3
    private var onboardingPage3: some View {
        VStack(spacing: AppSpacing.lg) {
            Spacer()

            Image(systemName: "sparkles")
                .font(.system(size: 56))
                .foregroundStyle(.appAccent)
                .padding(.bottom, AppSpacing.md)

            Text("준비 완료!")
                .font(AppFont.title(28))
                .foregroundStyle(.appTextPrimary)

            Text("대전 원도심의 숨은 이야기를\n지금 바로 만나보세요")
                .font(AppFont.body(16))
                .foregroundStyle(.appTextSecondary)
                .multilineTextAlignment(.center)
                .lineSpacing(4)

            // 선택한 테마 요약
            if !selectedThemes.isEmpty {
                HStack(spacing: AppSpacing.sm) {
                    ForEach(Array(selectedThemes).prefix(3)) { theme in
                        Text("\(theme.icon) \(theme.rawValue)")
                            .font(AppFont.caption(12))
                            .padding(.horizontal, 10)
                            .padding(.vertical, 6)
                            .background(Color.appPrimary.opacity(0.1))
                            .foregroundStyle(.appPrimary)
                            .clipShape(Capsule())
                    }
                }
            }

            Spacer()
            Spacer()
        }
        .padding(.horizontal, AppSpacing.lg)
    }

    // MARK: - Theme Card
    private func themeCard(_ theme: OnboardingTheme) -> some View {
        let isSelected = selectedThemes.contains(theme)
        return Button {
            withAnimation(.easeInOut(duration: 0.2)) {
                if isSelected {
                    selectedThemes.remove(theme)
                } else {
                    selectedThemes.insert(theme)
                }
            }
        } label: {
            VStack(spacing: AppSpacing.sm) {
                Text(theme.icon)
                    .font(.system(size: 28))
                Text(theme.rawValue)
                    .font(AppFont.label(14))
                    .foregroundStyle(isSelected ? .white : .appTextPrimary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, AppSpacing.lg)
            .background(isSelected ? Color.appPrimary : Color.appCardBackground)
            .clipShape(RoundedRectangle(cornerRadius: AppRadius.lg))
            .overlay(
                RoundedRectangle(cornerRadius: AppRadius.lg)
                    .stroke(isSelected ? Color.appPrimary : Color.appDivider, lineWidth: 1.5)
            )
        }
    }
}
