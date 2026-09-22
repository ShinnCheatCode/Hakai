import SwiftUI
import UIKit
import UniformTypeIdentifiers
import QuickLook

struct FileBrowserView: View {
    @Environment(\.appLanguage) private var language
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @EnvironmentObject private var patchDraftCoordinator: PatchDraftCoordinator
    @EnvironmentObject private var fileOperationCoordinator: FileOperationCoordinator
    let containerPath: String
    let title: String
    let bundleID: String?
    let isRoot: Bool
    private let filesTabSession: Binding<FilesTabSession>?
    @State private var currentPath: String
    @State private var entries: [FileEntry] = []
    @State private var fileSearchText = ""
    @State private var isLoadingEntries = true
    @State private var hasGranted = false
    @State private var pendingReplacementRequest: FileReplacementRequest?
    @State private var replacementRequest: FileReplacementRequest?
    @State private var activityText: String?
    @State private var replacementNotice: FileReplacementNotice?
    @State private var operationNotice: FileReplacementNotice?
    @State private var namePrompt: FileNamePrompt?
    @State private var nameInput = ""
    @State private var pendingImportPickerID: UUID?
    @State private var isShowingImportPicker = false
    @State private var importSession: FileImportSession?
    @State private var importConflict: FileImportConflict?
    @State private var isSelecting = false
    @State private var selectedEntryIDs = Set<String>()
    @State private var transferSession: FileTransferSession?
    @State private var transferConflict: FileTransferConflict?
    @State private var deleteTargets: [FileEntry] = []

    private var filteredEntries: [FileEntry] {
        let query = fileSearchText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !query.isEmpty else { return entries }
        return entries.filter { $0.name.localizedCaseInsensitiveContains(query) }
    }

    private var selectedEntries: [FileEntry] {
        entries.filter { selectedEntryIDs.contains($0.id) }
    }

    private var overlayState: FileBrowserOverlayState {
        if isLoadingEntries { return .loading }
        if entries.isEmpty { return .empty }
        if filteredEntries.isEmpty { return .noResults }
        return .none
    }

    private var interfaceAnimation: Animation? {
        reduceMotion ? nil : .easeOut(duration: 0.20)
    }

    init(
        containerPath: String,
        title: String,
        bundleID: String? = nil,
        filesTabSession: Binding<FilesTabSession>? = nil
    ) {
        self.containerPath = containerPath
        self.title = title
        self.bundleID = bundleID
        self.isRoot = true
        self.filesTabSession = filesTabSession
        _currentPath = State(initialValue: containerPath)
    }

