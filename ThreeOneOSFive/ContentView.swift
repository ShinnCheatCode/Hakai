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
                    case .reportTitle:
            return (
                "Báo lỗi",
                "Report a bug"
            )

        case .reportSub:
            return (
                "Thông báo lỗi hoặc sự cố",
                "Report a bug or issue"
            )
        }
    }
}

import Foundation

extension AppInfo {

    static let telegramHandle =
        "@ShinnThieuu"

    static let telegramURL =
        URL(
            string: "https://t.me/ShinnThieuu"
        )!

    static let bankName =
        "MB Bank"

    static let bankAccount =
        "104877777"

    static let defaultRepoName =
        "Shinn Cheat Share"

    static let defaultRepoURL =
        URL(
            string:
                "https://raw.githubusercontent.com/ShinnCheatCode/Mhieuu/main/shinn.json"
        )!

    static var version: String {
        Bundle.main.object(
            forInfoDictionaryKey:
                "CFBundleShortVersionString"
        ) as? String ?? "5.0"
    }
}

struct RepoSource: Codable, Identifiable, Hashable {
    let id: UUID
    let name: String
    let url: URL

    init(id: UUID = UUID(), name: String, url: URL) {
        self.id = id
        self.name = name
        self.url = url
    }
}

struct RepoManifest: Codable {

    let name: String?
    let description: String?
    let icon: String?

    let packages: [
        RepoPackage
    ]
}

struct RepoPackage:
    Codable,
    Identifiable,
    Hashable {

    let identifier: String
    let name: String

    let author: String?
    let version: String?

    let summary: String?
    let description: String?

    let category: String?
    let tags: [String]?

    let download: String

    let sha256: String?
    let size: Int?

    let icon: String?

    let patchPath: String?
    let openURL: String?

    var id: String {
        identifier
    }
}

struct CategoryInfo:
    Identifiable {

    let name: String
    let count: Int

    var id: String {
        name
    }
}

enum Route: Hashable {

    case packages(String?)
    case detail(String)
    case settings
    case about
    case support
}

func formatBytes(
    _ value: Int
) -> String {

    ByteCountFormatter.string(
        fromByteCount: Int64(value),
        countStyle: .file
    )
}

// ===== AppShimn source: RepoStore.swift =====
import Foundation
import CryptoKit
import UIKit

enum DLError: Error {
    case badURL
    case http(Int)
    case hashMismatch
    case other(String)
}

enum PatchError: Error {
    case invalidPath
    case sourceNotFound
    case backupFailed
    case applyFailed
    case restoreFailed
    case other(String)
}

enum DownloadState {
    case idle
    case downloading
    case done(URL)
    case failed(DLError)
}

enum LoadState {
    case idle
    case loading
    case loaded
    case failed
}

enum PatchState {
    case idle
    case applying
    case applied
    case restoring
    case restored
    case failed(String)
}

func sha256Hex(of url: URL) throws -> String {
    let data = try Data(
        contentsOf: url,
        options: .mappedIfSafe
    )

    return SHA256.hash(data: data)
        .map { String(format: "%02x", $0) }
        .joined()
}

@MainActor
final class RepoStore: ObservableObject {

    @Published private(set) var manifest: RepoManifest?
    @Published private(set) var loadState: LoadState = .idle
    @Published private(set) var downloads: [String: DownloadState] = [:]
    @Published private(set) var patchStates: [String: PatchState] = [:]

    private var didBootstrap = false

    @Published private(set) var additionalSources: [RepoSource] = []

    private var sourcesURL: URL {
        documentsURL.appendingPathComponent("repo_sources.json")
    }

    // MARK: - Locations

    private var documentsURL: URL {
        FileManager.default.urls(
            for: .documentDirectory,
            in: .userDomainMask
        )[0]
    }

    private var cacheURL: URL {
        let dir = FileManager.default.urls(
            for: .cachesDirectory,
            in: .userDomainMask
        )[0]
                )[0]

