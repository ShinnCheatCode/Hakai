import SwiftUI

struct GlassCardModifier: ViewModifier {
    var radius: CGFloat = 22

    func body(content: Content) -> some View {
        content
            .background(Color.primary.opacity(0.07), in: RoundedRectangle(cornerRadius: radius, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: radius, style: .continuous)
                    .strokeBorder(Color.primary.opacity(0.15), lineWidth: 1)
            )
    }
}

extension View {
    func shinnGlass(radius: CGFloat = 22) -> some View {
        modifier(GlassCardModifier(radius: radius))
    }
}

struct BackgroundView: View {
    var body: some View {
        ZStack {
            Color(.systemBackground)
            RadialGradient(
                colors: [Color.primary.opacity(0.09), .clear],
                center: .topTrailing,
                startRadius: 20,
                endRadius: 500
            )
            RadialGradient(
                colors: [Color.primary.opacity(0.05), .clear],
                center: .bottomLeading,
                startRadius: 20,
                endRadius: 450
            )
        }
        .ignoresSafeArea()
    }
}

struct IconBox: View {
    let systemName: String
    var size: CGFloat = 56

    var body: some View {
        Image(systemName: systemName)
            .font(.system(size: size * 0.42, weight: .semibold))
            .frame(width: size, height: size)
            .background(Color.primary.opacity(0.08), in: RoundedRectangle(cornerRadius: size * 0.3, style: .continuous))
    }
}

struct Pill: View {
    let text: String

    var body: some View {
        Text(text)
            .font(.caption.bold())
            .padding(.horizontal, 12)
            .padding(.vertical, 7)
            .background(Color.primary.opacity(0.1), in: Capsule())
    }
}


// ===== AppShimn source: Localization.swift =====
import SwiftUI

enum ShinnLanguage: String, CaseIterable, Identifiable {
    case vi
    case en

    var id: String {
        rawValue
    }

    var title: String {
        self == .vi ? "Tiếng Việt" : "English"
    }
}

enum ShinnTheme: String, CaseIterable, Identifiable {
    case system
    case light
    case dark

    var id: String {
        rawValue
    }

    var colorScheme: ColorScheme? {

        switch self {

        case .system:
            return nil

        case .light:
            return .light

        case .dark:
            return .dark
        }
    }

    var titleKey: K {

        switch self {

        case .system:
            return .themeSystem

        case .light:
            return .themeLight

        case .dark:
            return .themeDark
        }
    }
}

final class AppSettings: ObservableObject {

    @Published var theme: ShinnTheme {
        didSet {
            UserDefaults.standard.set(
                theme.rawValue,
                forKey: "theme"
            )
        }
    }

    @Published var language: ShinnLanguage {
        didSet {
            UserDefaults.standard.set(
                language.rawValue,
                forKey: "language"
            )
        }
    }

    @Published var autoRefresh: Bool {
        didSet {
            UserDefaults.standard.set(
                autoRefresh,
                forKey: "autoRefresh"
            )
        }
    }

    init() {

        let defaults =
            UserDefaults.standard

        theme =
            ShinnTheme(
                rawValue:
                    defaults.string(
                        forKey: "theme"
                    ) ?? ""
            )
            ?? .system

        if let raw =
            defaults.string(
                forKey: "language"
            ),
           let language =
            ShinnLanguage(rawValue: raw) {

            self.language = language

        } else {

            let first =
                Locale.preferredLanguages.first
                ?? "en"

            self.language =
                first.hasPrefix("vi")
                ? .vi
                : .en
        }

        autoRefresh =
            defaults.object(
                forKey: "autoRefresh"
            ) as? Bool ?? true
    }

    func t(_ key: K) -> String {

        let pair = key.text

        return language == .vi
            ? pair.vi
            : pair.en
    }

    func countText(_ n: Int) -> String {

        if language == .vi {
            return "\(n) gói"
        }

        return n == 1
            ? "1 package"
            : "\(n) packages"
    }
}

