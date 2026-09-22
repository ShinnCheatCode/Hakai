import SwiftUI

struct OnboardingView: View {
    @EnvironmentObject private var settings: AppSettings
    @Environment(\.appLanguage) private var language

    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false
    @State private var step = 0

    private let totalSteps = 4

    var body: some View {
        VStack(spacing: 0) {
            Text(language.text("onboarding.step", "\(step + 1)", "\(totalSteps)"))
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .padding(.top, 16)

            TabView(selection: $step) {
                languageStep.tag(0)
                welcomeStep.tag(1)
                versionsStep.tag(2)
                installStep.tag(3)
            }
            .tabViewStyle(.page(indexDisplayMode: .never))

            HStack {
                if step > 0 {
                    Button(language.text("common.back")) {
                        withAnimation { step -= 1 }
                    }
                }

                Spacer()

                Button(step == totalSteps - 1
                       ? language.text("common.finish")
                       : language.text("common.next")) {
                    if step == totalSteps - 1 {
                        hasCompletedOnboarding = true
                    } else {
                        withAnimation { step += 1 }
                    }
                }
                .buttonStyle(.borderedProminent)
            }
            .padding(20)
        }
    }

    private var languageStep: some View {
        VStack(spacing: 16) {
            Text(language.text("onboarding.language_title"))
                .font(.title2.bold())
            Text(language.text("onboarding.language_subtitle"))
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)

            ForEach(AppLanguage.allCases) { item in
                Button {
                    UserDefaults.standard.set(item.rawValue, forKey: AppLanguage.storageKey)
                } label: {
                    HStack {
                        Text(item.displayName)
                        Spacer()
                        if item == language {
                            Image(systemName: "checkmark")
                        }
                    }
                    .padding()
                }
            }

            Text(language.text("onboarding.language_hint"))
                .font(.footnote)
                .foregroundStyle(.secondary)
        }
        .padding(24)
    }

    private var welcomeStep: some View {
        VStack(spacing: 12) {
            Text(language.text("onboarding.welcome_title"))
                .font(.title.bold())
            Text(language.text("onboarding.welcome_message"))
                .foregroundStyle(.secondary)
            Text(language.text("onboarding.welcome_badge"))
                .font(.caption.bold())
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(.thinMaterial, in: Capsule())
        }
        .padding(24)
    }

    private var versionsStep: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(language.text("onboarding.versions_title"))
                .font(.title2.bold())
            Text(language.text("onboarding.versions_subtitle"))
                .foregroundStyle(.secondary)

            versionRow("iOS \(ExploitSupportPolicy.verifiedIOS17Range)")
            versionRow("iOS \(ExploitSupportPolicy.verifiedIOS18Range)")
            versionRow("iOS \(ExploitSupportPolicy.verifiedIOS26Range)")
            versionRow("iOS 27.0 Developer Beta 1–4 / Public Beta 1–2")

            Text(language.text(
                "onboarding.versions_footer",
                AppInfo.osVersion,
                AppInfo.osBuild
            ))
            .font(.footnote)
            .foregroundStyle(.secondary)
            .padding(.top, 8)
        }
        .padding(24)
    }

    private var installStep: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(language.text("onboarding.install_title"))
                .font(.title2.bold())
            Text(language.text("onboarding.install_message"))
                .foregroundStyle(.secondary)
            labelRow("checkmark.circle.fill", language.text("onboarding.install_ok"))
            labelRow("xmark.circle.fill", language.text("onboarding.install_bad"))
            labelRow("exclamationmark.triangle.fill", language.text("onboarding.install_jailbreak"))
            Text(language.text("onboarding.install_footer"))
                .font(.footnote)
                .foregroundStyle(.secondary)
        }
        .padding(24)
    }

    private func versionRow(_ text: String) -> some View {
        Label(text, systemImage: "checkmark.seal")
    }

    private func labelRow(_ icon: String, _ text: String) -> some View {
        Label(text, systemImage: icon)
    }
}