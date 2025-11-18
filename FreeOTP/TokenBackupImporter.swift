//
// FreeOTP
//
// Token backup importer.
//

import Foundation

enum TokenImportError: LocalizedError {
    case mismatchedCounts
    case invalidSecret
    case unsupportedTokenType(String)
    case addFailed

    var errorDescription: String? {
        switch self {
        case .mismatchedCounts:
            return "Backup file is corrupt (token order does not match tokens)."
        case .invalidSecret:
            return "Backup file contains an invalid secret."
        case .unsupportedTokenType(let type):
            return "Backup file contains an unsupported token type (\(type))."
        case .addFailed:
            return "Failed to import one or more tokens."
        }
    }
}

final class TokenBackupImporter {
    private let store: TokenStore

    init(store: TokenStore = TokenStore()) {
        self.store = store
    }

    func importBackup(from url: URL) throws {
        let needsAccess = url.startAccessingSecurityScopedResource()
        defer {
            if needsAccess {
                url.stopAccessingSecurityScopedResource()
            }
        }

        let data = try Data(contentsOf: url)
        try importBackup(from: data)
    }

    private func importBackup(from data: Data) throws {
        let decoder = JSONDecoder()
        let backup = try decoder.decode(TokenBackup.self, from: data)

        guard backup.tokenOrder.count == backup.tokens.count else {
            throw TokenImportError.mismatchedCounts
        }

        let pairs = Array(zip(backup.tokenOrder, backup.tokens))
        for (_, entry) in pairs.reversed() {
            try add(entry: entry)
        }
    }

    private func add(entry: TokenBackup.Entry) throws {
        let type = entry.type.lowercased()
        guard type == "hotp" || type == "totp" else {
            throw TokenImportError.unsupportedTokenType(entry.type)
        }

        guard let secretData = dataFrom(secretArray: entry.secret) else {
            throw TokenImportError.invalidSecret
        }

        var components = URLComponents()
        components.scheme = "otpauth"
        components.host = type
        components.path = "/" + makePath(issuer: entry.issuerExt, label: entry.label)

        var queryItems = [
            URLQueryItem(name: "secret", value: secretData.base32EncodedString()),
            URLQueryItem(name: "algorithm", value: entry.algo.lowercased()),
            URLQueryItem(name: "digits", value: String(entry.digits))
        ]

        if type == "totp" {
            queryItems.append(URLQueryItem(name: "period", value: String(entry.period)))
        } else {
            queryItems.append(URLQueryItem(name: "counter", value: String(entry.counter)))
        }

        if entry.issuerExt.isEmpty == false {
            queryItems.append(URLQueryItem(name: "issuer", value: entry.issuerExt))
        }

        components.queryItems = queryItems

        guard store.add(components) != nil else {
            throw TokenImportError.addFailed
        }
    }

    private func makePath(issuer: String, label: String) -> String {
        let trimmedIssuer = issuer.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedLabel = label.trimmingCharacters(in: .whitespacesAndNewlines)
        var combined: String

        if trimmedIssuer.isEmpty {
            combined = trimmedLabel
        } else if trimmedLabel.isEmpty {
            combined = trimmedIssuer
        } else {
            combined = "\(trimmedIssuer):\(trimmedLabel)"
        }

        if combined.isEmpty {
            combined = UUID().uuidString
        }

        return combined.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? combined
    }

    private func dataFrom(secretArray: [Int]) -> Data? {
        var bytes = [UInt8]()
        bytes.reserveCapacity(secretArray.count)

        for value in secretArray {
            guard value >= 0 && value <= 255 else {
                return nil
            }
            bytes.append(UInt8(value))
        }

        return Data(bytes)
    }
}