enum K {

    case heroFree
    case heroNote
    case categoriesTitle
        case allPackages
    case loadingText
    case loadFailed
    case retry

    case settingsTitle
    case settingsSub
    case aboutTitle
    case aboutSub

    case packagesTitle
    case packageCenter
    case packageCenterSub
    case searchPrompt
    case allLabel
    case notFound
    case notFoundDesc

    case versionLabel
    case authorLabel
    case categoryLabel
    case sizeLabel
    case descriptionLabel

    case downloadAction
    case downloading
    case downloaded
    case redownload
    case shareAction
    case savedHint
    case sha256OK

    case errHash
    case errHTTP
    case errURL

    case appearance
    case themeLabel
    case themeSystem
    case themeLight
    case themeDark
    case languageLabel

    case autoUpdate
    case repoSection
    case defaultSource
    case defaultBadge
    case repoLocked
    case refreshRepo
    case infoTitle

    case aboutDesc
    case madeBy
    case contactTitle
    case donateTitle
    case copy
    case copied

    case featRemote
    case featSHA

    case termsTitle
    case termsBody

    case supportTitle
    case telegramSub
    case reportTitle
    case reportSub
}

extension K {

    var text: (
        vi: String,
        en: String
    ) {

        switch self {

        case .heroFree:
            return (
                "LÀ APP VÀ REPO HOÀN TOÀN FREE",
                "A COMPLETELY FREE APP AND REPO"
            )

        case .heroNote:
            return (
                "Không bán key • Không khóa thiết bị",
                "No keys sold • No device lock"
            )

        case .categoriesTitle:
            return (
                "DANH MỤC GÓI",
                "PACKAGE CATEGORIES"
            )

        case .allPackages:
            return (
                "Tất cả gói",
                "All packages"
            )

        case .loadingText:
            return (
                "Đang tải repo…",
                "Loading repo…"
            )

        case .loadFailed:
            return (
                "Không tải được repo. Kiểm tra mạng và thử lại.",
                "Couldn't load the repo. Check your connection and try again."
            )

        case .retry:
            return (
                "Thử lại",
                "Retry"
            )

        case .settingsTitle:
            return (
                "Cài Đặt",
                "Settings"
            )

        case .settingsSub:
            return (
                "Tùy chỉnh app",
                "Customize the app"
            )

        case .aboutTitle:
            return (
                "Giới Thiệu",
                "About"
            )

        case .aboutSub:
            return (
                "Thông tin app",
                "App information"
            )

        case .packagesTitle:
            return (
                "Packages",
                "Packages"
            )

        case .packageCenter:
            return (
                "Package Center",
                "Package Center"
            )

        case .packageCenterSub:
            return (
                "Các package được cung cấp bởi Shinn Cheat",
                "Packages provided by Shinn Cheat"
            )

        case .searchPrompt:
            return (
                "Tìm package",
                "Search packages"
            )

        case .allLabel:
            return (
                "Tất cả",
                "All"
            )

        case .notFound:
            return (
                "Không tìm thấy",
                "No results"
            )

        case .notFoundDesc:
            return (
                "Không có package phù hợp với từ khóa.",
                "No packages match your search."
            )

        case .versionLabel:
            return (
                "Phiên bản",
                "Version"
            )

        case .authorLabel:
            return (
                "Tác giả",
                "Author"
            )

        case .categoryLabel:
            return (
                "Danh mục",
                "Category"
            )

        case .sizeLabel:
            return (
                "Dung lượng",
                "Size"
            )

        case .descriptionLabel:
            return (
                "Mô tả",
                "Description"
            )

        case .downloadAction:
            return (
                "Tải xuống",
                "Download"
            )

        case .downloading:
            return (
                "Đang tải…",
                "Downloading…"
            )

        case .downloaded:
            return (
                "Đã tải",
                "Downloaded"
            )

        case .redownload:
            return (
                "Tải lại",
                "Download again"
            )

        case .shareAction:
            return (
                "Chia sẻ",
                "Share"
            )

        case .savedHint:
            return (
                "Đã lưu vào Files",
                "Saved to Files"
            )

        case .sha256OK:
            return (
                "SHA-256 hợp lệ",
                "SHA-256 verified"
            )

        case .errHash:
            return (
                "SHA-256 không khớp.",
                "SHA-256 mismatch."
            )

        case .errHTTP:
            return (
                "Lỗi máy chủ.",
                "Server error."
            )

        case .errURL:
            return (
                "URL không hợp lệ.",
                "Invalid URL."
            )

        case .appearance:
            return (
                "Giao diện",
                "Appearance"
            )

        case .themeLabel:
            return (
                "Chủ đề",
                "Theme"
            )

        case .themeSystem:
            return (
                "Hệ thống",
                "System"
            )

        case .themeLight:
            return (
                "Sáng",
                "Light"
            )

        case .themeDark:
            return (
                "Tối",
                "Dark"
            )

        case .languageLabel:
            return (
                "Ngôn ngữ",
                "Language"
            )

        case .autoUpdate:
            return (
                "Tự động cập nhật repo",
                "Auto refresh repo"
            )

        case .repoSection:
            return (
                "Nguồn Repo",
                "Repository Source"
            )

        case .defaultSource:
            return (
                "Nguồn mặc định",
                "Default source"
            )

        case .defaultBadge:
            return (
                "Mặc định",
                "Default"
            )

        case .repoLocked:
            return (
                "Nguồn mặc định được khóa.",
                "The default source is locked."
            )

        case .refreshRepo:
            return (
                "Làm mới repo",
                "Refresh repo"
            )

        case .infoTitle:
            return (
                "Thông tin",
                "Information"
            )

        case .aboutDesc:
            return (
                "Ứng dụng quản lý và tải package từ repo từ xa.",
                "An app for managing and downloading packages from a remote repository."
            )

        case .madeBy:
            return (
                "Make By Nguyen Vu Minh Hieu",
                "Make By Nguyen Vu Minh Hieu"
            )

        case .contactTitle:
            return (
                "Liên hệ",
                "Contact"
            )

        case .donateTitle:
            return (
                "Ủng hộ",
                "Support"
            )

        case .copy:
            return (
                "Sao chép",
                "Copy"
            )

        case .copied:
            return (
                "Đã sao chép",
                "Copied"
            )

        case .featRemote:
            return (
                "Repo từ xa",
                "Remote repository"
            )

        case .featSHA:
            return (
                "Xác minh SHA-256",
                "SHA-256 verification"
            )

        case .termsTitle:
            return (
                "Điều khoản",
                "Terms"
            )

        case .termsBody:
            return (
                "Sử dụng ứng dụng có trách nhiệm và tuân thủ quy định của nền tảng.",
                "Use the app responsibly and follow platform rules."
            )

        case .supportTitle:
            return (
                "Hỗ trợ",
                "Support"
            )

        case .telegramSub:
            return (
                "Telegram: @ShinnThieuu",
                "Telegram: @ShinnThieuu"
            )

        case .reportTitle:
            return (
                "Báo lỗi",
                "Report a problem"
            )

        case .reportSub:
            return (
                "Liên hệ Telegram để được hỗ trợ.",
                "Contact Telegram for support."
            )
        }
    }
}
                "Download"
            )

        case .downloading:
            return (
                "Đang tải…",
                "Downloading…"
            )

        case .downloaded:
            return (
                "Đã tải xong",
                "Downloaded"
            )

        case .redownload:
            return (
                "Tải lại",
                "Download again"
            )

        case .shareAction:
            return (
                "Chia sẻ / Mở bằng app khác",
                "Share / Open in another app"
            )

        case .savedHint:
            return (
                "File được lưu trong Tệp › Trên iPhone › Shinn Cheat.",
                "Saved in Files › On My iPhone › Shinn Cheat."
            )

        case .sha256OK:
            return (
                "Đã xác minh SHA256",
                "SHA256 verified"
            )

        case .errHash:
            return (
                "File tải về không khớp SHA256 nên đã bị hủy.",
                "The downloaded file failed the SHA256 check and was discarded."
            )

        case .errHTTP:
            return (
                "Lỗi máy chủ",
                "Server error"
            )

        case .errURL:
            return (
                "Link tải không hợp lệ",
                "Invalid download link"
            )

        case .appearance:
            return (
                "Giao diện",
                "Appearance"
            )

        case .themeLabel:
            return (
                "Chủ đề",
                "Theme"
            )

        case .themeSystem:
            return (
                "Theo hệ thống",
                "System"
            )

        case .themeLight:
            return (
                "Sáng",
                "Light"
            )

        case .themeDark:
            return (
                "Tối",
                "Dark"
            )

        case .languageLabel:
            return (
                "Ngôn ngữ",
                "Language"
            )

        case .autoUpdate:
            return (
                "Tự động cập nhật repo",
                "Auto-refresh repo"
            )

        case .repoSection:
            return (
                "Nguồn repo",
                "Repository"
            )

        case .defaultSource:
            return (
                "Nguồn mặc định",
                "Default source"
            )

        case .defaultBadge:
            return (
                "MẶC ĐỊNH",
                "DEFAULT"
            )

        case .repoLocked:
            return (
                "Nguồn mặc định của app, không thể xóa hoặc thay thế.",
                "The app's built-in source. It can't be removed or replaced."
            )

        case .refreshRepo:
            return (
                "Làm mới repo",
                "Refresh repo"
            )

        case .infoTitle:
            return (
                "Thông tin",
                "Info"
            )

        case .aboutDesc:
            return (
                "Shinn Cheat là ứng dụng quản lý và phân phối các package được cấu hình thông qua repository của Shinn.",
                "Shinn Cheat is an app for managing and distributing packages configured through Shinn's repository."
            )

        case .madeBy:
            return (
                "App được make bởi Shinn",
                "App made by Shinn"
            )

        case .contactTitle:
            return (
                "Liên hệ",
                "Contact"
            )

        case .donateTitle:
            return (
                "Donate",
                "Donate"
            )

        case .copy:
            return (
                "Sao chép",
                "Copy"
            )

        case .copied:
            return (
                "Đã sao chép",
                "Copied"
            )

        case .featRemote:
            return (
                "Cập nhật dữ liệu từ repository",
                "Sync data from the repository"
            )

        case .featSHA:
            return (
                "Kiểm tra tính toàn vẹn của file",
                "Verify file integrity"
            )

        case .termsTitle:
            return (
                "Điều khoản sử dụng",
                "Terms of use"
            )

        case .termsBody:

            return (
                """
                Khi cài đặt và sử dụng ứng dụng này, bạn đã đồng ý với chính sách của chúng tôi.

                • Ứng dụng và repo hoàn toàn MIỄN PHÍ.
                • Không sử dụng ứng dụng vào bất kỳ hành vi nào trái với pháp luật.
                • Mọi hành vi phá hoại, cố ý vi phạm sẽ bị cảnh báo.
                """,

                """
                By installing and using this app, you agree to our policy.

                • The app and its repo are completely FREE.
                • Do not use the app for anything that violates the law.
                • Sabotage or deliberate violations will result in a warning.
                """
            )

        case .supportTitle:
            return (
                "Hỗ trợ",
                "Support"
            )

        case .telegramSub:
            return (
                "Liên hệ nhóm hỗ trợ",
                "Contact the support team"
            )
                            "Download"
            )

        case .downloading:
            return (
                "Đang tải…",
                "Downloading…"
            )

        case .downloaded:
            return (
                "Đã tải xong",
                "Downloaded"
            )

        case .redownload:
            return (
                "Tải lại",
                "Download again"
            )

        case .shareAction:
            return (
                "Chia sẻ / Mở bằng app khác",
                "Share / Open in another app"
            )

        case .savedHint:
            return (
                "File được lưu trong Tệp › Trên iPhone › Shinn Cheat.",
                "Saved in Files › On My iPhone › Shinn Cheat."
            )

        case .sha256OK:
            return (
                "Đã xác minh SHA256",
                "SHA256 verified"
            )

        case .errHash:
            return (
                "File tải về không khớp SHA256 nên đã bị hủy.",
                "The downloaded file failed the SHA256 check and was discarded."
            )

        case .errHTTP:
            return (
                "Lỗi máy chủ",
                "Server error"
            )

        case .errURL:
            return (
                "Link tải không hợp lệ",
                "Invalid download link"
            )

        case .appearance:
            return (
                "Giao diện",
                "Appearance"
            )

        case .themeLabel:
            return (
                "Chủ đề",
                "Theme"
            )

        case .themeSystem:
            return (
                "Theo hệ thống",
                "System"
            )

        case .themeLight:
            return (
                "Sáng",
                "Light"
            )

        case .themeDark:
            return (
                "Tối",
                "Dark"
            )

        case .languageLabel:
            return (
                "Ngôn ngữ",
                "Language"
            )

        case .autoUpdate:
            return (
                "Tự động cập nhật repo",
                "Auto-refresh repo"
            )

        case .repoSection:
            return (
                "Nguồn repo",
                "Repository"
            )

        case .defaultSource:
            return (
                "Nguồn mặc định",
                "Default source"
            )

        case .defaultBadge:
            return (
                "MẶC ĐỊNH",
                "DEFAULT"
            )

        case .repoLocked:
            return (
                "Nguồn mặc định của app, không thể xóa hoặc thay thế.",
                "The app's built-in source. It can't be removed or replaced."
            )

        case .refreshRepo:
            return (
                "Làm mới repo",
                "Refresh repo"
            )

        case .infoTitle:
            return (
                "Thông tin",
                "Info"
            )

        case .aboutDesc:
            return (
                "Shinn Cheat là ứng dụng quản lý và phân phối các package được cấu hình thông qua repository của Shinn.",
                "Shinn Cheat is an app for managing and distributing packages configured through Shinn's repository."
            )

        case .madeBy:
            return (
                "App được make bởi Shinn",
                "App made by Shinn"
            )

        case .contactTitle:
            return (
                "Liên hệ",
                "Contact"
            )

        case .donateTitle:
            return (
                "Donate",
                "Donate"
            )

        case .copy:
            return (
                "Sao chép",
                "Copy"
            )

        case .copied:
            return (
                "Đã sao chép",
                "Copied"
            )

        case .featRemote:
            return (
                "Cập nhật dữ liệu từ repository",
                "Sync data from the repository"
            )

        case .featSHA:
            return (
                "Kiểm tra tính toàn vẹn của file",
                "Verify file integrity"
            )

        case .termsTitle:
            return (
                "Điều khoản sử dụng",
                "Terms of use"
            )

        case .termsBody:

            return (
                """
                Khi cài đặt và sử dụng ứng dụng này, bạn đã đồng ý với chính sách của chúng tôi.

                • Ứng dụng và repo hoàn toàn MIỄN PHÍ.
                • Không sử dụng ứng dụng vào bất kỳ hành vi nào trái với pháp luật.
                • Mọi hành vi phá hoại, cố ý vi phạm sẽ bị cảnh báo.
                """,

                """
                By installing and using this app, you agree to our policy.

                • The app and its repo are completely FREE.
                • Do not use the app for anything that violates the law.
                • Sabotage or deliberate violations will result in a warning.
                """
            )

        case .supportTitle:
            return (
                "Hỗ trợ",
                "Support"
            )

        case .telegramSub:
            return (
                "Liên hệ nhóm hỗ trợ",
                "Contact the support team"
            )
    