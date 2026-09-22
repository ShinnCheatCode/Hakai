import SwiftUI

struct FolderPatchSelectionView: View {
    @Environment(\.appLanguage) private var language
    @Environment(\.dismiss) private var dismiss
    let containerRoot: URL
    let folder: URL
    let onCreate: ([PatchDraftCandidate]) -> Void

    @State private var candidates: [PatchDraftCandidate] = []
    @State private var selectedIDs = Set<String>()
    @State private var isLoading = true
    @State private var validationMessageKey: String?

    private var selectedCandidates: [PatchDraftCandidate] {
        candidates.filter { selectedIDs.contains($0.id) }
    }

    var body: some View {
        NavigationStack {
            Group {
                if isLoading {
                    ProgressView(language.text("patch.folder_scanning"))
                } else if candidates.isEmpty {
                    VStack(spacing: 10) {
                        Image(systemName: "folder")
                            .font(.system(size: AppTheme.emptyIconSize, weight: .light))
                            .foregroundStyle(.secondary)
                        Text(language.text("patch.folder_empty"))
                            .font(.headline)
                        Text(language.text("patch.folder_empty_message"))
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding()
                } else {
                    fileList
                }
            }
            .navigationTitle(language.text("patch.select_files"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(language.text("common.cancel")) { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(language.text("patch.add_selected")) {
                        let selection = selectedCandidates
                        dismiss()
                        onCreate(selection)
                    }
                    .disabled(selectedIDs.isEmpty)
                }
                ToolbarItemGroup(placement: .bottomBar) {
                    Button(selectionActionTitle, action: toggleAll)
                }
            }
            .task { loadCandidates() }
        }
    }

    private var fileList: some View {
        List {
            if let validationMessageKey {
                Section {
                    Label(
                        language.text(validationMessageKey),
                        systemImage: "exclamationmark.triangle.fill"
                    )
                    .font(.subheadline)
                    .foregroundStyle(.red)
                }
            }

            Section {
                ForEach(candidates) { candidate in
                    Button {
                        toggle(candidate)
                    } label: {
                        HStack(spacing: 12) {
                            Image(systemName: "doc.fill")
                                .foregroundStyle(AppTheme.accent)
                                .frame(width: 24)
                            VStack(alignment: .leading, spacing: 3) {
                                Text(candidate.url.lastPathComponent)
                                    .font(.subheadline.weight(.medium))
                                    .foregroundStyle(.primary)
                                    .lineLimit(1)
                                Text(candidate.relativePath)
                                    .font(.caption2.monospaced())
                                    .foregroundStyle(.secondary)
                                    .lineLimit(2)
                            }
                            Spacer(minLength: 8)
                            VStack(alignment: .trailing, spacing: 5) {
                                Image(systemName: selectedIDs.contains(candidate.id)
                                      ? "checkmark.circle.fill"
                                      : "circle")
                                    .foregroundStyle(selected