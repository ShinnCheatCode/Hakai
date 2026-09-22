import Foundation
import Darwin

enum FileManagerOperationError: Error, Equatable, LocalizedError {
    case invalidName
    case nameTooLong
    case itemAlreadyExists
    case sourceMissing
    case destinationMissing
    case sourceIsDirectory
    case destinationIsDirectory
    case destinationNotDirectory
    case symbolicLinkUnsupported
    case recursiveDestination
    case sourceTooLarge
    case cannotCreate
    case cannotRename
    case cannotDelete
    case cannotImport
    case cannotCopy
    case cannotMove
    case cannotArchive
    case cannotExtract
    case unsafeArchive
    case insufficientSpace

    var errorDescription: String? {
        switch self {
        case .invalidName: return "Enter a valid file or folder name."
        case .nameTooLong: return "The name is too long."
        case .itemAlreadyExists: return "An item with this name already exists."
        case .sourceMissing: return "The selected source file is unavailable."
        case .destinationMissing: return "The destination no longer exists."
        case .sourceIsDirectory: return "Select a file, not a folder."
        case .destinationIsDirectory: return "A folder with this name already exists."
        case .destinationNotDirectory: return "The destination is not a folder."
        case .symbolicLinkUnsupported: return "Symbolic links are not supported."
        case .recursiveDestination: return "A folder cannot be copied or moved into itself."
        case .sourceTooLarge: return "The selected file is too large."
        case .cannotCreate: return "The item could not be created."
        case .cannotRename: return "The item could not be renamed."
        case .cannotDelete: return "The item could not be deleted."
        case .cannotImport: return "The file could not be imported safely."
        case .cannotCopy: return "The selected items could not be copied."
        case .cannotMove: return "The selected items could not be moved."
        case .cannotArchive: return "The ZIP archive could not be created."
        case .cannotExtract: return "The ZIP archive could not be extracted."
        case .unsafeArchive: return "The ZIP archive contains unsafe or unsupported entries."
        case .insufficientSpace: return "There is not enough free space to extract this archive."
        }
    }
}

enum FileTransferMode: Equatable {
    case copy
    case move
}

enum FileConflictPolicy: Equatable {
    case fail
    case replace
    case keepBoth
}

enum FileTransferDisposition: Equatable {
    case copied
    case moved
    case replaced
    case renamed
}

struct FileTransferResult: Equatable {
    let sourceURL: URL
    let destinationURL: URL
    let disposition: FileTransferDisposition
}

struct FileArchiveResult: Equatable {
    let archiveURL: URL
    let entryCount: Int
    let sourceBytes: Int64
}

enum FileImportDisposition: Equatable {
    case imported
    case replaced
}

struct FileImportResult: Equatable {
    let destinationURL: URL
    let byteCount: Int64
    let disposition: FileImportDisposition
}

struct FileImportSession: Equatable {
    let destinationDirectory: URL
    private(set) var pendingSourceURLs: [URL]
    private(set) var replaceAll = false
    private(set) var importedCount = 0
    private(set) var replacedCount = 0
    private(set) var failedCount = 0
    private(set) var isCancelled = false

    init(destinationDirectory: URL, sourceURLs: [URL]) {
        self.destinationDirectory = destinationDirectory
        self.pendingSourceURLs = sourceURLs
    }

    var isComplete: Bool { pendingSourceURLs.isEmpty }

    mutating func takeNext() -> URL? {
        guard !pendingSourceURLs.isEmpty else { return nil }
        return pendingSourceURLs.removeFirst()
    }

    mutating func enableReplaceAll() {
        replaceAll = true
    }

    mutating func record(_ disposition: FileImportDisposition) {
        switch disposition {
        case .imported: importedCount += 1
        case .replaced: replacedCount += 1
        }
    }

    mutating func recordFailure() {
        failedCount += 1
    }

    mutating func cancel() {
        pendingSourceURLs.removeAll()
        isCancelled = true
    }
}

enum FileManagerService {
    private static let maximumNameByteCount = 255
    private static let copyChunkSize = 1_024 * 1_024