        return dir.appendingPathComponent("repo_default.json")
    }

    private var backupDirectory: URL {
        documentsURL.appendingPathComponent(
            ".ShinnBackups",
            isDirectory: true
        )
    }

    // MARK: - Package data

    var packages: [RepoPackage] {
        manifest?.packages ?? []
    }

    var categories: [CategoryInfo] {
        var order: [String] = []
        var counts: [String: Int] = [:]

        for p in packages {
            let category = p.category ?? "Other"

            if counts[category] == nil {
                order.append(category)
            }

            counts[category, default: 0] += 1
        }

        return order.map {
            CategoryInfo(
                name: $0,
                count: counts[$0] ?? 0
            )
        }
    }

    // MARK: - Bootstrap

    func bootstrap(autoRefresh: Bool) async {
        if didBootstrap {
            return
        }

        didBootstrap = true

        loadSources()
        loadCache()

        if manifest == nil || autoRefresh {
            await refresh()
        }
    }

    private func loadCache() {
        guard
            let data = try? Data(contentsOf: cacheURL),
            let decoded = try? JSONDecoder().decode(
                RepoManifest.self,
                from: data
            )
        else {
            return
        }

        manifest = decoded
        loadState = .loaded
    }

    // MARK: - Remote JSON

    func refresh() async {
        loadState = .loading

        let urls = [AppInfo.defaultRepoURL] + additionalSources.map(\.url)
        var manifests: [RepoManifest] = []

        await withTaskGroup(of: RepoManifest?.self) { group in
            for url in urls {
                group.addTask {
                    do {
                        var request = URLRequest(
                            url: url,
                            cachePolicy: .reloadIgnoringLocalCacheData,
                            timeoutInterval: 20
                        )
                        request.setValue(
                            "no-cache",
                            forHTTPHeaderField: "Cache-Control"
                        )

                        let (data, response) = try await URLSession.shared.data(for: request)
                        if let http = response as? HTTPURLResponse, !(200..<300).contains(http.statusCode) {
                            return nil
                        }
                        return try JSONDecoder().decode(RepoManifest.self, from: data)
                    } catch {
                        return nil
                    }
                }
            }

            for await result in group {
                if let result { manifests.append(result) }
            }
        }

        guard !manifests.isEmpty else {
            loadState = manifest == nil ? .failed : .loaded
            return
        }

        let first = manifests[0]
        if manifests.count == 1 {
            manifest = first
        } else {
            var seen = Set<String>()
            var packages: [RepoPackage] = []
            for item in manifests {
                for package in item.packages where seen.insert(package.identifier).inserted {
                    packages.append(package)
                }
            }
            manifest = RepoManifest(
                name: first.name,
                description: first.description,
                icon: first.icon,
                packages: packages
            )
        }

        if let manifest, let data = try? JSONEncoder().encode(manifest) {
            try? data.write(to: cacheURL, options: .atomic)
        }

        loadState = .loaded
    }

    // MARK: - Repository management

    func addSource(name: String, urlString: String) -> Bool {
        guard let url = URL(string: urlString.trimmingCharacters(in: .whitespacesAndNewlines)),
              let scheme = url.scheme?.lowercased(),
              scheme == "https",
              !urlString.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            return false
        }

        // The built-in source can never be duplicated, replaced or removed.
        guard url.absoluteString != AppInfo.defaultRepoURL.absoluteString else {
            return false
        }

        guard !additionalSources.contains(where: { $0.url.absoluteString == url.absoluteString }) else {
            return false
        }

        let cleanName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        additionalSources.append(
            RepoSource(
                name: cleanName.isEmpty ? url.host ?? "Repository" : cleanName,
                url: url
            )
        )
        saveSources()
        return true
    }

    func removeSource(id: UUID) {
        additionalSources.removeAll { $0.id == id }
        saveSources()
    }

    private func loadSources() {
        guard let data = try? Data(contentsOf: sourcesURL),
              let sources = try? JSONDecoder().decode([RepoSource].self, from: data) else {
            additionalSources = []
            return
        }

        additionalSources = sources.filter {
            $0.url.absoluteString != AppInfo.defaultRepoURL.absoluteString
        }
    }

    private func saveSources() {
        guard let data = try? JSONEncoder().encode(additionalSources) else { return }
        try? data.write(to: sourcesURL, options: .atomic)
    }

    // MARK: - Download

    private func destination(for pkg: RepoPackage) -> URL? {
        guard
            let url = URL(string: pkg.download)
        else {
            return nil
        }

        let directory = documentsURL

        return directory.appendingPathComponent(
            url.lastPathComponent
        )
    }

    func existingFile(for pkg: RepoPackage) -> URL? {
        guard let destination = destination(for: pkg) else {
            return nil
        }

        guard FileManager.default.fileExists(
            atPath: destination.path
        ) else {
            return nil
        }
                return destination
    }

    func state(for pkg: RepoPackage) -> DownloadState {
        if let state = downloads[pkg.id] {
            return state
        }

        if let file = existingFile(for: pkg) {
            return .done(file)
        }

        return .idle
    }

    func download(_ pkg: RepoPackage) async {

        guard
            let url = URL(string: pkg.download),
            let destination = destination(for: pkg)
        else {
            downloads[pkg.id] = .failed(.badURL)
            return
        }

        downloads[pkg.id] = .downloading

        do {
            let (temporaryURL, response) =
                try await URLSession.shared.download(
                    from: url
                )

            if let http = response as? HTTPURLResponse,
               !(200..<300).contains(http.statusCode) {

                throw DLError.http(http.statusCode)
            }

            if let expected = pkg.sha256?
                .trimmingCharacters(in: .whitespacesAndNewlines)
                .lowercased(),
               !expected.isEmpty {

                let actual = try await Task.detached(
                    priority: .utility
                ) {
                    try sha256Hex(of: temporaryURL)
                }.value

                if actual.lowercased() != expected {
                    try? FileManager.default.removeItem(
                        at: temporaryURL
                    )

                    throw DLError.hashMismatch
                }
            }

            // A repo package is a real Make-iPA .3105 package.
            // Validate its envelope before exposing it as downloadable.
            do {
                let packageData = try Data(contentsOf: temporaryURL, options: .mappedIfSafe)
                _ = try PatchPackageCodec.inspect(packageData)
            } catch let error as PatchPackageError {
                try? FileManager.default.removeItem(at: temporaryURL)
                throw DLError.other(
                    "Gói .3105 không hợp lệ: \(error.localizedDescription)"
                )
            } catch {
                try? FileManager.default.removeItem(at: temporaryURL)
                throw DLError.other(
                    "Gói .3105 không hợp lệ: \(error.localizedDescription)"
                )
            }

            if FileManager.default.fileExists(
                atPath: destination.path
            ) {
                try FileManager.default.removeItem(
                    at: destination
                )
            }

            try FileManager.default.moveItem(
                at: temporaryURL,
                to: destination
            )

            downloads[pkg.id] = .done(destination)

        } catch let error as DLError {

            downloads[pkg.id] = .failed(error)

        } catch {

            downloads[pkg.id] = .failed(
                .other(error.localizedDescription)
            )
        }
    }

    // MARK: - Patch

    private func safeDocumentsPath(
        _ relativePath: String
    ) -> URL? {

        let clean = relativePath
            .trimmingCharacters(
                in: CharacterSet(
                    charactersIn: "/"
                )
            )

        guard !clean.isEmpty else {
            return nil
        }

        if clean.contains("..") {
            return nil
        }

        let candidate = documentsURL
            .appendingPathComponent(
                clean,
                isDirectory: false
            )

        let base = documentsURL.standardizedFileURL.path
        let path = candidate.standardizedFileURL.path

        guard
            path == base ||
            path.hasPrefix(base + "/")
        else {
            return nil
        }

        return candidate
    }

    private func packageArchive(
        _ pkg: RepoPackage
    ) -> URL? {
        existingFile(for: pkg)
    }

    private func patchDestination(
        _ pkg: RepoPackage
    ) -> URL? {

        if let custom = pkg.patchPath,
           !custom.isEmpty {

            return safeDocumentsPath(custom)
        }

        return safeDocumentsPath(
            "Applied/\(pkg.identifier)"
        )
    }

    private func backupURL(
        for pkg: RepoPackage
    ) -> URL {

        backupDirectory.appendingPathComponent(
            "\(pkg.identifier).backup",
            isDirectory: false
        )
    }

    private func createBackupDirectory() throws {

        if !FileManager.default.fileExists(
            atPath: backupDirectory.path
        ) {

            try FileManager.default.createDirectory(
                at: backupDirectory,
                withIntermediateDirectories: true
            )
        }
    }

    private func backupCurrentTarget(
        _ target: URL,
        for pkg: RepoPackage
    ) throws {

        try createBackupDirectory()

        let backup = backupURL(for: pkg)

        if FileManager.default.fileExists(
            atPath: backup.path
        ) {
            try FileManager.default.removeItem(
                at: backup
            )
        }

        guard FileManager.default.fileExists(
            atPath: target.path
        ) else {
            return
        }

        try FileManager.default.copyItem(
            at: target,
            to: backup
        )
    }

    // MARK: - Make-iPA .3105 Patch

    private func decodedPatchProject(
        for pkg: RepoPackage
    ) -> URL?
        ) throws -> PatchProject {
        guard let archive = existingFile(for: pkg) else {
            throw PatchError.sourceNotFound
        }

        let data = try Data(
            contentsOf: archive,
            options: .mappedIfSafe
        )

        let summary = try PatchPackageCodec.inspect(data)

        guard !summary.isPasswordProtected else {
            throw PatchError.other(
                "Gói .3105 này được bảo vệ bằng mật khẩu và không thể tự động áp dụng từ repo."
            )
        }

        return try PatchPackageCodec.decode(
            data,
            password: nil
        ).project
    }

    func apply(_ pkg: RepoPackage) async {
        patchStates[pkg.id] = .applying

        do {
            // IMPORTANT: do not copy/unzip the downloaded file.
            // The downloaded file is the actual Make-iPA .3105 envelope.
            // Decode it and let the native transaction engine perform the patch.
            let project = try decodedPatchProject(for: pkg)
            _ = try DevicePatchService.apply(project: project)

            patchStates[pkg.id] = .applied
            openTargetApp(for: pkg)
        } catch {
            patchStates[pkg.id] = .failed(
                errorMessage(error)
            )
        }
    }

    func restore(_ pkg: RepoPackage) async {
        patchStates[pkg.id] = .restoring

        do {
            let project = try decodedPatchProject(for: pkg)
            guard let receipt = DevicePatchService.latestReceipt(
                projectID: project.id
            ) else {
                throw PatchError.restoreFailed
            }

            try DevicePatchService.restore(receipt: receipt)
            patchStates[pkg.id] = .restored
        } catch {
            patchStates[pkg.id] = .failed(
                errorMessage(error)
            )
        }
    }

    func patchState(
        for pkg: RepoPackage
    ) -> PatchState {

        patchStates[pkg.id] ?? .idle
    }

    func openTargetApp(for pkg: RepoPackage) {
        var schemes: [String] = []

        if let raw = pkg.openURL, !raw.isEmpty {
            schemes.append(raw)
        }

        switch (pkg.category ?? "").lowercased() {
        case "free fire":
            schemes += ["freefire://", "com.dts.freefireth://"]
        case "free fire max":
            schemes += ["freefiremax://", "com.dts.freefiremax://"]
        case "liên quân mobile", "lien quan":
            schemes += ["com.garena.game.kgvn://"]
        default:
            break
        }

        for raw in schemes {
            guard let url = URL(string: raw) else { continue }
            if UIApplication.shared.canOpenURL(url) {
                UIApplication.shared.open(url)
                return
            }
        }
    }

    private func unzip(
        _ zipURL: URL,
        to destination: URL
    ) throws {

        let fileManager = FileManager.default

        let temporaryDirectory =
            fileManager.temporaryDirectory
            .appendingPathComponent(
                UUID().uuidString,
                isDirectory: true
            )

        try fileManager.createDirectory(
            at: temporaryDirectory,
            withIntermediateDirectories: true
        )

        defer {
            try? fileManager.removeItem(
                at: temporaryDirectory
            )
        }

        #if targetEnvironment(simulator)
        let process = Process()
        process.executableURL = URL(
            fileURLWithPath: "/usr/bin/unzip"
        )

        process.arguments = [
            "-q",
            zipURL.path,
            "-d",
            temporaryDirectory.path
        ]

        let pipe = Pipe()
        process.standardOutput = pipe
        process.standardError = pipe

        try process.run()
        process.waitUntilExit()

        guard process.terminationStatus == 0 else {
            throw PatchError.applyFailed
        }

        let contents = try fileManager.contentsOfDirectory(
            at: temporaryDirectory,
            includingPropertiesForKeys: nil,
            options: [.skipsHiddenFiles]
        )

        if contents.count == 1,
           let first = contents.first,
           (try? first.resourceValues(
               forKeys: [.isDirectoryKey]
           ).isDirectory) == true {

            try fileManager.moveItem(
                at: first,
                to: destination
            )

        } else {

            try fileManager.moveItem(
                at: temporaryDirectory,
                to: destination
            )
        }
        #else
        try fileManager.copyItem(
            at: zipURL,
            to: destination
        )
        #endif
    }

    private func errorMessage(
        _ error: Error
    ) -> String {

        if let patchError = error as? PatchError {

            switch patchError {

            case .invalidPath:
                return "Đường dẫn patch không hợp lệ."

            case .sourceNotFound:
                return "Chưa tải patch."

            case .backupFailed:
                return "Không thể tạo sao lưu."

            case .applyFailed:
                return "Không thể áp dụng pactch."

            case .restoreFailed:
                return "Không tìm thấy sao lưu."

            case .other(let message):
                return message
            }
        }

        return error.localizedDescription
    }
}

