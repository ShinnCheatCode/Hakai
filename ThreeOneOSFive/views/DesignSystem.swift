import SwiftUI

enum AppTheme {
    // MARK: - Accent

    static let accent = Color(
        uiColor: UIColor { traits in
            traits.userInterfaceStyle == .dark
                ? UIColor(
                    red: 1.00,
                    green: 0.23,
                    blue: 0.28,
                    alpha: 1.00
                )
                : UIColor(
                    red: 0.90,
                    green: 0.16,
                    blue: 0.20,
                    alpha: 1.00
                )
        }
    )

    // MARK: - Background

    /// Transparent so the app-wide liquid-glass wallpaper can show through.
    static let pageBackground = Color.clear

    static let consoleBackground =
        Color(uiColor: .secondarySystemBackground)

    // MARK: - Layout

    static let pageInset: CGFloat = 16

    // MARK: - Row Icons

    static let rowIconSize: CGFloat = 17
    static let rowIconFrame: CGFloat = 28

    static let fileRowIconSize: CGFloat = 17
    static let fileRowIconFrame: CGFloat = 30

    static let fileRowHeight: CGFloat = 60

    // MARK: - App Icons

    static let appIconSize: CGFloat = 32

    // MARK: - Empty State

    static let emptyIconSize: CGFloat = 30

    // MARK: - Selection

    static let selectionIconSize: CGFloat = 18
}

// MARK: - App Row Icon

struct AppRowIcon: View {
    let systemName: String

    var tint: Color = AppTheme.accent
    var symbolSize: CGFloat = AppTheme.rowIconSize
    var frameSize: CGFloat = AppTheme.rowIconFrame

    var body: some View {
        ZStack {
            RoundedRectangle(
                cornerRadius: 7,
                style: .continuous
            )
            .fill(tint.opacity(0.12))

            Image(systemName: systemName)
                .font(
                    .system(
                        size: symbolSize,
                        weight: .medium
                    )
                )
                .foregroundStyle(tint)
        }
        .frame(
            width: frameSize,
            height: frameSize
        )
        .accessibilityHidden(true)
    }
}

// MARK: - App Search Field

struct AppSearchField: View {
    @Binding var text: String

    let prompt: String
    let clearLabel: String

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: "magnifyingglass")
                .font(
                    .system(
                        size: 14,
                        weight: .medium
                    )
                )
                .foregroundStyle(.secondary)
                .accessibilityHidden(true)

            TextField(
                prompt,
                text: $text
            )
            .font(.body)
            .textInputAutocapitalization(.never)
            .autocorrectionDisabled()
            .submitLabel(.search)

            if !text.isEmpty {
                Button {
                    text = ""
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(
                            .system(
                                size: 14,
                                weight: .medium
                            )
                        )
                        .foregroundStyle(.tertiary)
                }
                .buttonStyle(.plain)
                .accessibilityLabel(clearLabel)
            }
        }
        .padding(.horizontal, 11)
        .frame(minHeight: 36)
        .background(
            Color(uiColor: .secondarySystemFill),
            in: RoundedRectangle(
                cornerRadius: 10,
                style: .continuous
            )
        )
        .padding(.horizontal, AppTheme.pageInset)
        .padding(.vertical, 8)
        .background(.bar)
    }
}

// MARK: - App Logo

struct AppLogo: View {
    var size: CGFloat = 44

    var body: some View {
        Group {
            if let icon =
                UIImage(named: "AppIcon60x60")
                ??
                Bundle.main
                    .path(
                        forResource: "AppIcon60x60@2x",
                        ofType: "png"
                    )
                    .flatMap(
                        UIImage.init(contentsOfFile:)
                    )
                ??
                UIImage(named: "AppIcon")
            {
                Image(uiImage: icon)
                    .resizable()
                    .scaledToFill()
            } else {
                Image(systemName: "slider.horizontal.3")
                    .font(
                        .title2
                        .weight(.semibold)
                    )
                    .foregroundStyle(.white)
                    .frame(
                        maxWidth: .infinity,
                        maxHeight: .infinity
                    )
                    .background(
                        AppTheme.accent
                    )
            }
        }
        .frame(
            width: size,
            height: size
        )
        .clipShape(
            RoundedRectangle(
                cornerRadius: size * 0.22,
                style: .continuous
            )
        )
        .accessibilityHidden(true)
    }
}


// MARK: - App-wide Liquid Glass Background

/// Full-screen background used by the whole app.
/// Replace `AppBackground.png` in Assets.xcassets/AppBackground.imageset
/// with any wallpaper you want; no Swift code changes are required.
struct AppBackgroundView: View {
    var body: some View {
        GeometryReader { proxy in
            ZStack {
                Color.clear

                if let image = UIImage(named: "AppBackground") {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFill()
                        .frame(
                            width: proxy.size.width,
                            height: proxy.size.height
                        )
                        .clipped()
                } else {
                    LinearGradient(
                        colors: [
                            AppTheme.accent.opacity(0.18),
                            Color.white.opacity(0.08),
                            AppTheme.accent.opacity(0.07)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                }

                // Subtle liquid highlights.
                Circle()
                    .fill(.white.opacity(0.035))
                    .frame(width: 220, height: 220)
                    .blur(radius: 45)
                    .offset(
                        x: proxy.size.width * 0.32,
                        y: -proxy.size.height * 0.18
                    )

                Circle()
                    .fill(AppTheme.accent.opacity(0.035))
                    .frame(width: 260, height: 260)
                    .blur(radius: 55)
                    .offset(
                        x: -proxy.size.width * 0.34,
                        y: proxy.size.height * 0.24
                    )

                LinearGradient(
                    colors: [
                        Color.white.opacity(0.018),
                        .clear,
                        Color.black.opacity(0.025)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
            }
            .ignoresSafeArea()
        }
        .allowsHitTesting(false)
    }
}

// MARK: - Liquid Glass Card

struct LiquidGlassCard<S: Shape>: View {
    let shape: S
    var tint: Color = .white

    var body: some View {
        shape
            .fill(.ultraThinMaterial)
            .overlay {
                shape
                    .fill(
                        LinearGradient(
                            colors: [
                                Color.white.opacity(0.16),
                                tint.opacity(0.035),
                                Color.white.opacity(0.025)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            }
            .overlay {
                shape
                    .stroke(
                        LinearGradient(
                            colors: [
                                Color.white.opacity(0.34),
                                Color.white.opacity(0.07),
                                tint.opacity(0.16)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 0.9
                    )
            }
            .shadow(
                color: .black.opacity(0.10),
                radius: 22,
                x: 0,
                y: 10
            )
    }
}