    var body: some View {
        VStack(spacing: 0) {
            AppSearchField(
                text: $fileSearchText,
                prompt: language.text("browser.search_files"),
                clearLabel: language.text("common.clear")
            )

            Divider()

            List {
                Section {
                    ForEach(filteredEntries) { entry in
                        fileRow(entry)
                    }
                } header: {
                    Text(
                        language.text(
                            "browser.items_count",
                            Int64(filteredEntries.count)
                        )
                    )
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .textCase(nil)
                }
            }
            .listStyle(.insetGrouped)
            .environment(
                \.defaultMinListRowHeight,
                AppTheme.fileRowHeight
            )
            .scrollDismissesKeyboard(.interactively)
            .overlay {
                Group {
                    switch overlayState {
                    case .loading:
                        ProgressView(language.text("browser.loading"))
                            .frame(
                                maxWidth: .infinity,
                                maxHeight: .infinity
                            )

                    case .empty:
                        fileEmptyView

                    case .noResults:
                        searchEmptyView

                    case .none:
                        EmptyView()
                    }
                }
                .transition(.opacity)
                .animation(
                    interfaceAnimation,
                    value: overlayState
                )
            }
        }
        .navigationTitle(
            currentPath == containerPath
                ? title
                : (currentPath as NSString).lastPathComponent
        )
        .navigationBarTitleDisplayMode(.inline)
        .navigationDestination(
            for: FileBrowserDestination.self
        ) { destination in
            FileBrowserView(
                containerPath: destination.containerPath,
                startPath: destination.startPath,
                title: destination.title,
                bundleID: destination.bundleID,
                filesTabSession: filesTabSession
            )
        }
        .toolbar {
            if let filesTabSession {
                ToolbarItem(
                    placement: .navigationBarTrailing
                ) {
                    FilesTabToolbarButton(
                        session: filesTabSession
                    )
                }
            }

            ToolbarItem(
                placement: .navigationBarTrailing
            ) {
                Button(
                    isSelecting
                        ? language.text("common.cancel")
                        : language.text("browser.select")
                ) {
                    toggleSelectionMode()
                }
                .disabled(
                    activityText != nil ||
                    importSession != nil
                )
            }

            ToolbarItem(
                placement: .navigationBarTrailing
            ) {
                if isSelecting {
                    Button(
                        selectionActionTitle,
                        action: toggleAllSelection
                    )
                    .disabled(entries.isEmpty)
                } else {
                    Menu {
                        if let payload =
                            fileOperationCoordinator.payload
                        {
                            Button {
                                beginPaste(payload)
                            } label: {
                                Label(
                                    language.text(
                                        "browser.paste_count",
                                        Int64(payload.itemCount)
                                    ),
                                    systemImage: "doc.on.clipboard"
                                )
                            }

                            Button(
                                role: .destructive
                            ) {
                                fileOperationCoordinator.clear()
                            } label: {
                                Label(
                                    language.text(
                                        "browser.clear_clipboard"
                                    ),
                                    systemImage: "xmark"
                                )
                            }

                            Divider()
                        }

                        Button {
                            requestImportPicker()
                        } label: {
                            Label(
                                language.text(
                                    "browser.import_files"
                                ),
                                systemImage:
                                    "square.and.arrow.down"
                            )
                        }

                        Divider()

                        Button {
                            presentNamePrompt(.createFile)
                        } label: {
                            Label(
                                language.text(
                                    "browser.new_file"
                                ),
                                systemImage:
                                    "doc.badge.plus"
                            )
                        }

                        Button {
                            presentNamePrompt(.createFolder)
                        } label: {
                            Label(
                                language.text(
                                    "browser.new_folder"
                                ),
                                systemImage:
                                    "folder.badge.plus"
                            )
                        }
                    } label: {
                        Image(systemName: "plus")
                    }
                    .disabled(
                        activityText != nil ||
                        importSession != nil ||
                        transferSession != nil
                    )
                    .accessibilityLabel(
                        language.text("browser.add")
                    )
                }
            }
        }
        .safeAreaInset(
            edge: .bottom,
            spacing: 0
        ) {
            if isSelecting {
                FileSelectionActionBar(
                    selectedCount: selectedEntryIDs.count,
                    language: language,
                    onCopy: {
                        prepareTransfer(.copy)
                    },
                    onMove: {
                        prepareTransfer(.move)
                    },
                    onArchive: prepareArchive,
                    onDelete: prepareBulkDelete
                )
                .transition(
                    .move(edge: .bottom)
                        .combined(with: .opacity)
                )
            } else if let payload =
                fileOperationCoordinator.payload
            {
                FilePasteBar(
                    itemCount: payload.itemCount,
                    mode: payload.mode,
                    language: language,
                    onPaste: {
                        beginPaste(payload)
                    },
                    onCancel: fileOperationCoordinator.clear
                )
                .transition(
                    .move(edge: .bottom)
                        .combined(with: .opacity)
                )
            }
        }
        .safeAreaInset(
            edge: .top,
            spacing: 0
        ) {
            if horizontalSizeClass == .regular,
               let filesTabSession
            {
                FilesTabStrip(
                    session: filesTabSession
                )
            }
        }
        .animation(
            interfaceAnimation,
            value: isSelecting
        )
        .animation(
            interfaceAnimation,
            value: fileOperationCoordinator.payload
        )
        .onAppear {
            load()
        }
        .sheet(item: $replacementRequest) { request in
            FileDocumentPicker(
                allowsMultipleSelection: false,
                onSelection: { result in
                    log(
                        "filebrowser: replacement picker returned"
                    )
                    handleReplacementImport(
                        result,
                        request: request
                    )
                    replacementRequest = nil
                },
                onCancel: {
                    log(
                        "filebrowser: replacement picker cancelled"
                    )
                    replacementRequest = nil
                }
            )
            .ignoresSafeArea()
        }
        .sheet(
            isPresented: $isShowingImportPicker
        ) {
            FileDocumentPicker(
                allowsMultipleSelection: true,
                onSelection: { result in
                    handleImportSelection(result)
                    isShowingImportPicker = false
                },
                onCancel: {
                    isShowingImportPicker = false
                }
            )
            .ignoresSafeArea()
        }
        .sheet(item: $replacementNotice) { notice in
            NoticeSheet(
                title: notice.title,
                message: notice.message
            )
        }
        .sheet(item: $operationNotice) { notice in
            NoticeSheet(
                title: notice.title,
                message: notice.message
            )
        }
        .alert(item: $namePrompt) { prompt in
            Alert(
                title: Text(
                    namePromptTitle(prompt.action)
                ),
                message: Text(
                    namePromptMessage(prompt.action)
                ),
                primaryButton: .default(
                    Text(language.text("common.save"))
                ) {
                    submitNamePrompt(prompt.action)
                },
                secondaryButton: .cancel()
            )
        }
        .alert(
            language.text("browser.replace_title"),
            isPresented: Binding(
                get: {
                    pendingReplacementRequest != nil
                },
                set: { presented in
                    if !presented {
                        pendingReplacementRequest = nil
                    }
                }
            )
        ) {
            Button(
                language.text("browser.replace"),
                role: .destructive
            ) {
                guard let request =
                    pendingReplacementRequest
                else {
                    return
                }

                pendingReplacementRequest = nil
                replacementRequest = request
            }

            Button(
                language.text("common.cancel"),
                role: .cancel
            ) {
                pendingReplacementRequest = nil
            }
        } message: {
            if let request = pendingReplacementRequest {
                Text(
                    language.text(
                        "browser.replace_message",
                        request.destination.lastPathComponent
                    )
                )
            }
        }
        .confirmationDialog(
            language.text("browser.delete_title"),
            isPresented: Binding(
                get: {
                    !deleteTargets.isEmpty
                },
                set: { presented in
                    if !presented {
                        deleteTargets = []
                    }
                }
            ),
            titleVisibility: .visible
        ) {
            Button(
                language.text("browser.delete"),
                role: .destructive
            ) {
                let targets = deleteTargets
                deleteTargets = []
                deleteEntries(targets)
            }

            Button(
                language.text("common.cancel"),
                role: .cancel
            ) {
                deleteTargets = []
            }
        } message: {
            Text(
                language.text(
                    "browser.delete_message",
                    Int64(deleteTargets.count)
                )
            )
        }
    }