// ===== AppShimn source: HomeView.swift =====
import SwiftUI
import UIKit

struct HomeView: View {
    @EnvironmentObject var settings: AppSettings
    @EnvironmentObject var store: RepoStore
    @EnvironmentObject var session: Session
    let open: (Route) -> Void
        @EnvironmentObject var settings: AppSettings
    @EnvironmentObject var store: RepoStore

    @State private var searchText = ""
    @State private var category: String?

    let open: (Route) -> Void

    private var filtered: [RepoPackage] {
        store.packages.filter { package in
            let categoryMatch =
                category == nil ||
                package.category == category

            let searchMatch =
                searchText.isEmpty ||
                package.name.localizedCaseInsensitiveContains(searchText) ||
                package.identifier.localizedCaseInsensitiveContains(searchText) ||
                (package.description ?? "")
                    .localizedCaseInsensitiveContains(searchText)

            return categoryMatch && searchMatch
        }
    }

    var body: some View {
        ZStack {
            BackgroundView()

            ScrollView(showsIndicators: false) {
                LazyVStack(spacing: 12) {
                    header
                    categoryPicker

                    if filtered.isEmpty {
                        emptyState
                    } else {
                        ForEach(filtered) { package in
                            PackageRow(package: package) {
                                open(.detail(package.id))
                            }
                        }
                    }
                }
                .padding(.horizontal, 18)
                .padding(.top, 12)
                .padding(.bottom, 30)
            }
        }
        .searchable(
            text: $searchText,
            prompt: settings.t(.searchPrompt)
        )
        .navigationTitle(settings.t(.packagesTitle))
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            category = category
        }
    }

    private var header: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(settings.t(.packageCenter))
                    .font(
                        .system(
                            size: 28,
                            weight: .black,
                            design: .rounded
                        )
                    )

                Text(settings.t(.packageCenterSub))
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            Spacer()
        }
    }

    private var categoryPicker: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                categoryChip(
                    title: settings.t(.allLabel),
                    value: nil
                )

                ForEach(store.categories) { item in
                    categoryChip(
                        title: item.name,
                        value: item.name
                    )
                }
            }
            .padding(.vertical, 2)
        }
    }

    private func categoryChip(
        title: String,
        value: String?
    ) -> some View {
        Button {
            category = value
        } label: {
            Text(title)
                .font(.caption.bold())
                .padding(.horizontal, 13)
                .padding(.vertical, 8)
                .background(
                    (category == value
                     ? Color.primary.opacity(0.16)
                     : Color.primary.opacity(0.07)),
                    in: Capsule()
                )
                .overlay(
                    Capsule()
                        .strokeBorder(
                            Color.primary.opacity(
                                category == value ? 0.22 : 0.1
                            ),
                            lineWidth: 1
                        )
                )
        }
        .buttonStyle(.plain)
    }

    private var emptyState: some View {
        VStack(spacing: 10) {
            Image(systemName: "shippingbox")
                .font(.system(size: 34))

            Text(settings.t(.notFound))
                .font(.headline.bold())

            Text(settings.t(.notFoundDesc))
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(28)
        .shinnGlass()
    }
}