    static func validatedName(_ rawName: String) throws -> String {
        let name = rawName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !name.isEmpty,
              name != ".",
              name != "..",
              !name.contains("/"),
              !name.unicodeScalars.contains(where: CharacterSet.controlCharacters.contains) else {
            throw FileManagerOperationError.invalidName
        }
        guard name.lengthOfBytes(using: .utf8) <= maximumNameByteCount else {
            throw FileManagerOperationError.nameTooLong
        }
        return name
    }

    static func destinationURL(
        named rawName: String,
        in directoryURL: URL,
        fileManager: FileManager = .default
    ) throws -> URL {
        try validateDirectory(directoryURL, fileManager: fileManager)
        let name = try validatedName(rawName)
        return directoryURL.appendingPathComponent(name, isDirectory: false)
    }

    static func createFile(
        named rawName: String,
        in directoryURL: URL,
        fileManager: FileManager = .default
    ) throws -> URL {
        let destinationURL = try destinationURL(
            named: rawName,
            in: directoryURL,
            fileManager: fileManager
        )
        guard !fileManager.fileExists(atPath: destinationURL.path) else {
            throw FileManagerOperationError.itemAlreadyExists
        }
        try createExclusiveFile(
            at: destinationURL,
            existingError: .itemAlreadyExists,
            failureError: .cannotCreate
        )
        return destinationURL
    }

    static func createFolder(
        named rawName: String,
        in directoryURL: URL,
        fileManager: FileManager = .default
    ) throws -> URL {
        let destinationURL = try destinationURL(
            named: rawName,
            in: directoryURL,
            fileManager: fileManager
        )
        guard !fileManager.fileExists(atPath: destinationURL.path) else {
            throw FileManagerOperationError.itemAlreadyExists
        }
        do {
            try fileManager.createDirectory(
                at: destinationURL,
                withIntermediateDirectories: false
            )
            return destinationURL
        } catch {
            throw FileManagerOperationError.cannotCreate
        }
    }

    static func renameItem(
        at sourceURL: URL,
        to rawName: String,
        fileManager: FileManager = .default
    ) throws -> URL {
        let sourceValues = try values(
            for: sourceURL,
            missingError: .sourceMissing,
            fileManager: fileManager
        )
        guard sourceValues.isSymbolicLink != true else {
            throw FileManagerOperationError.symbolicLinkUnsupported
        }
        let destinationURL = try destinationURL(
            named: rawName,
            in: sourceURL.deletingLastPathComponent(),
            fileManager: fileManager
        )
        if destinationURL.standardizedFileURL == sourceURL.standardizedFileURL {
            return sourceURL
        }
        guard !fileManager.fileExists(atPath: destinationURL.path) else {
            throw FileManagerOperationError.itemAlreadyExists
        }
        do {
            try fileManager.moveItem(at: sourceURL, to: destinationURL)
            return destinationURL
        } catch {
            throw FileManagerOperationError.cannotRename
        }
    }

    static func deleteItem(
        at itemURL: URL,
        fileManager: FileManager = .default
    ) throws {
        let itemValues = try values(
            for: itemURL,
            missingError: .sourceMissing,
            fileManager: fileManager
        )
        guard itemValues.isSymbolicLink != true else {
            throw FileManagerOperationError.symbolicLinkUnsupported
        }
        do {
            try fileManager.removeItem(at: itemURL)
        } catch {
            throw FileManagerOperationError.cannotDelete
        }
    }