    // MARK: - Loading

    private func load() {
        isLoadingEntries = true

        let path = currentPath

        DispatchQueue.global(qos: .userInitiated).async {
            let result = FileManagerService.listDirectory(
                atPath: path
            )

            DispatchQueue.main.async {
                guard path == currentPath else {
                    return
                }

                switch result {
                case .success(let values):
                    entries = values
                    hasGranted = true

                case .failure(let error):
                    entries = []
                    hasGranted = false
                    log(
                        "filebrowser: list failed: \(error.localizedDescription)"
                    )
                }

                isLoadingEntries = false
            }
        }
    }

    // MARK: - Selection

    private var selectionActionTitle: String {
        if selectedEntryIDs.count == entries.count,
           !entries.isEmpty
        {
            return language.text("common.deselect_all")
        }

        return language.text("common.select_all")
    }

    private func toggleSelectionMode() {
        withAnimation(interfaceAnimation) {
            isSelecting.toggle()

            if !isSelecting {
                selectedEntryIDs.removeAll()
            }
        }
    }

    private func toggleAllSelection() {
        withAnimation(interfaceAnimation) {
            if selectedEntryIDs.count == entries.count {
                selectedEntryIDs.removeAll()
            } else {
                selectedEntryIDs = Set(
                    entries.map(\.id)
                )
            }
        }
    }

    private func toggleSelection(
        for entry: FileEntry
    ) {
        if selectedEntryIDs.contains(entry.id) {
            selectedEntryIDs.remove(entry.id)
        } else {
            selectedEntryIDs.insert(entry.id)
        }
    }

    // MARK: - File Row

    @ViewBuilder
    private func fileRow(
        _ entry: FileEntry
    ) -> some View {
        let selectionState =
            isSelecting
                ? selectedEntryIDs.contains(entry.id)
                : nil

        Button {
            if isSelecting {
                toggleSelection(for: entry)
                return
            }

            if entry.isDirectory {
                navigate(to: entry)
            } else {
                preview(entry)
            }
        } label: {
            HStack(spacing: 12) {
                AppRowIcon(
                    systemName: entry.isDirectory
                        ? "folder.fill"
                        : fileSymbol(for: entry),
                    tint: entry.isDirectory
                        ? .orange
                        : AppTheme.accent,
                    symbolSize:
                        AppTheme.fileRowIconSize,
                    frameSize:
                        AppTheme.fileRowIconFrame
                )

                VStack(
                    alignment: .leading,
                    spacing: 3
                ) {
                    Text(entry.name)
                        .font(
                            .subheadline.weight(
                                .semibold
                            )
                        )
                        .lineLimit(
                            dynamicTypeSize.isAccessibilitySize
                                ? 2
                                : 1
                        )
                        .truncationMode(.middle)

                    Text(
                        entry.isDirectory
                            ? language.text(
                                "browser.folder"
                            )
                            : entry.sizeText
                    )
                    .font(.caption)
                    .foregroundStyle(.secondary)
                }

                Spacer(minLength: 4)

                if let selectionState {
                    Image(
                        systemName:
                            selectionState
                                ? "checkmark.circle.fill"
                                : "circle"
                    )
                    .font(
                        .system(
                            size:
                                AppTheme.selectionIconSize,
                            weight: .medium
                        )
                    )
                    .foregroundStyle(
                        selectionState
                            ? AppTheme.accent
                            : Color.secondary
                    )
                    .accessibilityHidden(true)
                }
            }
            .contentShape(Rectangle())
            .accessibilityElement(children: .combine)
        }
        .buttonStyle(.plain)
        .contextMenu {
            fileContextMenu(for: entry)
        }
    }

    @ViewBuilder
    private func fileContextMenu(
        for entry: FileEntry
    ) -> some View {
        Button {
            prepareTransfer(
                .copy,
                entries: [entry]
            )
        } label: {
            Label(
                language.text("browser.copy"),
                systemImage: "doc.on.doc"
            )
        }

        Button {
            prepareTransfer(
                .move,
                entries: [entry]
            )
        } label: {
            Label(
                language.text("browser.move"),
                systemImage: "folder"
            )
        }

        Button {
            presentNamePrompt(
                .rename(entry)
            )
        } label: {
            Label(
                language.text("browser.rename"),
                systemImage: "pencil"
            )
        }

        if entry.isDirectory == false {
            Button {
                requestReplacement(for: entry)
            } label: {
                Label(
                    language.text("browser.replace"),
                    systemImage:
                        "arrow.triangle.2.circlepath"
                )
            }
        }

        Button {
            prepareArchive(
                entries: [entry]
            )
        } label: {
            Label(
                language.text("browser.create_zip"),
                systemImage: "archivebox"
            )
        }

        Divider()

        Button(
            role: .destructive
        ) {
            deleteTargets = [entry]
        } label: {
            Label(
                language.text("browser.delete"),
                systemImage: "trash"
            )
        }
    }