struct PackageRow: View {
    @EnvironmentObject var settings: AppSettings

    let package: RepoPackage
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 14) {
                PackageIcon(package: package)

                VStack(alignment: .leading, spacing: 5) {
                    Text(package.name)
                        .font(
                            .system(
                                size: 17,
                                weight: .bold,
                                design: .rounded
                            )
                        )
                        .lineLimit(1)

                    HStack(spacing: 8) {
                        if let version = package.version,
                           !version.isEmpty {
                            Pill(text: "v\(version)")
                        }

                        if let category = package.category,
                           !category.isEmpty {
                            Text(category)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }

                    if let description = package.description,
                       !description.isEmpty {
                        Text(description)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .lineLimit(2)
                    }
                }

                Spacer(minLength: 0)

                Image(systemName: "chevron.right")
                    .font(.footnote.bold())
                    .frame(width: 34, height: 34)
                    .background(
                        Color.primary.opacity(0.08),
                        in: Circle()
                    )
            }
            .padding(12)
            .contentShape(Rectangle())
            .shinnGlass()
        }
        .buttonStyle(.plain)
    }
}

struct PackageIcon: View {
    let package: RepoPackage

    var body: some View {
        Group {
            if let raw = package.icon,
               let url = URL(string: raw) {

                AsyncImage(url: url) { phase in
                    switch phase {
                    case .success(let image):
                        image
                            .resizable()
                            .scaledToFill()

                    default:
                        fallback
                    }
                }

            } else {
                fallback
            }
        }
        .frame(width: 58, height: 58)
        .background(Color.primary.opacity(0.08))
        .clipShape(
            RoundedRectangle(
                cornerRadius: 17,
                style: .continuous
            )
        )
        .overlay(
            RoundedRectangle(
                cornerRadius: 17,
                style: .continuous
            )
            .strokeBorder(
                Color.primary.opacity(0.12),
                lineWidth: 1
            )
        )
    }

    private var fallback: some View {
        Image(
            systemName:
                categoryIcon(package.category ?? "")
        )
        .font(.title2)
    }
}
                }
                .buttonStyle(.bordered)
            } else {
                ProgressView()
                Text(settings.t(.loadingText))
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(24)
        .shinnGlass()
    }

    private var quickActions: some View {
        HStack(spacing: 12) {
            QuickAction(title: settings.t(.settingsTitle), subtitle: settings.t(.settingsSub), icon: "gearshape.fill") {
                open(.settings)
            }
            QuickAction(title: settings.t(.aboutTitle), subtitle: settings.t(.aboutSub), icon: "info.circle.fill") {
                open(.about)
            }
        }
    }

    private var credit: some View {
        HStack {
            Image(systemName: "cube.fill")
                .font(.title2)
            VStack(alignment: .leading) {
                Text("SHINN CHEAT").font(.headline.bold())
                Text("FREE FIRE • FREE FIRE MAX")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            Text("Play Smart\nStay Ahead")
                .font(.system(size: 11, weight: .semibold, design: .serif))
                .italic()
                .multilineTextAlignment(.trailing)
        }
        .padding(18)
        .shinnGlass()
    }
}

struct CategoryCard: View {
    @EnvironmentObject var settings: AppSettings
    let icon: String
    let title: String
    let count: Int
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 14) {
                IconBox(systemName: icon, size: 56)

                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.system(size: 18, weight: .bold, design: .rounded))
                        .lineLimit(1)
                    Text(settings.countText(count))
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                Spacer(minLength: 0)

                Image(systemName: "chevron.right")
                    .font(.footnote.bold())
                    .frame(width: 34, height: 34)
                    .background(Color.primary.opacity(0.08), in: Circle())
            }
            .padding(12)
            .contentShape(Rectangle())
            .shinnGlass()
        }
        .buttonStyle(.plain)
    }
}

