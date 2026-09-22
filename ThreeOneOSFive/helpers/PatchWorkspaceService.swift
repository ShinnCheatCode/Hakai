import Foundation

enum PatchWorkspaceService {
    private struct Manifest: Codable {
        let schemaVersion: Int
        let projectID: UUID
        var displayName: String
    }

    private static let manifestFilename = ".3105-project.plist"
    private static let manifestSchemaVersion = 1

    static func documentsRootURL(fileManager: FileManager = .default) throws -> URL {
        try fileManager.url(
            for: .documentDirectory,
            in: .userDomainMask,
            appropriateFor: nil,
            create: true
        )
    }

    static func patchesRootURL(fileManager: FileManager = .default) throws -> URL {
        let documents = try documentsRootURL(fileManager: fileManager)
        let root = documents.appendingPathComponent("Patches", isDirectory: true)
        try fileManager.createDirectory(at: root, withIntermediateDirectories: true)
        return root
    }

    static func createWorkspace(
        for project: PatchProject,
        patchesRoot: URL? = nil,
        fileManager: FileManager = .default
    ) throws -> URL {
        try PatchPackageCodec.validate(project)
        let root = try patchesRoot ?? patchesRootURL(fileManager: fileManager)
        try fileManager.createDirectory(at: root, withIntermediateDirectories: true)
        if let existing = workspaceURL(
            projectID: project.id,
            patchesRoot: root,
            fileManager: fileManager
        ) {
            return existing
        }

        let destination = uniqueWorkspaceURL(
            named: project.name,
            in: root,
            fileManager: fileManager
        )
        let staging = root.appendingPathComponent(
            ".3105-workspace-\(UUID().uuidString)",
            isDirectory: true
        )
        defer { try? fileManager.removeItem(at: staging) }

        do {
            try fileManager.createDirectory(at: staging, withIntermediateDirectories: false)
            for bundleID in project.allBundleIdentifiers {
                let canonical = try PatchPathValidator.canonicalBundleIdentifier(bundleID)
                guard canonical == bundleID else { throw PatchPackageError.invalidProject }
                try fileManager.createDirectory(
                    at: staging.appendingPathComponent(bundleID, isDirectory: true),
                    withIntermediateDirectories: false
                )
            }
            for directory in project.directories {
                let target = try workspaceTarget(
                    bundleID: directory.bundleID,
                    relativePath: directory.relativePath,
                    workspaceRoot: staging,
                    isDirectory: true
                )
                try fileManager.createDirectory(at: target, withIntermediateDirectories: true)
            }
            for rule in project.rules {
                let target = try workspaceTarget(
                    bundleID: rule.bundleID,
                    relativePath: rule.relativePath,
                    workspaceRoot: staging,
                    isDirectory: false
                )
                try fileManager.createDirectory(
                    at: target.deletingLastPathComponent(),
                    withIntermediateDirectories: true
                )
                guard !fileManager.fileExists(atPath: target.path) else {
                    throw PatchPackageError.duplicateTarget
                }
                try rule.replacementData.write(to: target, options: [.atomic, .completeFileProtection])
            }
            try writeManifest(
                Manifest(
                    schemaVersion: manifestSchemaVersion,
                    projectID: project.id,
                    displayName: project.name
                ),
                workspaceURL: staging
            )
            try fileManager.moveItem(at: staging, to: destination)
            return destination
        } catch let error as PatchPackageError {
            throw error
        } catch {
            throw PatchPackageError.invalidProject
        }
    }

    static func ensureWorkspace(
        for project: PatchProject,
        patchesRoot: URL? = nil,
        fileManager: FileManager = .default
    ) throws -> URL {
        let root = try patchesRoot ?? patchesRootURL(fileManager: fileManager)
        if let existing = workspaceURL(
            projectID: project.id,
            patchesRoot: root,
            fileManager: fileManager
        ) {
            return existing
        }
        return try createWorkspace(for: project, patchesRoot: root, fileManager: fileManager)
    }

    static func replaceWorkspace(
        with project: PatchProject,
        patchesRoot: URL? = nil,
        fileManager: FileManager = .default
    ) throws -> URL {
        let root = try patchesRoot ?? patchesRootURL(fileManager: fileManager)
        let existing = workspaceURL(
            projectID: project.id,
            patchesRoot: root,
            fileManager: fileManager
        )
        let displaced = root.appendingPathComponent(
            ".3105-displaced-workspace-\(UUID().uuidString)",
            isDirectory: true
        )

        if let existing {
            try fileManager.moveItem(at: existing, to: displaced)
        }
        do {
            let replacement = try createWorkspace(
                for: project,
                patchesRoot: root,
                fileManager: fileManager
            )
            if fileManager.fileExists(atPath: displaced.path) {
                try fileManager.removeItem(at: displaced)
            }
            return replacement
        } catch {
            if let replacement = workspaceURL(
                projectID: project.id,
                patchesRoot: root,
                fileManager: fileManager
            ) {
                try? fileManager.removeItem(at: replacement)
            }
            if let existing, fileManager.fileExists(atPath: displaced.path) {
                try? fileManager.moveItem(at: displaced, to: existing)
            }
            throw error
        }
    }