    private func fileSymbol(
        for entry: FileEntry
    ) -> String {
        switch entry.fileExtension.lowercased() {
        case "swift":
            return "swift"
        case "json":
            return "curlybraces"
        case "plist":
            return "list.bullet.rectangle"
        case "png", "jpg", "jpeg", "gif", "heic", "webp":
            return "photo"
        case "zip", "ipa":
            return "archivebox"
        case "txt", "md", "log":
            return "doc.text"
        case "framework", "dylib", "bundle":
            return "shippingbox"
        case "h", "m", "mm", "c", "cpp":
            return "chevron.left.forwardslash.chevron.right"
        default:
            return "doc"
        }
    }

    // MARK: - Navigation

    private func navigate(
        to entry: FileEntry
    ) {
        guard entry.isDirectory else {
            return
        }

        let destination = FileBrowserDestination(
            containerPath: containerPath,
            startPath: entry.path,
            title: entry.name,
            bundleID: bundleID
        )

        // Keep navigation driven by NavigationStack value destinations.
        // The destination is encoded by the row's NavigationLink-equivalent.
        patchDraftCoordinator.navigateTo(
            destination
        )
    }

    private func preview(
        _ entry: FileEntry
    ) {
        patchDraftCoordinator.presentPreview(
            FileQuickLookView(file: entry)
        )
    }

    // MARK: - Empty States

    private var fileEmptyView: some View {
        VStack(spacing: 10) {
            Image(systemName: "folder")
                .font(
                    .system(
                        size: AppTheme.emptyIconSize,
                        weight: .light
                    )
                )
                .foregroundStyle(.secondary)

            Text(
                language.text("browser.empty")
            )
            .font(.subheadline)
            .foregroundStyle(.secondary)
        }
        .frame(
            maxWidth: .infinity,
            maxHeight: .infinity
        )
        .padding()
    }

    private var searchEmptyView: some View {
        VStack(spacing: 10) {
            Image(systemName: "magnifyingglass")
                .font(
                    .system(
                        size: AppTheme.emptyIconSize,
                        weight: .light
                    )
                )
                .foregroundStyle(.secondary)

            Text(
                language.text(
                    "browser.no_results"
                )
            )
            .font(.subheadline)
            .foregroundStyle(.secondary)
        }
        .frame(
            maxWidth: .infinity,
            maxHeight: .infinity
        )
        .padding()
    }

    // MARK: - Import

    private func requestImportPicker() {
        pendingImportPickerID = UUID()
        isShowingImportPicker = true
    }

    private func handleImportSelection(
        _ result: Result<[URL], Error>
    ) {
        switch result {
        case .failure(let error):
            operationNotice = FileReplacementNotice(
                title: language.text(
                    "browser.import_error"
                ),
                message: error.localizedDescription
            )

        case .success(let urls):
            guard !urls.isEmpty else {
                return
            }

            let session = FileImportSession(
                urls: urls,
                destination: URL(
                    fileURLWithPath: currentPath,
                    isDirectory: true
                )
            )

            importSession = session
            importNext(session)
        }
    }

    private func importNext(
        _ session: FileImportSession
    ) {
        guard let source = session.urls.first else {
            importSession = nil
            load()
            return
        }

        let destination = URL(
            fileURLWithPath: currentPath,
            isDirectory: true
        )
        .appendingPathComponent(
            source.lastPathComponent,
            isDirectory: false
        )

        if FileManager.default.fileExists(
            atPath: destination.path
        ) {
            importConflict = FileImportConflict(
                sourceURL: source,
                destinationURL: destination
            )
            return
        }

        copyImported(
            source,
            to: destination,
            session: session
        )
    }

    private func copyImported(
        _ source: URL,
        to destination: URL,
        session: FileImportSession
    ) {
        activityText = language.text(
            "browser.importing"
        )

        DispatchQueue.global(
            qos: .userInitiated
        ).async {
            do {
                try FileManager.default.copyItem(
                    at: source,
                    to: destination
                )

                DispatchQueue.main.async {
                    activityText = nil
                    importSession = session.advancing()
                    importNext(
                        session.advancing()
                    )
                }
            } catch {
                DispatchQueue.main.async {
                    activityText = nil
                    operationNotice =
                        FileReplacementNotice(
                            title: language.text(
                                "browser.import_error"
                            ),
                            message:
                                error.localizedDescription
                        )

                    importSession = nil
                }
            }
        }
    }

    // MARK: - Replacement

    private func requestReplacement(
        for entry: FileEntry
    ) {
        pendingReplacementRequest =
            FileReplacementRequest(
                source: entry,
                destination: URL(
                    fileURLWithPath: entry.path
                )
            )
    }

