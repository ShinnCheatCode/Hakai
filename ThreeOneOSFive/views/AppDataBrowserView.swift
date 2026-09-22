import SwiftUI
struct AppDataBrowserView: View {
    // MARK: - Remote JSON URL
    private var jsonURLString: String {
        let base64String =
        "Shinn"
        guard let data = Data(base64Encoded: base64String),
              let decodedURL = String(data: data, encoding: .utf8) else {
            return ""
        }
        return decodedURL
    }
    // MARK: - Inputs
    let targetApp: LemonTargetApp
    @Binding var featureCategory: FFH4XFeatureCategory
    let onBack: () -> Void
    // MARK: - State
    @State private var features: [PatchHUDFeature] = []
    @State private var isLoading: Bool = true
    @State private var busyFeatureID: String?
    @State private var message: String?
    @State private var errorMessage: String?
    // MARK: - Body
    var body: some View {
        ZStack {
            AppBackgroundView()
                .ignoresSafeArea()
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 18) {
                    hero
                    categoryBar
                    VStack(spacing: 12) {
                        if isLoading {
                            loadingState
                        } else if features.isEmpty {
                            emptyFeatureState
                        } else {
                            ForEach($features) { $feature in
                                featureCard(feature: $feature)
                            }
                        }
                    }
                    if let message {
                        statusBanner(
                            message,
                            systemImage: "checkmark.circle.fill"
                        )
                        .transition(
                            .move(edge: .bottom)
                            .combined(with: .opacity)
                        )
                    }
                    if let errorMessage {
                        statusBanner(
                            errorMessage,
                            systemImage: "exclamationmark.triangle.fill",
                            isError: true
                        )
                        .transition(
                            .move(edge: .bottom)
                            .combined(with: .opacity)
                        )
                    }
                    footer
                }
                .padding(.horizontal, 16)
                .padding(.top, 8)
                .padding(.bottom, 120)
            }
        }
        .task {
            await fetchRemoteFeatures()
        }
        .onChange(of: featureCategory) { _ in
            Task { await fetchRemoteFeatures() }
        }
        .animation(
            .spring(response: 0.32, dampingFraction: 0.82),
            value: message
        )
        .animation(
            .spring(response: 0.32, dampingFraction: 0.82),
            value: errorMessage
        )
        .animation(
            .spring(response: 0.32, dampingFraction: 0.82),
            value: isLoading
        )
    }
    // MARK: - Remote Data Fetcher
    @MainActor
    private func fetchRemoteFeatures() async {
        isLoading = true
        message = nil
        errorMessage = nil
        var loadedFeatures = await PatchHUDFeature.fetchRemote(
            from: jsonURLString,
            targetApp: targetApp,
            category: featureCategory
        )
        FeatureSettingsStore.restore(&loadedFeatures)
        features = loadedFeatures
        isLoading = false
    }
    // MARK: - Hero
    private var hero: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(alignment: .center, spacing: 12) {
                Button(action: onBack) {
                    Image(systemName: "chevron.left")
                        .font(.body.weight(.bold))
                        .frame(width: 38, height: 38)
                        .background(
                            .thinMaterial,
                            in: Circle()
                        )
                }
                .buttonStyle(.plain)
                ProjectAppIcon(
                    assetName: targetApp.iconAssetName,
                    size: 48
                )
                VStack(alignment: .leading, spacing: 2) {
                    Text(targetApp.name)
                        .font(
                            .system(
                                size: 26,
                                weight: .bold,
                                design: .rounded
                            )
                        )
                        .tracking(-0.5)
                    Text(targetApp.bundleID)
                        .font(.caption.monospaced())
                        .foregroundStyle(.secondary)
                    Text(featureCategory.title)
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(AppTheme.accent)
                }
                Spacer(minLength: 0)
            }
            HStack(spacing: 8) {
                StatusPill(
                    title: "\(features.count) chức năng",
                    icon: "slider.horizontal.3"
                )
                StatusPill(
                    title: "Sẵn sàng",
                    icon: "checkmark.shield.fill"
                )
            }
            .padding(.top, 14)
        }
        .padding(.top, 6)
    }
    // MARK: - Horizontal Category Bar
    private var categoryBar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 9) {
                ForEach(FFH4XFeatureCategory.allCases) { category in
                    Button {
                        withAnimation(.spring(response: 0.32, dampingFraction: 0.82)) {
                            featureCategory = category
                        }
                    } label: {
                        HStack(spacing: 7) {
                            Image(systemName: category.icon)
                                .font(.system(size: 13, weight: .semibold))
                            Text(category.title)
                                .font(
                                    .system(
                                        size: 14,
                                        weight: .semibold,
                                        design: .rounded
                                    )
                                )
                        }
                        .foregroundStyle(
                            featureCategory == category
                            ? .white
                            : .primary
                        )
                        .padding(.horizontal, 15)
                        .frame(height: 40)
                        .background {
                            RoundedRectangle(
                                cornerRadius: 15,
                                style: .continuous
                            )
                            .fill(.ultraThinMaterial)
                            if featureCategory == category {
                                RoundedRectangle(
                                    cornerRadius: 15,
                                    style: .continuous
                                )
                                .fill(category.tint.opacity(0.90))
                            }
                        }
                        .overlay {
                            RoundedRectangle(
                                cornerRadius: 15,
                                style: .continuous
                            )
                            .stroke(
                                featureCategory == category
                                ? Color.white.opacity(0.42)
                                : Color.white.opacity(0.25),
                                lineWidth: 0.8
                            )
                        }
                        .shadow(
                            color: featureCategory == category
                            ? category.tint.opacity(0.20)
                            : .clear,
                            radius: 12,
                            y: 5
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.vertical, 2)
        }
    }
    // MARK: - Feature Card
    private func featureCard(
        feature: Binding<PatchHUDFeature>
    ) -> some View {
        let value = feature.wrappedValue
        let isBusy = busyFeatureID == value.id
        return HStack(spacing: 14) {
            ZStack {
                RoundedRectangle(
                    cornerRadius: 17,
                    style: .continuous
                )
                .fill(value.tint.opacity(0.14))
                RoundedRectangle(
                    cornerRadius: 17,
                    style: .continuous
                )
                .strokeBorder(value.tint.opacity(0.12))
                Image(systemName: value.icon)
                    .font(
                        .system(
                            size: 20,
                            weight: .bold
                        )
                    )
                    .foregroundStyle(value.tint)
            }
            .frame(width: 54, height: 54)
            VStack(
                alignment: .leading,
                spacing: 5
            ) {
                Text(value.title)
                    .font(
                        .system(
                            size: 18,
                            weight: .semibold,
                            design: .rounded
                        )
                    )
                    .foregroundStyle(.primary)
                Text(value.content)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
                    .fixedSize(
                        horizontal: false,
                        vertical: true
                    )
            }
            Spacer(minLength: 4)
            if isBusy {
                ProgressView()
                    .controlSize(.small)
            } else {
                Toggle(
                    "",
                    isOn: Binding(
                        get: {
                            feature.wrappedValue.isOn
                        },
                        set: { newValue in
                            Task {
                                await toggleFeature(
                                    feature: feature,
                                    newValue: newValue
                                )
                            }
                        }
                    )
                )
                .labelsHidden()
                .tint(value.tint)
            }
        }
        .padding(14)
        .background(
            .ultraThinMaterial,
            in: RoundedRectangle(
                cornerRadius: 22,
                style: .continuous
            )
        )
        .overlay {
            RoundedRectangle(
                cornerRadius: 22,
                style: .continuous
            )
            .stroke(
                Color.white.opacity(0.20),
                lineWidth: 0.8
            )
        }
        .shadow(
            color: .black.opacity(0.08),
            radius: 16,
            y: 7
        )
    }
    // MARK: - Feature Toggle
    @MainActor
    private func toggleFeature(
        feature: Binding<PatchHUDFeature>,
        newValue: Bool
    ) async {
        guard busyFeatureID == nil else {
            return
        }
        let value = feature.wrappedValue
        busyFeatureID = value.id
        message = nil
        errorMessage = nil
        do {
            let replacementDataList =
                try await loadReplacementData(
                    for: value
                )
            let project =
                value.makeProject(
                    replacementDataList: replacementDataList
                )
            if newValue {
                try await PatchProjectCoordinator.shared.apply(
                    project
                )
                feature.wrappedValue.isOn = true
                FeatureSettingsStore.set(
                    true,
                    for: value
                )
                message = "Đã bật \(value.title)"
            } else {
                try await PatchProjectCoordinator.shared.restore(
                    project
                )
                feature.wrappedValue.isOn = false
                FeatureSettingsStore.set(
                    false,
                    for: value
                )
                message = "Đã tắt \(value.title)"
            }
        } catch {
            errorMessage = error.localizedDescription
            feature.wrappedValue.isOn =
                FeatureSettingsStore.get(value)
        }
        busyFeatureID = nil
    }
    // MARK: - Replacement Data
    private func loadReplacementData(
        for feature: PatchHUDFeature
    ) async throws -> [Data] {
        guard !feature.replacementFilenames.isEmpty else {
            throw PatchHUDError.payloadEmpty(
                "replacement"
            )
        }
        var result: [Data] = []
        for filename in feature.replacementFilenames {
            guard let url = URL(string: filename) else {
                throw PatchHUDError.invalidServerURL
            }
            do {
                let (
                    data,
                    response
                ) = try await URLSession.shared.data(
                    from: url
                )
                if let httpResponse =
                    response as? HTTPURLResponse,
                   !(200...299).contains(
                    httpResponse.statusCode
                   ) {
                    throw PatchHUDError.payloadDownloadFailed(
                        filename
                    )
                }
                guard !data.isEmpty else {
                    throw PatchHUDError.payloadEmpty(
                        filename
                    )
                }
                result.append(data)
            } catch let error as PatchHUDError {
                throw error
            } catch {
                throw PatchHUDError.payloadDownloadFailed(
                    filename
                )
            }
        }
        return result
    }
    // MARK: - Loading State
    private var loadingState: some View {
        VStack(spacing: 12) {
            ProgressView()
                .controlSize(.regular)
            Text("Đang tải chức năng…")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 50)
        .background(
            .ultraThinMaterial,
            in: RoundedRectangle(
                cornerRadius: 22,
                style: .continuous
            )
        )
    }
    // MARK: - Empty State
    private var emptyFeatureState: some View {
        VStack(spacing: 10) {
            Image(systemName: "square.slash")
                .font(
                    .system(
                        size: 30,
                        weight: .light
                    )
                )
                .foregroundStyle(.secondary)
            Text("Chưa có chức năng")
                .font(.headline)
            Text(
                "Không tìm thấy chức năng nào cho mục này."
            )
            .font(.subheadline)
            .foregroundStyle(.secondary)
            .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 45)
        .background(
            .ultraThinMaterial,
            in: RoundedRectangle(
                cornerRadius: 22,
                style: .continuous
            )
        )
    }
    // MARK: - Status Banner
    private func statusBanner(
        _ text: String,
        systemImage: String,
        isError: Bool = false
    ) -> some View {
        HStack(spacing: 10) {
            Image(systemName: systemImage)
                .foregroundStyle(
                    isError
                    ? .red
                    : .green
                )
            Text(text)
                .font(.subheadline.weight(.medium))
            Spacer()
        }
        .padding(13)
        .background(
            (isError ? Color.red : Color.green)
                .opacity(0.10),
            in: RoundedRectangle(
                cornerRadius: 15,
                style: .continuous
            )
        )
        .overlay {
            RoundedRectangle(
                cornerRadius: 15,
                style: .continuous
            )
            .stroke(
                (isError ? Color.red : Color.green)
                    .opacity(0.18),
                lineWidth: 0.8
            )
        }
    }
    // MARK: - Footer
    private var footer: some View {
        VStack(spacing: 5) {
            Text("ThreeOneOSFive")
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)
            Text(
                "Dữ liệu chức năng được tải từ máy chủ cấu hình."
            )
            .font(.caption2)
            .foregroundStyle(.tertiary)
            .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 12)
    }
}
// MARK: - Feature Settings Store
private enum FeatureSettingsStore {
    private static let prefix = "FFH4X.feature"
    private static func key(
        for feature: PatchHUDFeature
    ) -> String {
        [
            prefix,
            feature.targetAppID,
            feature.categoryID,
            feature.id
        ]
        .joined(separator: ".")
    }
    static func get(
        _ feature: PatchHUDFeature
    ) -> Bool {
        guard feature.saveSetting else {
            return feature.isOn
        }
        let settingKey = key(for: feature)
        guard UserDefaults.standard.object(
            forKey: settingKey
        ) != nil else {
            return feature.isOn
        }
        return UserDefaults.standard.bool(
            forKey: settingKey
        )
    }
    static func set(
        _ value: Bool,
        for feature: PatchHUDFeature
    ) {
        let settingKey = key(for: feature)
        guard feature.saveSetting else {
            UserDefaults.standard.removeObject(
                forKey: settingKey
            )
            return
        }
        UserDefaults.standard.set(
            value,
            forKey: settingKey
        )
    }
    static func restore(
        _ features: inout [PatchHUDFeature]
    ) {
        for index in features.indices {
            features[index].isOn =
                get(features[index])
        }
    }
    static func remove(
        _ feature: PatchHUDFeature
    ) {
        UserDefaults.standard.removeObject(
            forKey: key(for: feature)
        )
    }
    static func clearAll() {
        let defaults = UserDefaults.standard
        for key in defaults.dictionaryRepresentation().keys
        where key.hasPrefix("\(prefix).") {
            defaults.removeObject(forKey: key)
        }
    }
}
// MARK: - Status Pill
private struct StatusPill: View {
    let title: String
    let icon: String
    var body: some View {
        Label(
            title,
            systemImage: icon
        )
        .font(
            .caption.weight(.semibold)
        )
        .foregroundStyle(.secondary)
        .padding(.horizontal, 10)
        .padding(.vertical, 7)
        .background(
            .thinMaterial,
            in: Capsule()
        )
    }
}
// MARK: - Feature Model
private struct PatchHUDFeature:
    Identifiable,
    Decodable {
    let id: String
    let title: String
    let subtitle: String
    let content: String
    let icon: String
    let tintHex: String
    let targetAppID: String
    let categoryID: String
    let bundleID: String
    let relativePaths: [String]
    let replacementFilenames: [String]
    let saveSetting: Bool
    var replacementFilename: String {
        replacementFilenames.joined(separator: ", ")
    }
    let projectID: UUID
    private enum CodingKeys: String, CodingKey {
        case id
        case title
        case subtitle
        case content
        case icon
        case tintHex
        case targetAppID
        case categoryID
        case bundleID
        case relativePath
        case relativePaths
        case replacementFilename
        case replacementFilenames
        case saveSetting
        case projectID
        case isOn
    }
    init(from decoder: Decoder) throws {
        let container =
            try decoder.container(
                keyedBy: CodingKeys.self
            )
        id =
            try container.decode(
                String.self,
                forKey: .id
            )
        title =
            try container.decode(
                String.self,
                forKey: .title
            )
        subtitle =
            try container.decode(
                String.self,
                forKey: .subtitle
            )
        content =
            try container.decode(
                String.self,
                forKey: .content
            )
        icon =
            try container.decode(
                String.self,
                forKey: .icon
            )
        tintHex =
            try container.decode(
                String.self,
                forKey: .tintHex
            )
        targetAppID =
            try container.decode(
                String.self,
                forKey: .targetAppID
            )
        categoryID =
            try container.decode(
                String.self,
                forKey: .categoryID
            )
        bundleID =
            try container.decode(
                String.self,
                forKey: .bundleID
            )
        if let filenames =
            try container.decodeIfPresent(
                [String].self,
                forKey: .replacementFilenames
            ) {
            replacementFilenames =
                filenames.filter {
                    !$0.trimmingCharacters(
                        in: .whitespacesAndNewlines
                    ).isEmpty
                }
        } else if let filename =
                    try container.decodeIfPresent(
                        String.self,
                        forKey: .replacementFilename
                    ),
                    !filename.trimmingCharacters(
                        in: .whitespacesAndNewlines
                    ).isEmpty {
            replacementFilenames = [filename]
        } else {
            replacementFilenames = []
        }
        saveSetting =
            try container.decodeIfPresent(
                Bool.self,
                forKey: .saveSetting
            ) ?? true
        projectID =
            try container.decode(
                UUID.self,
                forKey: .projectID
            )
        isOn =
            try container.decode(
                Bool.self,
                forKey: .isOn
            )
        if let paths =
            try container.decodeIfPresent(
                [String].self,
                forKey: .relativePaths
            ) {
            relativePaths =
                paths.filter {
                    !$0.trimmingCharacters(
                        in: .whitespacesAndNewlines
                    ).isEmpty
                }
        } else if let path =
                    try container.decodeIfPresent(
                        String.self,
                        forKey: .relativePath
                    ),
                    !path.trimmingCharacters(
                        in: .whitespacesAndNewlines
                    ).isEmpty {
            relativePaths = [path]
        } else {
            relativePaths = []
        }
    }
    var isOn: Bool
    var tint: Color {
        Color(hex: tintHex)
    }
    // MARK: - Make Project
    func makeProject(
        replacementDataList: [Data]
    ) -> PatchProject {
        let rules = zip(
            zip(
                relativePaths,
                replacementFilenames
            ),
            replacementDataList
        ).map { pair, data in
            let (path, filename) = pair
            return PatchRule(
                bundleID: bundleID,
                relativePath: path,
                replacementFilename: filename,
                replacementData: data
            )
        }
        return PatchProject(
            id: projectID,
            name: "HUD • \(title)",
            rules: rules
        )
    }
    // MARK: - Fetch Remote
    static func fetchRemote(
        from urlString: String,
        targetApp: LemonTargetApp,
        category: FFH4XFeatureCategory
    ) async -> [PatchHUDFeature] {
        guard let url =
                URL(string: urlString) else {
            return []
        }
        do {
            let (
                data,
                response
            ) = try await URLSession.shared.data(
                from: url
            )
            if let httpResponse =
                response as? HTTPURLResponse,
               httpResponse.statusCode != 200 {
                return []
            }
            let items =
                try JSONDecoder().decode(
                    [PatchHUDFeature].self,
                    from: data
                )
            return items.filter { item in
                item.targetAppID == targetApp.id
                &&
                item.categoryID == category.id
            }
        } catch {
            print(
                "Lỗi fetch JSON remote: \(error.localizedDescription)"
            )
            return []
        }
    }
}
// MARK: - Color Hex Extension
private extension Color {
    init(hex: String) {
        let hexClean =
            hex.trimmingCharacters(
                in:
                    CharacterSet
                        .alphanumerics
                        .inverted
            )
        var int: UInt64 = 0
        Scanner(
            string: hexClean
        ).scanHexInt64(&int)
        let a: UInt64
        let r: UInt64
        let g: UInt64
        let b: UInt64
        switch hexClean.count {
        case 3:
            (
                a,
                r,
                g,
                b
            ) = (
                255,
                (int >> 8) * 17,
                (int >> 4 & 0xF) * 17,
                (int & 0xF) * 17
            )
        case 6:
            (
                a,
                r,
                g,
                b
            ) = (
                255,
                int >> 16,
                int >> 8 & 0xFF,
                int & 0xFF
            )
        case 8:
            (
                a,
                r,
                g,
                b
            ) = (
                int >> 24,
                int >> 16 & 0xFF,
                int >> 8 & 0xFF,
                int & 0xFF
            )
        default:
            (
                a,
                r,
                g,
                b
            ) = (
                255,
                0,
                0,
                0
            )
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}
// MARK: - Errors
private enum PatchHUDError:
    LocalizedError {
    case invalidServerURL
    case payloadEmpty(String)
    case payloadDownloadFailed(String)
    case nothingToRestore
    var errorDescription: String? {
        switch self {
        case .invalidServerURL:
            return "Đường dẫn máy chủ không hợp lệ."
        case .payloadEmpty(let filename):
            return "Nội dung tệp \(filename) trên máy chủ bị rỗng."
        case .payloadDownloadFailed(let filename):
            return "Không thể tải tệp \(filename) từ máy chủ."
        case .nothingToRestore:
            return "Không có thay đổi trước đó để khôi phục."
        }
    }
}