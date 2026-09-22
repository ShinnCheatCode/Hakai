import Foundation
import Compression

enum SecureZIPArchiveError: Error {
    case invalidArchive
    case unsupportedArchive
    case invalidEntry
    case pathTraversal
    case unsupportedCompressionMethod
    case decompressionFailed
    case compressionFailed
    case sizeLimitExceeded
    case checksumMismatch
}

struct SecureZIPArchiveEntry {
    let path: String
    let data: Data
    let isDirectory: Bool
}

enum SecureZIPArchive {
    private static let localHeaderSignature: UInt32 = 0x04034b50
    private static let centralHeaderSignature: UInt32 = 0x02014b50
    private static let endOfCentralDirectorySignature: UInt32 = 0x06054b50

    private static let maximumEntryCount = 10_000
    private static let maximumEntrySize: UInt64 = 512 * 1024 * 1024
    private static let maximumArchiveSize: UInt64 = 1024 * 1024 * 1024

    static func extract(
        data: Data,
        fileManager: FileManager = .default
    ) throws -> [SecureZIPArchiveEntry] {
        guard UInt64(data.count) <= maximumArchiveSize else {
            throw SecureZIPArchiveError.sizeLimitExceeded
        }

        let entries = try centralDirectoryEntries(data)
        guard entries.count <= maximumEntryCount else {
            throw SecureZIPArchiveError.sizeLimitExceeded
        }

        return try entries.map { entry in
            let normalizedPath = try normalizePath(entry.path)
            if entry.isDirectory {
                return SecureZIPArchiveEntry(
                    path: normalizedPath,
                    data: Data(),
                    isDirectory: true
                )
            }

            guard entry.uncompressedSize <= maximumEntrySize else {
                throw SecureZIPArchiveError.sizeLimitExceeded
            }

            let compressed = try localEntryData(data, entry: entry)
            let decoded: Data
            switch entry.compressionMethod {
            case 0:
                decoded = compressed
            case 8:
                decoded = try inflate(
                    compressed,
                    expectedSize: entry.uncompressedSize
                )
            default:
                throw SecureZIPArchiveError.unsupportedCompressionMethod
            }

            guard UInt64(decoded.count) == entry.uncompressedSize else {
                throw SecureZIPArchiveError.decompressionFailed
            }

            guard crc32(decoded) == entry.crc32 else {
                throw SecureZIPArchiveError.checksumMismatch
            }

            return SecureZIPArchiveEntry(
                path: normalizedPath,
                data: decoded,
                isDirectory: false
            )
        }
    }

    static func extract(
        data: Data,
        to destination: URL,
        fileManager: FileManager = .default
    ) throws {
        let root = destination.standardizedFileURL
        let values = try? root.resourceValues(
            forKeys: [.isDirectoryKey, .isSymbolicLinkKey]
        )
        if values?.isSymbolicLink == true {
            throw SecureZIPArchiveError.invalidEntry
        }
        try fileManager.createDirectory(at: root, withIntermediateDirectories: true)

        let entries = try extract(data: data, fileManager: fileManager)
        for entry in entries {
            let target = try containedURL(
                for: entry.path,
                root: root,
                isDirectory: entry.isDirectory
            )

            if entry.isDirectory {
                try fileManager.createDirectory(
                    at: target,
                    withIntermediateDirectories: true
                )
                continue
            }

            try fileManager.createDirectory(
                at: target.deletingLastPathComponent(),
                withIntermediateDirectories: true
            )

            if fileManager.fileExists(atPath: target.path) {
                let existing = try target.resourceValues(
                    forKeys: [.isDirectoryKey, .isSymbolicLinkKey]
                )
                guard existing.isDirectory != true,
                      existing.isSymbolicLink != true else {
                    throw SecureZIPArchiveError.invalidEntry
                }
                try fileManager.removeItem(at: target)
            }

            guard fileManager.createFile(
                atPath: target.path,
                contents: entry.data,
                attributes: nil
            ) else {
                throw SecureZIPArchiveError.invalidEntry
            }
        }
    }