    private func handleReplacementImport(
        _ result: Result<[URL], Error>,
        request: FileReplacementRequest
    ) {
        switch result {
        case .failure(let error):
            operationNotice =
                FileReplacementNotice(
                    title: language.text(
                        "browser.replace_error"
                    ),
                    message:
                        error.localizedDescription
                )

        case .success(let urls):
            guard let source = urls.first else {
                return
            }

            activityText = language.text(
                "browser.replacing"
            )

            DispatchQueue.global(
                qos: .userInitiated
            ).async {
                let result =
                    FileReplacementService.replace(
                        source: source,
                        destination: request.destination
                    )

                DispatchQueue.main.async {
                    activityText = nil

                    switch result {
                    case .success:
                        operationNotice =
                            FileReplacementNotice(
                                title: language.text(
                                    "browser.replace_success"
                                ),
                                message:
                                    request.destination
                                    .lastPathComponent
                            )
                        load()

                    case .failure(let error):
                        operationNotice =
                            FileReplacementNotice(
                                title: language.text(
                                    "browser.replace_error"
                                ),
                                message:
                                    error.localizedDescription
                            )
                    }
                }
            }
        }
    }

    // MARK: - Create / Rename

    private func presentNamePrompt(
        _ action: FileNamePromptAction
    ) {
        nameInput = ""

        switch action {
        case .createFile,
             .createFolder,
             .rename:
            namePrompt = FileNamePrompt(
                action: action
            )

        case .archive:
            namePrompt = FileNamePrompt(
                action: action
            )
        }
    }

    private func namePromptTitle(
        _ action: FileNamePromptAction
    ) -> String {
        switch action {
        case .createFile:
            return language.text(
                "browser.new_file"
            )
        case .createFolder:
            return language.text(
                "browser.new_folder"
            )
        case .rename:
            return language.text(
                "browser.rename"
            )
        case .archive:
            return language.text(
                "browser.create_zip"
            )
        }
    }

    private func namePromptMessage(
        _ action: FileNamePromptAction
    ) -> String {
        switch action {
        case .createFile:
            return language.text(
                "browser.enter_file_name"
            )
        case .createFolder:
            return language.text(
                "browser.enter_folder_name"
            )
        case .rename:
            return language.text(
                "browser.enter_new_name"
            )
        case .archive:
            return language.text(
                "browser.enter_archive_name"
            )
        }
    }

    private func submitNamePrompt(
        _ action: FileNamePromptAction
    ) {
        let trimmed =
            nameInput.trimmingCharacters(
                in: .whitespacesAndNewlines
            )

        guard !trimmed.isEmpty else {
            return
        }

        switch action {
        case .createFile:
            createFile(named: trimmed)

        case .createFolder:
            createFolder(named: trimmed)

        case .rename(let entry):
            rename(
                entry,
                to: trimmed
            )

        case .archive(let entries):
            archive(
                entries,
                named: trimmed
            )
        }
    }

    private func createFile(
        named name: String
    ) {
        let url =
            URL(fileURLWithPath: currentPath)
            .appendingPathComponent(name)

        do {
            try Data().write(to: url)
            load()
        } catch {
            operationNotice =
                FileReplacementNotice(
                    title: language.text(
                        "browser.create_error"
                    ),
                    message:
                        error.localizedDescription
                )
        }
    }

    private func createFolder(
        named name: String
    ) {
        let url =
            URL(fileURLWithPath: currentPath)
            .appendingPathComponent(
                name,
                isDirectory: true
            )

        do {
            try FileManager.default.createDirectory(
                at: url,
                withIntermediateDirectories: false
            )
            load()
        } catch {
            operationNotice =
                FileReplacementNotice(
                    title: language.text(
                        "browser.create_error"
                    ),
                    message:
                        error.localizedDescription
                )
        }
    }

    private func rename(
        _ entry: FileEntry,
        to name: String
    ) {
        let source =
            URL(fileURLWithPath: entry.path)
        let destination =
            URL(fileURLWithPath: currentPath)
            .appendingPathComponent(name)

        do {
            try FileManager.default.moveItem(
                at: source,
                to: destination
            )
            load()
        } catch {
            operationNotice =
                FileReplacementNotice(
                    title: language.text(
                        "browser.rename_error"
                    ),
                    message:
                        error.localizedDescription
                )
        }
    }

    // MARK: - Transfer

    private func prepareTransfer(
        _ mode: FileTransferMode,
        entries: [FileEntry]? = nil
    ) {
        let values =
            entries ??
            selectedEntries

        guard !values.isEmpty else {
            return
        }

        transferSession =
            FileTransferSession(
                mode: mode,
                sources: values.map {
                    URL(fileURLWithPath: $0.path)
                }
            )

        selectedEntryIDs.removeAll()
        isSelecting = false
    }

    private func beginPaste(
        _ payload: FileTransferPayload
    ) {
        guard !payload.urls.isEmpty else {
            fileOperationCoordinator.clear()
            return
        }

        let destinations =
            payload.urls.map {
                URL(fileURLWithPath: currentPath)
                    .appendingPathComponent(
                        $0.lastPathComponent
                    )
            }

        if let index = destinations.firstIndex(
            where: {
                FileManager.default.fileExists(
                    atPath: $0.path
                )
            }
        ) {
            transferConflict =
                FileTransferConflict(
                    sourceURL:
                        payload.urls[index],
                    destinationURL:
                        destinations[index]
                )
            transferSession =
                FileTransferSession(
                    mode: payload.mode,
                    sources: payload.urls
                )
            return
        }

        executeTransfer(
            mode: payload.mode,
            sources: payload.urls
        )
    }