    static func workspaceURL(
        projectID: UUID,
        patchesRoot: URL? = nil,
        fileManager: FileManager = .default
    ) -> URL? {
        guard let root = try? patchesRoot ?? patchesRootURL(fileManager: fileManager),
              let candidates = try? fileManager.contentsOfDirectory(
                at: root,
                includingPropertiesForKeys: [.isDirectoryKey, .isSymbolicLinkKey],
                options: [.skipsHiddenFiles]
              ) else { return nil }

        for candidate in candidates {
            guard let values = try? candidate.resourceValues(
                forKeys: [.isDirectoryKey, .isSymbolicLinkKey]
            ), values.isDirectory == true, values.isSymbolicLink != true,
                  let manifest = try? readManifest(workspaceURL: candidate),
                  manifest.schemaVersion == manifestSchemaVersion,
                  manifest.projectID == projectID else { continue }
            return candidate
        }
        return nil
    }

    static func snapshot(
        baseProject: PatchProject,
        workspaceURL: URL,
        fileManager: FileManager = .default
    ) throws -> PatchProject {
        let root = workspaceURL.standardizedFileURL
        let rootValues = try root.resourceValues(
            forKeys: [.isDirectoryKey, .isSymbolicLinkKey]
        )
        guard rootValues.isDirectory == true, rootValues.isSymbolicLink != true else {
            throw PatchPackageError.invalidProject
        }
        let manifest = try readManifest(workspaceURL: root)
        guard manifest.schemaVersion == manifestSchemaVersion,
              manifest.projectID == baseProject.id else {
            throw PatchPackageError.invalidProject
        }

        let oldRuleIDs = Dictionary(uniqueKeysWithValues: baseProject.rules.map {
            (targetKey(bundleID: $0.bundleID, relativePath: $0.relativePath), $0.id)
        })
        let oldDirectoryIDs = Dictionary(uniqueKeysWithValues: baseProject.directories.map {
            (targetKey(bundleID: $0.bundleID, relativePath: $0.relativePath), $0.id)
        })

        let topLevel = try fileManager.contentsOfDirectory(
            at: root,
            includingPropertiesForKeys: [
                .isDirectoryKey,
                .isRegularFileKey,
                .isSymbolicLinkKey
            ],
            options: []
        ).filter { $0.lastPathComponent != manifestFilename }

        var discoveredBundles: [String] = []
        var directories: [PatchDirectory] = []
        var rules: [PatchRule] = []
        for bundleURL in topLevel.sorted(by: { $0.lastPathComponent < $1.lastPathComponent }) {
            let values = try bundleURL.resourceValues(
                forKeys: [.isDirectoryKey, .isRegularFileKey, .isSymbolicLinkKey]
            )
            guard values.isDirectory == true,
                  values.isSymbolicLink != true,
                  values.isRegularFile != true else {
                throw PatchPackageError.invalidProject
            }
            let bundleID = try PatchPathValidator.canonicalBundleIdentifier(bundleURL.lastPathComponent)
            guard bundleID == bundleURL.lastPathComponent else {
                throw PatchPackageError.invalidBundleIdentifier
            }
            discoveredBundles.append(bundleID)

            var enumerationFailed = false
            guard let enumerator = fileManager.enumerator(
                at: bundleURL,
                includingPropertiesForKeys: [
                    .isDirectoryKey,
                    .isRegularFileKey,
                    .isSymbolicLinkKey
                ],
                options: [],
                errorHandler: { _, _ in
                    enumerationFailed = true
                    return false
                }
            ) else {
                throw PatchPackageError.invalidProject
            }

            while let item = enumerator.nextObject() as? URL {
                let itemValues = try item.resourceValues(
                    forKeys: [.isDirectoryKey, .isRegularFileKey, .isSymbolicLinkKey]
                )
                guard itemValues.isSymbolicLink != true else {
                    throw PatchPackageError.symbolicLinkUnsupported
                }

                let relativePath = try relativePath(
                    from: bundleURL,
                    to: item,
                    fileManager: fileManager
                )
                if itemValues.isDirectory == true {
                    directories.append(PatchDirectory(
                        id: oldDirectoryIDs[targetKey(
                            bundleID: bundleID,
                            relativePath: relativePath
                        )] ?? UUID(),
                        bundleID: bundleID,
                        relativePath: relativePath
                    ))
                } else if itemValues.isRegularFile == true {
                    let data = try Data(contentsOf: item, options: .mappedIfSafe)
                    rules.append(PatchRule(
                        id: oldRuleIDs[targetKey(
                            bundleID: bundleID,
                            relativePath: relativePath
                        )] ?? UUID(),
                        bundleID: bundleID,
                        relativePath: relativePath,
                        replacementFilename: item.lastPathComponent,
                        replacementData: data
                    ))
                } else {
                    throw PatchPackageError.invalidProject
                }
            }
            guard !enumerationFailed else {
                throw PatchPackageError.invalidProject
            }
        }

        var updated = baseProject
        updated.updatedAt = Date()
        updated.bundleIdentifiers = discoveredBundles
        updated.directories = directories.sorted {
            targetKey(bundleID: $0.bundleID, relativePath: $0.relativePath)
                < targetKey(bundleID: $1.bundleID, relativePath: $1.relativePath)
        }
        updated.rules = rules.sorted {
            targetKey(bundleID: $0.bundleID, relativePath: $0.relativePath)
                < targetKey(bundleID: $1.bundleID, relativePath: $1.relativePath)
        }
        try PatchPackageCodec.validate(updated)
        return updated
    }

