//
// FreeOTP
//
// Stores per-token icon images used during import/export.
//

import Foundation

final class TokenIconStorage {
    private let fileManager: FileManager
    private let directoryURL: URL

    init(fileManager: FileManager = .default) {
        self.fileManager = fileManager
        let base = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first ?? fileManager.temporaryDirectory
        directoryURL = base.appendingPathComponent("TokenIcons", isDirectory: true)
        try? ensureDirectoryExists()
    }

    func clearAll() throws {
        if fileManager.fileExists(atPath: directoryURL.path) {
            try fileManager.removeItem(at: directoryURL)
        }
        try ensureDirectoryExists()
    }

    func saveIcon(data: Data, identifier: String) throws -> URL {
        try ensureDirectoryExists()
        let url = fileURL(for: identifier)
        try data.write(to: url, options: .atomic)
        return url
    }

    func iconData(for identifier: String) -> Data? {
        guard let url = iconURL(for: identifier) else {
            return nil
        }
        return try? Data(contentsOf: url)
    }

    func iconURL(for identifier: String) -> URL? {
        let url = fileURL(for: identifier)
        return fileManager.fileExists(atPath: url.path) ? url : nil
    }

    private func ensureDirectoryExists() throws {
        if fileManager.fileExists(atPath: directoryURL.path) == false {
            try fileManager.createDirectory(at: directoryURL, withIntermediateDirectories: true, attributes: nil)
        }
    }

    private func fileURL(for identifier: String) -> URL {
        let slug = Self.slug(for: identifier)
        return directoryURL.appendingPathComponent("\(slug).png")
    }

    private static func slug(for identifier: String) -> String {
        let data = Data(identifier.utf8)
        var hash = [UInt8](repeating: 0, count: Int(CC_SHA256_DIGEST_LENGTH))
        data.withUnsafeBytes {
            _ = CC_SHA256($0.baseAddress, CC_LONG(data.count), &hash)
        }
        return hash.map { String(format: "%02x", $0) }.joined()
    }
}