    private func executeTransfer(
        mode: FileTransferMode,
        sources: [URL]
    ) {
        activityText = language.text(
            mode == .copy
                ? "browser.copying"
                : "browser.moving"
        )

        DispatchQueue.global(
            qos: .userInitiated
        ).async {
            do {
                for source in sources {
                    let destination =
                        URL(fileURLWithPath: currentPath)
                        .appendingPathComponent(
                            source.lastPathComponent
                        )

                    if mode == .copy {
                        try FileManager.default.copyItem(
                            at: source,
                            to: destination
                        )
                    } else {
                        try FileManager.default.moveItem(
                            at: source,
                            to: destination
                        )
                    }
                }

                DispatchQueue.main.async {
                    activityText = nil
                    transferSession = nil
                    transferConflict = nil
                    fileOperationCoordinator.clear()
                    load()
                }
            } catch {
                DispatchQueue.main.async {
                    activityText = nil
                    operationNotice =
                        FileReplacementNotice(
                            title: language.text(
                                mode == .copy
                                    ? "browser.copy_error"
                                    : "browser.move_error"
                            ),
                            message:
                                error.localizedDescription
                        )
                }
            }
        }
    }

    // MARK: - Archive

    private func prepareArchive(
        entries: [FileEntry]? = nil
    ) {
        let values =
            entries ??
            selectedEntries

        guard !values.isEmpty else {
            return
        }

        presentNamePrompt(
            .archive(values)
        )
    }

    private func archive(
        _ entries: [FileEntry],
        named name: String
    ) {
        let archiveName =
            name.lowercased().hasSuffix(".zip")
                ? name
                : "\(name).zip"

        let destination =
            URL(fileURLWithPath: currentPath)
                .appendingPathComponent(
                    archiveName
                )

        activityText = language.text(
            "browser.creating_zip"
        )

        DispatchQueue.global(
            qos: .userInitiated
        ).async {
            do {
                try ZIPArchiveWriter.createArchive(
                    from: entries.map {
                        URL(fileURLWithPath: $0.path)
                    },
                    to: destination
                )

                DispatchQueue.main.async {
                    activityText = nil
                    isSelecting = false
                    selectedEntryIDs.removeAll()
                    load()
                }
            } catch {
                DispatchQueue.main.async {
                    activityText = nil
                    operationNotice =
                        FileReplacementNotice(
                            title: language.text(
                                "browser.create_zip_error"
                            ),
                            message:
                                error.localizedDescription
                        )
                }
            }
        }
    }

    // MARK: - Delete

    private func prepareBulkDelete() {
        let values = selectedEntries
        guard !values.isEmpty else {
            return
        }

        deleteTargets = values
    }

    private func deleteEntries(
        _ entries: [FileEntry]
    ) {
        guard !entries.isEmpty else {
            return
        }

        activityText = language.text(
            "browser.deleting"
        )

        DispatchQueue.global(
            qos: .userInitiated
        ).async {
            do {
                for entry in entries {
                    try FileManager.default.removeItem(
                        at: URL(
                            fileURLWithPath: entry.path
                        )
                    )
                }

                DispatchQueue.main.async {
                    activityText = nil
                    isSelecting = false
                    selectedEntryIDs.removeAll()
                    load()
                }
            } catch {
                DispatchQueue.main.async {
                    activityText = nil
                    operationNotice =
                        FileReplacementNotice(
                            title: language.text(
                                "browser.delete_error"
                            ),
                            message:
                                error.localizedDescription
                        )
                }
            }
        }
    }
}

// MARK: - Models

private enum FileBrowserOverlayState: Equatable {
    case loading
    case empty
    case noResults
    case none
}

struct FileBrowserDestination:
    Hashable,
    Identifiable
{
    let id = UUID()
    let containerPath: String
    let startPath: String
    let title: String
    let bundleID: String?
}

private struct FileReplacementRequest:
    Identifiable
{
    let id = UUID()
    let source: FileEntry
    let destination: URL
}

private enum FileTransferMode {
    case copy
    case move
}

private struct FileTransferSession:
    Identifiable
{
    let id = UUID()
    let mode: FileTransferMode
    let sources: [URL]
}

private struct FileTransferPayload:
    Equatable
{
    let mode: FileTransferMode
    let urls: [URL]

    var itemCount: Int {
        urls.count
    }
}

private struct FileImportSession {
    let urls: [URL]
    let destination: URL
    let index: Int = 0

    func advancing() -> FileImportSession {
        FileImportSession(
            urls: Array(urls.dropFirst()),
            destination: destination
        )
    }
}

private struct NoticeSheet:
    View
{
    let title: String
    let message: String

    var body: some View {
        NavigationStack {
            VStack(spacing: 16) {
                Image(
                    systemName: "info.circle"
                )
                .font(.system(size: 34))
                .foregroundStyle(
                    AppTheme.accent
                )

                Text(message)
                    .multilineTextAlignment(
                        .center
                    )
                    .padding(.horizontal)

                Spacer()
            }
            .padding(.top, 32)
            .navigationTitle(title)
            .navigationBarTitleDisplayMode(
                .inline
            )
        }
        .presentationDetents(
            [.medium]
        )
    }
}