    static func transferItem(
        at sourceURL: URL,
        into directoryURL: URL,
        mode: FileTransferMode,
        conflictPolicy: FileConflictPolicy,
        fileManager: FileManager = .default
    ) throws -> FileTransferResult {
        let source = sourceURL.standardizedFileURL
        let destinationDirectory = directoryURL.standardizedFileURL
        let sourceValues = try values(
            for: source,
            missingError: .sourceMissing,
            fileManager: fileManager
        )
        guard sourceValues.isSymbolicLink != true else {
            throw FileManagerOperationError.symbolicLinkUnsupported
        }
        try validateDirectory(destinationDirectory, fileManager: fileManager)
        try validateNoSymbolicLinks(in: source, fileManager: fileManager)

        if sourceValues.isDirectory == true {
            let sourcePath = source.path.hasSuffix("/") ? source.path : source.path + "/"
            let destinationPath = destinationDirectory.path.hasSuffix("/")
                ? destinationDirectory.path
                : destinationDirectory.path + "/"
            guard destinationDirectory.path != source.path,
                  !destinationPath.hasPrefix(sourcePath) else {
                throw FileManagerOperationError.recursiveDestination
            }
        }

        let requestedDestination = destinationDirectory.appendingPathComponent(
            source.lastPathComponent,
            isDirectory: sourceValues.isDirectory == true
        )
        if mode == .move,
           source.standardizedFileURL == requestedDestination.standardizedFileURL {
            return FileTransferResult(
                sourceURL: source,
                destinationURL: requestedDestination,
                disposition: .moved
            )
        }

        var destination = requestedDestination
        var disposition: FileTransferDisposition = mode == .copy ? .copied : .moved

        if fileManager.fileExists(atPath: destination.path) {
            switch conflictPolicy {
            case .fail:
                throw FileManagerOperationError.itemAlreadyExists
            case .replace:
                try deleteItem(at: destination, fileManager: fileManager)
                disposition = .replaced
            case .keepBoth:
                destination = uniqueDestinationURL(
                    for: destination,
                    isDirectory: sourceValues.isDirectory == true,
                    fileManager: fileManager
                )
                disposition = .renamed
            }
        }

        do {
            switch mode {
            case .copy:
                try fileManager.copyItem(at: source, to: destination)
            case .move:
                try fileManager.moveItem(at: source, to: destination)
            }
        } catch {
            switch mode {
            case .copy: throw FileManagerOperationError.cannotCopy
            case .move: throw FileManagerOperationError.cannotMove
            }
        }

        return FileTransferResult(
            sourceURL: source,
            destinationURL: destination,
            disposition: disposition
        )
    }

    static func importFile(
        from sourceURL: URL,
        into directoryURL: URL,
        conflictPolicy: FileConflictPolicy = .fail,
        fileManager: FileManager = .default
    ) throws -> FileImportResult {
        let sourceValues = try values(
            for: sourceURL,
            missingError: .sourceMissing,
            fileManager: fileManager
        )
        guard sourceValues.isSymbolicLink != true else {
            throw FileManagerOperationError.symbolicLinkUnsupported
        }
        guard sourceValues.isDirectory != true else {
            throw FileManagerOperationError.sourceIsDirectory
        }
        try validateDirectory(directoryURL, fileManager: fileManager)

        let originalDestination = directoryURL.appendingPathComponent(sourceURL.lastPathComponent)
        var destination = originalDestination
        var disposition: FileImportDisposition = .imported

        if fileManager.fileExists(atPath: destination.path) {
            switch conflictPolicy {
            case .fail:
                throw FileManagerOperationError.itemAlreadyExists
            case .replace:
                disposition = .replaced
            case .keepBoth:
                destination = uniqueDestinationURL(
                    for: destination,
                    isDirectory: false,
                    fileManager: fileManager
                )
            }
        }

        let stagingURL = directoryURL.appendingPathComponent(
            ".3105-import-\(UUID().uuidString)"
        )
        let byteCount = try copyToStaging(
            sourceURL: sourceURL,
            stagingURL: stagingURL,
            fileManager: fileManager
        )
        defer { try? fileManager.removeItem(at: stagingURL) }

        if disposition == .replaced {
            try deleteItem(at: destination, fileManager: fileManager)
        }

        do {
            try fileManager.moveItem(at: stagingURL, to: destination)
        } catch {
            throw FileManagerOperationError.cannotImport
        }

        return FileImportResult(
            destinationURL: destination,
            byteCount: byteCount,
            disposition: disposition
        )
    }