    private struct CentralEntry {
        let path: String
        let compressionMethod: UInt16
        let crc32: UInt32
        let compressedSize: UInt64
        let uncompressedSize: UInt64
        let localHeaderOffset: UInt64
        let isDirectory: Bool
    }

    private static func centralDirectoryEntries(_ data: Data) throws -> [CentralEntry] {
        guard let endOffset = findEndOfCentralDirectory(data) else {
            throw SecureZIPArchiveError.invalidArchive
        }

        let entryCount = Int(readUInt16(data, at: endOffset + 10))
        let centralSize = UInt64(readUInt32(data, at: endOffset + 12))
        let centralOffset = UInt64(readUInt32(data, at: endOffset + 16))

        guard centralOffset + centralSize <= UInt64(data.count),
              entryCount <= maximumEntryCount else {
            throw SecureZIPArchiveError.invalidArchive
        }

        var offset = Int(centralOffset)
        var result: [CentralEntry] = []
        result.reserveCapacity(entryCount)

        for _ in 0..<entryCount {
            guard offset + 46 <= data.count,
                  readUInt32(data, at: offset) == centralHeaderSignature else {
                throw SecureZIPArchiveError.invalidArchive
            }

            let flags = readUInt16(data, at: offset + 8)
            guard flags & 0x0001 == 0 else {
                throw SecureZIPArchiveError.unsupportedArchive
            }

            let method = readUInt16(data, at: offset + 10)
            let checksum = readUInt32(data, at: offset + 16)
            let compressedSize = UInt64(readUInt32(data, at: offset + 20))
            let uncompressedSize = UInt64(readUInt32(data, at: offset + 24))
            let nameLength = Int(readUInt16(data, at: offset + 28))
            let extraLength = Int(readUInt16(data, at: offset + 30))
            let commentLength = Int(readUInt16(data, at: offset + 32))
            let localOffset = UInt64(readUInt32(data, at: offset + 42))

            let nameStart = offset + 46
            let nameEnd = nameStart + nameLength
            guard nameEnd <= data.count,
                  nameEnd + extraLength + commentLength <= data.count else {
                throw SecureZIPArchiveError.invalidArchive
            }

            let nameData = data.subdata(in: nameStart..<nameEnd)
            guard let path = String(data: nameData, encoding: .utf8) else {
                throw SecureZIPArchiveError.invalidEntry
            }

            let isDirectory = path.hasSuffix("/")
            result.append(CentralEntry(
                path: path,
                compressionMethod: method,
                crc32: checksum,
                compressedSize: compressedSize,
                uncompressedSize: uncompressedSize,
                localHeaderOffset: localOffset,
                isDirectory: isDirectory
            ))

            offset = nameEnd + extraLength + commentLength
        }

        return result
    }

    private static func localEntryData(
        _ data: Data,
        entry: CentralEntry
    ) throws -> Data {
        let offset = Int(entry.localHeaderOffset)
        guard offset >= 0,
              offset + 30 <= data.count,
              readUInt32(data, at: offset) == localHeaderSignature else {
            throw SecureZIPArchiveError.invalidArchive
        }

        let nameLength = Int(readUInt16(data, at: offset + 26))
        let extraLength = Int(readUInt16(data, at: offset + 28))
        let start = offset + 30 + nameLength + extraLength
        let size = Int(entry.compressedSize)

        guard start >= 0,
              size >= 0,
              start <= data.count,
              size <= data.count - start else {
            throw SecureZIPArchiveError.invalidArchive
        }

        return data.subdata(in: start..<(start + size))
    }