private struct FileRowContent:
    View
{
    @Environment(
        \.dynamicTypeSize
    ) private var dynamicTypeSize

    @Environment(
        \.appLanguage
    ) private var language

    let entry: FileEntry
    let selectionState: Bool?

    var body: some View {
        HStack(spacing: 12) {
            AppRowIcon(
                systemName: entry.isDirectory
                    ? "folder.fill"
                    : fileSymbol,
                tint: entry.isDirectory
                    ? .orange
                    : AppTheme.accent,
                symbolSize:
                    AppTheme.fileRowIconSize,
                frameSize:
                    AppTheme.fileRowIconFrame
            )

            VStack(
                alignment: .leading,
                spacing: 3
            ) {
                Text(entry.name)
                    .font(
                        .subheadline.weight(
                            .semibold
                        )
                    )
                    .lineLimit(
                        dynamicTypeSize.isAccessibilitySize
                            ? 2
                            : 1
                    )
                    .truncationMode(.middle)

                Text(
                    entry.isDirectory
                        ? language.text(
                            "browser.folder"
                        )
                        : entry.sizeText
                )
                .font(.caption)
                .foregroundStyle(.secondary)
            }

            Spacer(minLength: 4)

            if let selectionState {
                Image(
                    systemName:
                        selectionState
                            ? "checkmark.circle.fill"
                            : "circle"
                )
                .font(
                    .system(
                        size:
                            AppTheme.selectionIconSize,
                        weight: .medium
                    )
                )
                .foregroundStyle(
                    selectionState
                        ? AppTheme.accent
                        : Color.secondary
                )
                .accessibilityHidden(true)
            }
        }
        .contentShape(Rectangle())
        .accessibilityElement(
            children: .combine
        )
    }

    private var fileSymbol: String {
        switch entry.fileExtension
            .lowercased()
        {
        case "swift":
            return "swift"
        case "json":
            return "curlybraces"
        case "plist":
            return "list.bullet.rectangle"
        case "png", "jpg", "jpeg", "gif",
             "heic", "webp":
            return "photo"
        case "zip", "ipa":
            return "archivebox"
        case "txt", "md", "log":
            return "doc.text"
        case "framework", "dylib", "bundle":
            return "shippingbox"
        case "h", "m", "mm", "c", "cpp":
            return "chevron.left.forwardslash.chevron.right"
        default:
            return "doc"
        }
    }
}

private struct FileSelectionActionBar:
    View
{
    let selectedCount: Int
    let language: AppLanguage
    let onCopy: () -> Void
    let onMove: () -> Void
    let onArchive: () -> Void
    let onDelete: () -> Void

    var body: some View {
        HStack(spacing: 0) {
            action(
                "browser.copy",
                systemImage: "doc.on.doc",
                action: onCopy
            )

            action(
                "browser.move",
                systemImage: "folder",
                action: onMove
            )

            action(
                "browser.create_zip",
                systemImage: "archivebox",
                action: onArchive
            )

            action(
                "browser.delete",
                systemImage: "trash",
                role: .destructive,
                action: onDelete
            )
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 7)
        .background(.bar)
        .overlay(
            alignment: .top
        ) {
            Divider()
        }
        .disabled(
            selectedCount == 0
        )
    }

    private func action(
        _ key: String,
        systemImage: String,
        role: ButtonRole? = nil,
        action: @escaping () -> Void
    ) -> some View {
        Button(
            role: role,
            action: action
        ) {
            VStack(spacing: 3) {
                Image(
                    systemName: systemImage
                )
                .font(
                    .system(
                        size: 16,
                        weight: .semibold
                    )
                )

                Text(language.text(key))
                    .font(.caption2)
                    .lineLimit(1)
            }
            .frame(
                maxWidth: .infinity,
                minHeight: 34
            )
        }
        .buttonStyle(.plain)
        .foregroundStyle(
            role == .destructive
                ? Color.red
                : AppTheme.accent
        )
        .accessibilityLabel(
            language.text(key)
        )
        .accessibilityValue(
            language.text(
                "browser.selected_count",
                Int64(selectedCount)
            )
        )
    }
}

private struct FilePasteBar:
    View
{
    let itemCount: Int
    let mode: FileTransferMode
    let language: AppLanguage
    let onPaste: () -> Void
    let onCancel: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            Image(
                systemName:
                    mode == .copy
                        ? "doc.on.doc"
                        : "folder"
            )
            .foregroundStyle(
                AppTheme.accent
            )
            .frame(width: 28)

            VStack(
                alignment: .leading,
                spacing: 2
            ) {
                Text(
                    language.text(
                        mode == .copy
                            ? "browser.copy_ready"
                            : "browser.move_ready"
                    )
                )
                .font(
                    .subheadline.weight(
                        .semibold
                    )
                )

                Text(
                    language.text(
                        "browser.selected_count",
                        Int64(itemCount)
                    )
                )
                .font(.caption)
                .foregroundStyle(.secondary)
            }

            Spacer(minLength: 8)

            Button(
                language.text("common.cancel"),
                action: onCancel
            )
            .buttonStyle(.borderless)

            Button(
                language.text("browser.paste"),
                action: onPaste
            )
            .buttonStyle(.borderedProminent)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 9)
        .background(.bar)
        .overlay(
            alignment: .top
        ) {
            Divider()
        }
    }
}