    static func deleteWorkspace(
        projectID: UUID,
        patchesRoot: URL? = nil,
        fileManager: FileManager = .default
    ) throws {
        guard let workspace = workspaceURL(
            projectID: projectID,
            patchesRoot: patchesRoot,
            fileManager: fileManager
        ) else {
            return
        }
        try fileManager.removeItem(at: workspace)
    }

    private static func workspaceTarget(
        bundleID: String,
        relativePath: String,
        workspaceRoot: URL,
        isDirectory: Bool
    ) throws -> URL {
        let canonicalBundleID = try PatchPathValidator.canonicalBundleIdentifier(bundleID)
        guard canonicalBundleID == bundleID else {
            throw PatchPackageError.invalidBundleIdentifier
        }
        let canonicalPath = try PatchPathValidator.canonicalRelativePath(relativePath)
        let bundleRoot = workspaceRoot.appendingPathComponent(
            canonicalBundleID,
            isDirectory: true
        )
        let target = bundleRoot.appendingPathComponent(
            canonicalPath,
            isDirectory: isDirectory
        ).standardizedFileURL
        guard target.path.hasPrefix(bundleRoot.standardizedFileURL.path + "/") else {
            throw PatchPackageError.unsafeTargetPath
        }
        return target
    }

    private static func relativePath(
        from bundleRoot: URL,
        to item: URL,
        fileManager: FileManager
    ) throws -> String {
        let root = bundleRoot.standardizedFileURL
        let target = item.standardizedFileURL
        guard target.path.hasPrefix(root.path + "/") else {
            throw PatchPackageError.unsafeTargetPath
        }

        let relative = String(target.path.dropFirst(root.path.count + 1))
        try PatchPathValidator.canonicalRelativePath(relative)
        try rejectSymbolicLinks(
            relativePath: relative,
            bundleRoot: root,
            fileManager: fileManager
        )
        return relative
    }

    private static func rejectSymbolicLinks(
        relativePath: String,
        bundleRoot: URL,
        fileManager: FileManager
    ) throws {
        var cursor = bundleRoot
        for component in relativePath.split(separator: "/") {
            cursor.appendPathComponent(String(component))
            guard fileManager.fileExists(atPath: cursor.path) else {
                throw PatchPackageError.invalidProject
            }
            let values = try cursor.resourceValues(forKeys: [.isSymbolicLinkKey])
            guard values.isSymbolicLink != true else {
                throw PatchPackageError.symbolicLinkUnsupported
            }
        }
    }

    private static func writeManifest(
        _ manifest: Manifest,
        workspaceURL: URL
    ) throws {
        let url = workspaceURL.appendingPathComponent(manifestFilename)
        let encoder = PropertyListEncoder()
        encoder.outputFormat = .binary
        try encoder.encode(manifest).write(to: url, options: .atomic)
    }

    private static func readManifest(workspaceURL: URL) throws -> Manifest {
        let url = workspaceURL.appendingPathComponent(manifestFilename)
        return try PropertyListDecoder().decode(
            Manifest.self,
            from: Data(contentsOf: url)
        )
    }

    private static func uniqueWorkspaceURL(
        named rawName: String,
        in root: URL,
        fileManager: FileManager
    ) -> URL {
        let base = sanitizedName(rawName)
        var candidate = root.appendingPathComponent(base, isDirectory: true)
        var suffix = 2
        while fileManager.fileExists(atPath: candidate.path) {
            candidate = root.appendingPathComponent(
                "\(base)-\(suffix)",
                isDirectory: true
            )
            suffix += 1
        }
        return candidate
    }

    private static func sanitizedName(_ rawName: String) -> String {
        let allowed = CharacterSet.alphanumerics.union(
            CharacterSet(charactersIn: "-_ ")
        )
        let value = rawName.unicodeScalars.map {
            allowed.contains($0) ? Character(String($0)) : "-"
        }
        let name = String(value)
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .prefix(80)
        return name.isEmpty ? "Patch" : String(name)
    }

    private static func targetKey(
        bundleID: String,
        relativePath: String
    ) -> String {
        "\(bundleID)\0\(relativePath)"
    }
}