    private static func inflate(
        _ data: Data,
        expectedSize: UInt64
    ) throws -> Data {
        guard expectedSize <= UInt64(Int.max) else {
            throw SecureZIPArchiveError.sizeLimitExceeded
        }

        var output = Data()
        output.reserveCapacity(Int(expectedSize))

        let bufferSize = 64 * 1024
        var sourceOffset = 0

        while sourceOffset < data.count {
            let remaining = data.count - sourceOffset
            let chunkSize = min(bufferSize, remaining)
            let source = data.subdata(in: sourceOffset..<(sourceOffset + chunkSize))

            var destination = [UInt8](repeating: 0, count: bufferSize)
            let decoded = source.withUnsafeBytes { sourceBytes -> Int in
                destination.withUnsafeMutableBytes { destinationBytes -> Int in
                    guard let sourceBase = sourceBytes.bindMemory(to: UInt8.self).baseAddress,
                          let destinationBase = destinationBytes.bindMemory(to: UInt8.self).baseAddress else {
                        return 0
                    }
                    return compression_decode_buffer(
                        destinationBase,
                        bufferSize,
                        sourceBase,
                        source.count,
                        nil,
                        COMPRESSION_ZLIB
                    )
                }
            }

            guard decoded > 0 else {
                throw SecureZIPArchiveError.decompressionFailed
            }

            output.append(contentsOf: destination.prefix(decoded))
            sourceOffset += chunkSize

            guard UInt64(output.count) <= expectedSize else {
                throw SecureZIPArchiveError.sizeLimitExceeded
            }
        }

        guard UInt64(output.count) == expectedSize else {
            throw SecureZIPArchiveError.decompressionFailed
        }

        return output
    }

    private static func normalizePath(_ rawPath: String) throws -> String {
        let replaced = rawPath.replacingOccurrences(of: "\\", with: "/")
        guard !replaced.hasPrefix("/"),
              !replaced.contains("\0") else {
            throw SecureZIPArchiveError.pathTraversal
        }

        let components = replaced.split(
            separator: "/",
            omittingEmptySubsequences: true
        )

        guard !components.isEmpty else {
            throw SecureZIPArchiveError.invalidEntry
        }

        var normalized: [String] = []
        for component in components {
            let value = String(component)
            guard value != ".", value != "..",
                  !value.unicodeScalars.contains(where: CharacterSet.controlCharacters.contains) else {
                throw SecureZIPArchiveError.pathTraversal
            }
            normalized.append(value)
        }

        let path = normalized.joined(separator: "/")
        guard !path.isEmpty else {
            throw SecureZIPArchiveError.invalidEntry
        }
        return path
    }

    private static func containedURL(
        for path: String,
        root: URL,
        isDirectory: Bool
    ) throws -> URL {
        let normalized = try normalizePath(path)
        let target = root
            .appendingPathComponent(normalized, isDirectory: isDirectory)
            .standardizedFileURL
        guard target.path.hasPrefix(root.path + "/") else {
            throw SecureZIPArchiveError.pathTraversal
        }
        return target
    }

    private static func findEndOfCentralDirectory(_ data: Data) -> Int? {
        guard data.count >= 22 else { return nil }
        let minimumOffset = max(0, data.count - (65_535 + 22))
        var index = data.count - 22

        while index >= minimumOffset {
            if readUInt32(data, at: index) == endOfCentralDirectorySignature {
                return index
            }
            index -= 1
        }
        return nil
    }

    private static func readUInt16(_ data: Data, at offset: Int) -> UInt16 {
        UInt16(data[offset])
            | (UInt16(data[offset + 1]) << 8)
    }

    private static func readUInt32(_ data: Data, at offset: Int) -> UInt32 {
        UInt32(data[offset])
            | (UInt32(data[offset + 1]) << 8)
            | (UInt32(data[offset + 2]) << 16)
            | (UInt32(data[offset + 3]) << 24)
    }

    private static func crc32(_ data: Data) -> UInt32 {
        var crc: UInt32 = 0xffffffff
        for byte in data {
            crc ^= UInt32(byte)
            for _ in 0..<8 {
                let mask = -(crc & 1)
                crc = (crc >> 1) ^ (0xedb88320 & UInt32(mask))
            }
        }
        return ~crc
    }
}