extension FileBrowserView {
    init(
        containerPath: String,
        startPath: String,
        title: String,
        bundleID: String?,
        filesTabSession:
            Binding<FilesTabSession>? = nil
    ) {
        self.containerPath = containerPath
        self.title = title
        self.bundleID = bundleID
        self.isRoot = false
        self.filesTabSession = filesTabSession
        _currentPath = State(
            initialValue: startPath
        )
    }
}

struct FileQuickLookView:
    View
{
    @Environment(
        \.appLanguage
    ) private var language

    let file: FileEntry

    @State private var previewURL: URL?
    @State private var previewDirectory: URL?
    @State private var previewFailed = false

    var body: some View {
        Group {
            if let previewURL {
                FileQuickLookController(
                    url: previewURL
                )
                .ignoresSafeArea(
                    edges: .bottom
                )
            } else if previewFailed {
                VStack(spacing: 12) {
                    Image(
                        systemName:
                            "doc.questionmark"
                    )
                    .font(
                        .system(
                            size:
                                AppTheme.emptyIconSize,
                            weight: .light
                        )
                    )
                    .foregroundStyle(
                        .secondary
                    )

                    Text(
                        language.text(
                            "browser.preview_error"
                        )
                    )
                    .font(.subheadline)
                    .foregroundStyle(
                        .secondary
                    )
                    .multilineTextAlignment(
                        .center
                    )
                }
                .frame(
                    maxWidth: .infinity,
                    maxHeight: .infinity
                )
                .padding()
            } else {
                ProgressView(
                    language.text(
                        "browser.loading"
                    )
                )
                .frame(
                    maxWidth: .infinity,
                    maxHeight: .infinity
                )
            }
        }
        .navigationTitle(file.name)
        .navigationBarTitleDisplayMode(
            .inline
        )
        .toolbar {
            ToolbarItem(
                placement:
                    .navigationBarTrailing
            ) {
                if let previewURL {
                    ShareLink(
                        item: previewURL
                    ) {
                        Image(
                            systemName:
                                "square.and.arrow.up"
                        )
                    }
                }
            }
        }
        .task(id: file.id) {
            let sourceURL =
                URL(
                    fileURLWithPath:
                        file.path
                )

            let result =
                await Task.detached(
                    priority:
                        .userInitiated
                ) {
                    Result {
                        try FilePreviewService
                            .makePreviewCopy(
                                of: sourceURL
                            )
                    }
                }
                .value

            guard !Task.isCancelled else {
                if case .success(
                    let prepared
                ) = result {
                    try? FileManager.default
                        .removeItem(
                            at:
                                prepared.directoryURL
                        )
                }
                return
            }

            switch result {
            case .success(let prepared):
                previewURL =
                    prepared.fileURL
                previewDirectory =
                    prepared.directoryURL

            case .failure:
                previewFailed = true
            }
        }
        .onDisappear {
            if let previewDirectory {
                try? FileManager.default
                    .removeItem(
                        at: previewDirectory
                    )
            }

            previewURL = nil
            previewDirectory = nil
            previewFailed = false
        }
    }
}

private struct PreparedFilePreview {
    let fileURL: URL
    let directoryURL: URL
}

private enum FilePreviewService {
    static func makePreviewCopy(
        of sourceURL: URL
    ) throws -> PreparedFilePreview {
        let values =
            try sourceURL.resourceValues(
                forKeys: [
                    .isRegularFileKey,
                    .isDirectoryKey,
                    .isSymbolicLinkKey
                ]
            )

        guard values.isRegularFile == true,
              values.isDirectory != true,
              values.isSymbolicLink != true
        else {
            throw FileManagerOperationError
                .sourceMissing
        }

        let directory =
            FileManager.default
                .temporaryDirectory
                .appendingPathComponent(
                    "3105-Preview",
                    isDirectory: true
                )
                .appendingPathComponent(
                    UUID().uuidString,
                    isDirectory: true
                )

        let destination =
            directory.appendingPathComponent(
                sourceURL.lastPathComponent
            )

        do {
            try FileManager.default
                .createDirectory(
                    at: directory,
                    withIntermediateDirectories:
                        true
                )

            try FileManager.default
                .copyItem(
                    at: sourceURL,
                    to: destination
                )

            return PreparedFilePreview(
                fileURL: destination,
                directoryURL: directory
            )
        } catch {
            try? FileManager.default
                .removeItem(
                    at: directory
                )
            throw error
        }
    }
}

private struct FileQuickLookController:
    UIViewControllerRepresentable
{
    let url: URL

    func makeCoordinator() -> Coordinator {
        Coordinator(url: url)
    }

    func makeUIViewController(
        context: Context
    ) -> QLPreviewController {
        let controller =
            QLPreviewController()

        controller.dataSource =
            context.coordinator

        return controller
    }

    func updateUIViewController(
        _ controller: QLPreviewController,
        context: Context
    ) {
        if context.coordinator.url != url {
            context.coordinator.url = url
            controller.reloadData()
        }
    }

    final class Coordinator:
        NSObject,
        QLPreviewControllerDataSource
    {
        var url: URL

        init(url: URL) {
            self.url = url
        }

        func numberOfPreviewItems(
            in controller: QLPreviewController
        ) -> Int {
            1
        }

        func previewController(
            _ controller: QLPreviewController,
            previewItemAt index: Int
        ) -> any QLPreviewItem {
            url as NSURL
        }
    }
}