struct QuickAction: View {
    let title: String
    let subtitle: String
    let icon: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 12) {
                Image(systemName: icon).font(.title2)
                Text(title).font(.headline.bold())
                Text(subtitle).font(.caption).foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(18)
            .contentShape(Rectangle())
            .shinnGlass()
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Logo mèo (dùng khi chưa có ảnh banner)

struct CatLogo: View {
    var size: CGFloat = 84

    private static let remoteURL = URL(string: "https://raw.githubusercontent.com/mhieuushinn-dev/ShinnCheatShare/main/IMG_0508.jpeg")

    private var bundled: UIImage? {
        guard let path = Bundle.main.path(forResource: "CatLogo", ofType: "jpg") else { return nil }
        return UIImage(contentsOfFile: path)
    }

    var body: some View {
        content
            .frame(width: size, height: size)
            .background(Color.primary.opacity(0.08))
            .clipShape(Circle())
            .overlay(Circle().strokeBorder(Color.primary.opacity(0.25), lineWidth: 1.5))
    }

    @ViewBuilder
    private var content: some View {
        if let ui = bundled {
            Image(uiImage: ui)
                .resizable()
                .scaledToFill()
        } else {
            AsyncImage(url: CatLogo.remoteURL) { phase in
                switch phase {
                case .success(let image):
                    image.resizable().scaledToFill()
                default:
                    Image(systemName: "crown.fill")
                        .font(.system(size: size * 0.4))
                }
            }
        }
    }
}

// MARK: - Banner

enum HeroBanner {
    static let image: UIImage? = {
        let names: [(String, String)] = [
            ("IMG_1253", "jpeg"),
            ("IMG_1253", "jpg"),
            ("IMG_1253", "JPG"),
            ("IMG_1253", "JPEG"),
            ("HeroBanner", "jpg")
        ]
        for (name, ext) in names {
            if let path = Bundle.main.path(forResource: name, ofType: ext),
               let img = UIImage(contentsOfFile: path) {
                return img
            }
        }
        return nil
    }()
}


// ===== AppShimn source: PackageViews.swift =====
import SwiftUI
import UIKit

func categoryIcon(_ name: String) -> String {
    switch name {
    case "AIM":
        return "scope"

    case "ESP":
        return "eye.fill"

    case "Free Fire":
        return "flame.fill"

    case "Free Fire Max":
        return "sparkles"

    case "MOD SKIN":
        return "paintbrush.fill"

    case "Liên Quân Mobile":
        return "gamecontroller.fill"

    default:
        return "shippingbox.fill"
    }
}

// MARK: - Packages list

struct PackagesView: View {

    @EnvironmentObject var settings: AppSettings
    @EnvironmentObject var store: RepoStore

    @State private var searchText = ""
    @State private var category: String?

    init(initialCategory: String?) {
        _category = State(initialValue: initialCategory)
    }

    private func matches(
        _ package: RepoPackage,
        _ query: String
    ) -> Bool {

        if package.name.localizedCaseInsensitiveContains(query) {
            return true
        }

        if (package.summary ?? "")
            .localizedCaseInsensitiveContains(query) {
            return true
        }
                    return true
        }

        return (package.tags ?? [])
            .contains {
                $0.localizedCaseInsensitiveContains(query)
            }
    }

    private var filtered: [RepoPackage] {

        var result = store.packages

        if let category {
            result = result.filter {
                $0.category == category
            }
        }

        let query = searchText
            .trimmingCharacters(
                in: .whitespacesAndNewlines
            )

        if !query.isEmpty {
            result = result.filter {
                matches($0, query)
            }
        }

        return result
    }

    var body: some View {

        ScrollView {

            LazyVStack(spacing: 12) {

                VStack(
                    alignment: .leading,
                    spacing: 4
                ) {

                    Text(settings.t(.packageCenter))
                        .font(
                            .system(
                                size: 28,
                                weight: .bold,
                                design: .rounded
                            )
                        )

                    Text(settings.t(.packageCenterSub))
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .frame(
                    maxWidth: .infinity,
                    alignment: .leading
                )

                chips

                if store.packages.isEmpty {

                    ProgressView()
                        .padding(.top, 40)

                } else if filtered.isEmpty {

                    VStack(spacing: 10) {
                        Image(systemName: "magnifyingglass")
                            .font(.system(size: 28, weight: .medium))
                            .foregroundColor(.secondary)

                        Text(settings.t(.notFound))
                            .font(.headline)

                        Text(settings.t(.notFoundDesc))
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.top, 30)

                } else {

                    ForEach(filtered) { package in

                        NavigationLink(
                            value: Route.detail(
                                package.id
                            )
                        ) {
                            PackageRow(pkg: package)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            .padding(.horizontal, 18)
            .padding(.vertical, 12)
        }
        .background(BackgroundView())
        .navigationTitle(settings.t(.packagesTitle))
        .navigationBarTitleDisplayMode(.inline)
        .searchable(
            text: $searchText,
            prompt: settings.t(.searchPrompt)
        )
        .refreshable {
            await store.refresh()
        }
    }

    private var chips: some View {

        ScrollView(
            .horizontal,
            showsIndicators: false
        ) {

            HStack(spacing: 8) {

                chip(
                    settings.t(.allLabel),
                    selected: category == nil
                ) {
                    category = nil
                }

                ForEach(store.categories) { category in

                    chip(
                        category.name,
                        selected: self.category == category.name
                    ) {
                        self.category = category.name
                    }
                }
            }
        }
    }

    private func chip(
        _ title: String,
        selected: Bool,
        action: @escaping () -> Void
    ) -> some View {

        Button(action: action) {

            Text(title)
                .font(.subheadline.weight(.semibold))
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .background(
                    selected
                    ? Color.primary
                    : Color.primary.opacity(0.08),
                    in: Capsule()
                )
                .foregroundStyle(
                    selected
                    ? Color(.systemBackground)
                    : Color.primary
                )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Row

struct PackageRow: View {

    let pkg: RepoPackage

    private func tag(
        _ text: String
    ) -> some View {

        Text(text)
            .font(.caption2.weight(.medium))
            .padding(.horizontal, 7)
            .padding(.vertical, 3)
            .background(
                Color.primary.opacity(0.08),
                in: Capsule()
            )
    }

    var body: some View {

        HStack(spacing: 14) {

            IconBox(
                systemName: categoryIcon(
                    pkg.category ?? ""
                ),
                size: 50
            )

            VStack(
                alignment: .leading,
                spacing: 4
            ) {

                Text(pkg.name)
                    .font(
                        .system(
                            size: 16,
                            weight: .semibold,
                            design: .rounded
                        )
                    )
                    .lineLimit(1)
                                    Text(pkg.summary ?? "")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)

                HStack(spacing: 6) {

                    if let version = pkg.version {
                        tag("v\(version)")
                    }

                    if let size = pkg.size {
                        tag(formatBytes(size))
                    }
                }
            }

            Spacer(minLength: 0)

            Image(systemName: "chevron.right")
                .font(.footnote.bold())
                .foregroundStyle(.secondary)
        }
        .padding(12)
        .contentShape(Rectangle())
        .shinnGlass(radius: 20)
    }
}

// MARK: - Detail

struct PackageDetailView: View {

    @EnvironmentObject var settings: AppSettings
    @EnvironmentObject var store: RepoStore

    let packageID: String

    private var pkg: RepoPackage? {
        store.packages.first {
            $0.id == packageID
        }
    }

    var body: some View {

        ZStack {

            BackgroundView()

            if let pkg {
                content(pkg)
            } else {
                ProgressView()
            }
        }
        .navigationTitle(pkg?.name ?? "")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func content(
        _ pkg: RepoPackage
    ) -> some View {

        ScrollView {

            VStack(spacing: 16) {

                remoteIcon(pkg)

                VStack(spacing: 4) {

                    Text(pkg.name)
                        .font(
                            .system(
                                size: 26,
                                weight: .bold,
                                design: .rounded
                            )
                        )

                    if let summary = pkg.summary {
                        Text(summary)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                }

                VStack(spacing: 0) {

                    infoRow(
                        settings.t(.versionLabel),
                        pkg.version ?? "-"
                    )

                    infoRow(
                        settings.t(.authorLabel),
                        pkg.author ?? "-"
                    )

                    infoRow(
                        settings.t(.categoryLabel),
                        pkg.category ?? "-"
                    )

                    infoRow(
                        settings.t(.sizeLabel),
                        pkg.size.map {
                            formatBytes($0)
                        } ?? "-"
                    )
                }
                .padding(.horizontal, 16)
                .shinnGlass()

                downloadSection(pkg)

                if let description = pkg.description,
                   !description.isEmpty {

                    VStack(
                        alignment: .leading,
                        spacing: 8
                    ) {

                        Text(
                            settings.t(
                                .descriptionLabel
                            )
                        )
                        .font(.headline)

                        Text(description)
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }
                    .frame(
                        maxWidth: .infinity,
                        alignment: .leading
                    )
                    .padding(16)
                    .shinnGlass()
                }
            }
            .padding(.horizontal, 18)
            .padding(.vertical, 16)
        }
    }

    @ViewBuilder
    private func remoteIcon(
        _ pkg: RepoPackage
    ) -> some View {

        if let string = pkg.icon,
           let url = URL(string: string) {

            AsyncImage(url: url) { phase in

                switch phase {

                case .success(let image):

                    image
                        .resizable()
                        .scaledToFill()

                default:

                    Image(
                        systemName: categoryIcon(
                            pkg.category ?? ""
                        )
                    )
                    .font(
                        .system(
                            size: 38,
                            weight: .semibold
                        )
                    )
                }
            }
            .frame(
                width: 96,
                height: 96
            )
            .background(
                Color.primary.opacity(0.08)
            )
            .clipShape(
                RoundedRectangle(
                    cornerRadius: 26,
                    style: .continuous
                )
            )

        } else {

            IconBox(
                systemName: categoryIcon(
                    pkg.category ?? ""
                ),
                size: 96
            )
        }
    }

    private func infoRow(
        _ label: String,
        _ value: String
    ) -> some View {

        HStack {

            Text(label)
                .foregroundStyle(.secondary)

            Spacer()

            Text(value)
                            .fontWeight(.medium)
        }
        .font(.subheadline)
        .padding(.vertical, 13)
    }

    private func mainButton(
        _ title: String,
        icon: String,
        action: @escaping () -> Void
    ) -> some View {

        Button(action: action) {

            Label(
                title,
                systemImage: icon
            )
            .font(
                .system(
                    size: 16,
                    weight: .bold,
                    design: .rounded
                )
            )
            .frame(maxWidth: .infinity)
            .padding(.vertical, 15)
            .background(
                Color.primary,
                in: RoundedRectangle(
                    cornerRadius: 16,
                    style: .continuous
                )
            )
            .foregroundStyle(
                Color(.systemBackground)
            )
        }
        .buttonStyle(.plain)
    }

    private func message(
        _ error: DLError
    ) -> String {

        switch error {

        case .badURL:
            return settings.t(.errURL)

        case .http(let code):
            return settings.t(.errHTTP)
                + " (\(code))"

        case .hashMismatch:
            return settings.t(.errHash)

        case .other(let message):
            return message
        }
    }

    // MARK: - Download / Apply / Restore

    @ViewBuilder
    private func downloadSection(
        _ pkg: RepoPackage
    ) -> some View {

        VStack(spacing: 12) {

            switch store.state(for: pkg) {

            case .idle:

                mainButton(
                    settings.t(.downloadAction),
                    icon: "arrow.down.circle.fill"
                ) {
                    Task {
                        await store.download(pkg)
                    }
                }

            case .downloading:

                HStack(spacing: 10) {

                    ProgressView()

                    Text(
                        settings.t(.downloading)
                    )
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 15)
                .shinnGlass(radius: 16)

            case .done(let url):

                Label(
                    settings.t(.downloaded),
                    systemImage: "checkmark.circle.fill"
                )
                .font(.headline)

                if let hash = pkg.sha256,
                   !hash.isEmpty {

                    Label(
                        settings.t(.sha256OK),
                        systemImage: "checkmark.shield.fill"
                    )
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                }

                // MARK: Apply

                mainButton(
                    "Áp dụng",
                    icon: "checkmark.circle.fill"
                ) {
                    Task {
                        await store.apply(pkg)
                    }
                }

                // MARK: Restore

                mainButton(
                    "Khôi phục",
                    icon: "arrow.uturn.backward.circle.fill"
                ) {
                    Task {
                        await store.restore(pkg)
                    }
                }

                if let openURL = pkg.openURL,
                   !openURL.isEmpty {

                    Text(
                        "Sau khi áp dụng sẽ mở ứng dụng đích."
                    )
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                }

                ShareLink(item: url) {

                    Label(
                        settings.t(.shareAction),
                        systemImage: "square.and.arrow.up"
                    )
                    .font(
                        .system(
                            size: 16,
                            weight: .bold,
                            design: .rounded
                        )
                    )
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 15)
                    .background(
                        Color.primary,
                        in: RoundedRectangle(
                            cornerRadius: 16,
                            style: .continuous
                        )
                    )
                    .foregroundStyle(
                        Color(.systemBackground)
                    )
                }

                Button(
                    settings.t(.redownload)
                ) {

                    Task {
                        await store.download(pkg)
                    }
                }
                .font(.subheadline)

                patchStatus(pkg)

            case .failed(let error):

                Text(message(error))
                    .font(.subheadline)
                    .foregroundStyle(.red)
                    .multilineTextAlignment(.center)

                mainButton(
                    settings.t(.retry),
                    icon: "arrow.clockwise"
                ) {
                    Task {
                        await store.download(pkg)
                    }
                }
            }
        }
    }

    @ViewBuilder
    private func patchStatus(
        _ pkg: RepoPackage
    ) -> some View {

        switch store.patchState(for: pkg) {

        case .idle:
            EmptyView()

        case .applying:
                    Label(
                "Đang áp dụng…",
                systemImage: "arrow.triangle.2.circlepath"
            )
            .foregroundStyle(.secondary)

        case .applied:

            Label(
                "Đã áp dụng",
                systemImage: "checkmark.circle.fill"
            )
            .foregroundStyle(.green)

        case .restoring:

            Label(
                "Đang khôi phục…",
                systemImage: "arrow.uturn.backward"
            )
            .foregroundStyle(.secondary)

        case .restored:

            Label(
                "Đã khôi phục",
                systemImage: "checkmark.circle.fill"
            )
            .foregroundStyle(.green)

        case .failed(let message):

            Text(message)
                .font(.caption)
                .foregroundStyle(.red)
                .multilineTextAlignment(.center)
        }
    }
}

// ===== AppShimn source: SecondaryViews.swift =====
import SwiftUI
import UIKit

// ===== Make-iPA compatibility models retained for existing browser views =====
struct LemonTargetApp: Identifiable, Hashable {
    let id: String
    let name: String
    let bundleID: String
    let iconAssetName: String
}

enum FFH4XFeatureCategory: String, CaseIterable, Identifiable, Hashable {
    case aim
    case chams
    case modSkin

    var id: String { rawValue }

    var title: String {
        switch self {
        case .aim: return "Aim"
        case .chams: return "Chams"
        case .modSkin: return "Mod Skin"
        }
    }

    var subtitle: String {
        switch self {
        case .aim: return "Hỗ trợ kéo tâm"
        case .chams: return "Định vị nhìn xuyên tường"
        case .modSkin: return "Mod skin"
        }
    }

    var icon: String {
        switch self {
        case .aim: return "scope"
        case .chams: return "eye.fill"
        case .modSkin: return "tshirt.fill"
        }
    }

    var tint: Color {
        switch self {
        case .aim: return .blue
        case .chams: return .purple
        case .modSkin: return .orange
        }
    }
}

struct ProjectAppIcon: View {
    let assetName: String
    let size: CGFloat

    var body: some View {
        Image(assetName)
            .resizable()
            .scaledToFill()
            .frame(width: size, height: size)
            .clipShape(RoundedRectangle(cornerRadius: size * 0.23, style: .continuous))
    }
}

struct InstalledAppIcon: View {
    let bundleID: String
    let size: CGFloat
    @State private var image: UIImage?

    var body: some View {
        Group {
            if let image {
                Image(uiImage: image).resizable().scaledToFill()
            } else {
                Image(systemName: "app.fill")
                    .font(.system(size: size * 0.38, weight: .semibold))
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .frame(width: size, height: size)
        .clipShape(RoundedRectangle(cornerRadius: size * 0.23, style: .continuous))
        .task(id: bundleID) {
            image = await Task.detached(priority: .userInitiated) {
                iconForBundleID(bundleID)
            }.value
        }
    }
}


// MARK: - AppShimn root
import SwiftUI
import CryptoKit

enum UserRole: String, CaseIterable, Identifiable {
    case owner, admin, member
    var id: String { rawValue }

    var title: String {
        switch self {
        case .owner: return "Owner"
        case .admin: return "Admin"
        case .member: return "Member"
        }
    }

    var icon: String {
        switch self {
        case .owner: return "crown.fill"
        case .admin: return "checkmark.shield.fill"
        case .member: return "person.fill"
        }
    }

    var needsPassword: Bool { self != .member }
}

final class Session: ObservableObject {
    @Published var role: UserRole?

    // SHA256 của mật khẩu Owner/Admin
    private static let passwordHash = "a43535812161a1aec35c04f0b6ea63bb4880d581f3d15df9ba7e68befe6b472e"

    func verify(_ input: String) -> Bool {
        let digest = SHA256.hash(data: Data(input.utf8))
        let hex = digest.map { String(format: "%02x", $0) }.joined()
        return hex == Session.passwordHash
    }
}

struct ContentView: View {
    @StateObject private var session = Session()
    @State private var path: [Route] = []

    var body: some View {
        Group {
            if session.role == nil {
                RoleGateView()
            } else {
                NavigationStack(path: $path) {
                    HomeView(open: { path.append($0) })
                        .navigationDestination(for: Route.self) { route in
                            switch route {
                            case .packages(let category):
                                PackagesView(initialCategory: category)
                            case .detail(let id):
                                PackageDetailView(packageID: id)
                            case .settings:
                                SettingsView()
                            case .about:
                                AboutView()
                            case .support:
                                SupportView()
                            }
                        }
                }
                .tint(.primary)
            }
        }
        .environmentObject(session)
        .animation(.easeInOut(duration: 0.25), value: session.role)
    }
}

// MARK: - Chọn vai trò

struct RoleGateView: View {
    @EnvironmentObject var settings: AppSettings
    @EnvironmentObject var session: Session
    @State private var pending: UserRole?
    @State private var password = ""
    @State private var attempts = 0
    @State private var closing = false
    @FocusState private var focused: Bool

    private var isVI: Bool { settings.language == .vi }

    var body: some View {
        ZStack {
                    Label(
                "Đang áp dụng…",
                systemImage: "arrow.triangle.2.circlepath"
            )
            .foregroundStyle(.secondary)

        case .applied:

            Label(
                "Đã áp dụng",
                systemImage: "checkmark.circle.fill"
            )
            .foregroundStyle(.green)

        case .restoring:

            Label(
                "Đang khôi phục…",
                systemImage: "arrow.uturn.backward"
            )
            .foregroundStyle(.secondary)

        case .restored:

            Label(
                "Đã khôi phục",
                systemImage: "checkmark.circle.fill"
            )
            .foregroundStyle(.green)

        case .failed(let message):

            Text(message)
                .font(.caption)
                .foregroundStyle(.red)
                .multilineTextAlignment(.center)
        }
    }
}

// ===== AppShimn source: SecondaryViews.swift =====
import SwiftUI
import UIKit

// ===== Make-iPA compatibility models retained for existing browser views =====
struct LemonTargetApp: Identifiable, Hashable {
    let id: String
    let name: String
    let bundleID: String
    let iconAssetName: String
}

enum FFH4XFeatureCategory: String, CaseIterable, Identifiable, Hashable {
    case aim
    case chams
    case modSkin

    var id: String { rawValue }

    var title: String {
        switch self {
        case .aim: return "Aim"
        case .chams: return "Chams"
        case .modSkin: return "Mod Skin"
        }
    }

    var subtitle: String {
        switch self {
        case .aim: return "Hỗ trợ kéo tâm"
        case .chams: return "Định vị nhìn xuyên tường"
        case .modSkin: return "Mod skin"
        }
    }

    var icon: String {
        switch self {
        case .aim: return "scope"
        case .chams: return "eye.fill"
        case .modSkin: return "tshirt.fill"
        }
    }

    var tint: Color {
        switch self {
        case .aim: return .blue
        case .chams: return .purple
        case .modSkin: return .orange
        }
    }
}

struct ProjectAppIcon: View {
    let assetName: String
    let size: CGFloat

    var body: some View {
        Image(assetName)
            .resizable()
            .scaledToFill()
            .frame(width: size, height: size)
            .clipShape(RoundedRectangle(cornerRadius: size * 0.23, style: .continuous))
    }
}

struct InstalledAppIcon: View {
    let bundleID: String
    let size: CGFloat
    @State private var image: UIImage?

    var body: some View {
        Group {
            if let image {
                Image(uiImage: image).resizable().scaledToFill()
            } else {
                Image(systemName: "app.fill")
                    .font(.system(size: size * 0.38, weight: .semibold))
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .frame(width: size, height: size)
        .clipShape(RoundedRectangle(cornerRadius: size * 0.23, style: .continuous))
        .task(id: bundleID) {
            image = await Task.detached(priority: .userInitiated) {
                iconForBundleID(bundleID)
            }.value
        }
    }
}


// MARK: - AppShimn root
import SwiftUI
import CryptoKit

enum UserRole: String, CaseIterable, Identifiable {
    case owner, admin, member
    var id: String { rawValue }

    var title: String {
        switch self {
        case .owner: return "Owner"
        case .admin: return "Admin"
        case .member: return "Member"
        }
    }

    var icon: String {
        switch self {
        case .owner: return "crown.fill"
        case .admin: return "checkmark.shield.fill"
        case .member: return "person.fill"
        }
    }

    var needsPassword: Bool { self != .member }
}

final class Session: ObservableObject {
    @Published var role: UserRole?

    // SHA256 của mật khẩu Owner/Admin
    private static let passwordHash = "a43535812161a1aec35c04f0b6ea63bb4880d581f3d15df9ba7e68befe6b472e"

    func verify(_ input: String) -> Bool {
        let digest = SHA256.hash(data: Data(input.utf8))
        let hex = digest.map { String(format: "%02x", $0) }.joined()
        return hex == Session.passwordHash
    }
}

struct ContentView: View {
    @StateObject private var session = Session()
    @State private var path: [Route] = []

    var body: some View {
        Group {
            if session.role == nil {
                RoleGateView()
            } else {
                NavigationStack(path: $path) {
                    HomeView(open: { path.append($0) })
                        .navigationDestination(for: Route.self) { route in
                            switch route {
                            case .packages(let category):
                                PackagesView(initialCategory: category)
                            case .detail(let id):
                                PackageDetailView(packageID: id)
                            case .settings:
                                SettingsView()
                            case .about:
                                AboutView()
                            case .support:
                                SupportView()
                            }
                        }
                }
                .tint(.primary)
            }
        }
        .environmentObject(session)
        .animation(.easeInOut(duration: 0.25), value: session.role)
    }
}

// MARK: - Chọn vai trò

struct RoleGateView: View {
    @EnvironmentObject var settings: AppSettings
    @EnvironmentObject var session: Session
    @State private var pending: UserRole?
    @State private var password = ""
    @State private var attempts = 0
    @State private var closing = false
    @FocusState private var focused: Bool

    private var isVI: Bool { settings.language == .vi }

    var body: some View {
        ZStack {
                    BackgroundView()

            ScrollView(showsIndicators: false) {
                VStack(spacing: 22) {
                    if pending == nil {
                        VStack(spacing: 22) {
                            Image(systemName: "crown.fill")
                                .font(.system(size: 46))

                            VStack(spacing: 6) {
                                Text("SHINN CHEAT")
                                    .font(.system(size: 32, weight: .black, design: .rounded))
                                    .tracking(-0.8)
                                Text(isVI ? "Chọn vai trò để kích hoạt" : "Choose a role to activate")
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                            }
                        }
                        .padding(.top, 40)
                    } else {
                        Color.clear.frame(height: 12)
                    }

                    VStack(spacing: 12) {
                        ForEach(UserRole.allCases) { role in
                            roleCard(role)
                        }
                    }
                    .padding(.top, 8)

                    if let role = pending {
                        passwordCard(role)
                    }
                }
                .animation(.easeInOut(duration: 0.2), value: pending)
                .padding(.horizontal, 20)
                .padding(.bottom, 30)
            }
            .scrollDismissesKeyboard(.interactively)
        }
    }

    private func roleCard(_ role: UserRole) -> some View {
        Button(action: { select(role) }) {
            HStack(spacing: 16) {
                IconBox(systemName: role.icon, size: 52)

                Text(role.title)
                    .font(.system(size: 20, weight: .bold, design: .rounded))

                Spacer(minLength: 0)
            }
            .padding(14)
            .contentShape(Rectangle())
            .shinnGlass()
        }
        .buttonStyle(.plain)
    }

    private func passwordCard(_ role: UserRole) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Label((isVI ? "Mật khẩu " : "Password for ") + role.title, systemImage: "lock.fill")
                .font(.headline)

            SecureField(isVI ? "Nhập mật khẩu" : "Enter password", text: $password)
                .focused($focused)
                .keyboardType(.numberPad)
                .padding(14)
                .background(Color.primary.opacity(0.08), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                .onSubmit { submit() }
                .disabled(closing)

            if closing {
                Text(isVI ? "Bạn là con bò. Ứng dụng sẽ tự đóng." : "You are a cow. The app will close.")
                    .font(.footnote.bold())
                    .foregroundStyle(.red)
            } else if attempts > 0 {
                Text(isVI ? "Bạn là con bò" : "You are a cow")
                    .font(.footnote.bold())
                    .foregroundStyle(.red)
            }

            HStack(spacing: 10) {
                Button(action: cancel) {
                    Text(isVI ? "Hủy" : "Cancel")
                        .font(.system(size: 15, weight: .semibold))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 13)
                        .background(Color.primary.opacity(0.08), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                }
                .buttonStyle(.plain)

                Button(action: submit) {
                    Text(isVI ? "Xác nhận" : "Confirm")
                        .font(.system(size: 15, weight: .bold))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 13)
                        .background(Color.primary, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                        .foregroundStyle(Color(.systemBackground))
                }
                .buttonStyle(.plain)
            }
        }
        .padding(16)
        .shinnGlass()
    }

    private func select(_ role: UserRole) {
        if closing { return }
        if role.needsPassword {
            pending = role
            password = ""
            DispatchQueue.main.async { focused = true }
        } else {
            session.role = role
        }
    }

    private func cancel() {
        if closing { return }
        pending = nil
        password = ""
        focused = false
    }

    private func submit() {
        guard let role = pending, !closing else { return }
        if session.verify(password) {
            session.role = role
            pending = nil
            password = ""
            attempts = 0
        } else {
            attempts += 1
            password = ""
            if attempts >= 3 {
                closing = true
                focused = false
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
                    exit(0)
                }
            }
        }
    }
}
        
    
    