    static func copyToStaging(
        sourceURL: URL,
        stagingURL: URL,
        fileManager: FileManager = .default
    ) throws -> Int64 {
        let sourceValues = try values(
            for: sourceURL,
            missingError: .sourceMissing,
            fileManager: fileManager
        )
        guard sourceValues.isSymbolicLink != true else {
            throw FileManagerOperationError.symbolicLinkUnsupported
        }
        guard sourceValues.isDirectory != true else {
            throw FileManagerOperationError.sourceIsDirectory
        }
        guard !fileManager.fileExists(atPath: stagingURL.path) else {
            throw FileManagerOperationError.itemAlreadyExists
        }

        do {
            guard fileManager.createFile(atPath: stagingURL.path, contents: nil) else {
                throw FileManagerOperationError.cannotImport
            }
            let source = try FileHandle(forReadingFrom: sourceURL)
            let staging = try FileHandle(forWritingTo: stagingURL)
            defer {
                try? source.close()
                try? staging.close()
            }
            var copiedByteCount: Int64 = 0
            while let data = try source.read(upToCount: copyChunkSize), !data.isEmpty {
                let (nextCount, overflow) = copiedByteCount.addingReportingOverflow(Int64(data.count))
                guard !overflow else {
                    throw FileManagerOperationError.sourceTooLarge
                }
                copiedByteCount = nextCount
                try staging.write(contentsOf: data)
            }
            try staging.synchronize()
            return copiedByteCount
        } catch let error as FileManagerOperationError {
            throw error
        } catch {
            throw FileManagerOperationError.cannotImport
        }
    }

    private static func createExclusiveFile(
        at url: URL,
        existingError: FileManagerOperationError,
        failureError: FileManagerOperationError
    ) throws {
        let descriptor = open(
            url.path,
            O_WRONLY | O_CREAT | O_EXCL,
            S_IRUSR | S_IWUSR
        )
        guard descriptor >= 0 else {
            if errno == EEXIST { throw existingError }
            throw failureError
        }
        guard close(descriptor) == 0 else {
            try? FileManager.default.removeItem(at: url)
            throw failureError
        }
    }

    private static func validateDirectory(
        _ directoryURL: URL,
        fileManager: FileManager
    ) throws {
        guard fileManager.fileExists(atPath: directoryURL.path) else {
            throw FileManagerOperationError.destinationMissing
        }
        let values = try directoryURL.resourceValues(forKeys: [.isDirectoryKey, .isSymbolicLinkKey])
        guard values.isDirectory == true else {
            throw FileManagerOperationError.destinationNotDirectory
        }
        guard values.isSymbolicLink != true else {
            throw FileManagerOperationError.symbolicLinkUnsupported
        }
    }

    private static func values(
        for url: URL,
        missingError: FileManagerOperationError,
        fileManager: FileManager
    ) throws -> URLResourceValues {
        guard fileManager.fileExists(atPath: url.path) else {
            throw missingError
        }
        do {
            return try url.resourceValues(
                forKeys: [.isDirectoryKey, .isSymbolicLinkKey, .fileSizeKey]
            )
        } catch {
            throw missingError
        }
    }

    private static func validateNoSymbolicLinks(
        in root: URL,
        fileManager: FileManager
    ) throws {
        let values = try root.resourceValues(forKeys: [.isSymbolicLinkKey, .isDirectoryKey])
        guard values.isSymbolicLink != true else {
            throw FileManagerOperationError.symbolicLinkUnsupported
        }
        guard values.isDirectory == true else { return }

        guard let enumerator = fileManager.enumerator(
            at: root,
            includingPropertiesForKeys: [.isSymbolicLinkKey, .isDirectoryKey],
            options: [.skipsHiddenFiles]
        ) else {
            return
        }

        for case let url as URL in enumerator {
            let values = try url.resourceValues(
                forKeys: [.isSymbolicLinkKey, .isDirectoryKey]
            )
            if values.isSymbolicLink == true {
                throw FileManagerOperationError.symbolicLinkUnsupported
            }
        }
    }

    private static func uniqueDestinationURL(
        for requestedURL: URL,
        isDirectory: Bool,
        fileManager: FileManager
    ) -> URL {
        let baseName = requestedURL.deletingPathExtension().lastPathComponent
        let ext = requestedURL.pathExtension
        let parent = requestedURL.deletingLastPathComponent()

        var index = 1
        while true {
            let suffix = index == 1 ? " copy" : " copy \(index)"
            let name = ext.isEmpty
                ? baseName + suffix
                : baseName + suffix + "." + ext
            let candidate = parent.appendingPathComponent(name, isDirectory: isDirectory)
            if !fileManager.fileExists(atPath: candidate.path) {
                return candidate
            }
            index += 1
        }
    }
}