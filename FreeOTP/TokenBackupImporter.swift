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
    case iconStorageFailed

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
        case .iconStorageFailed:
            return "Failed to persist an imported icon."
        }
    }
}

struct TokenImportFailure {
    let index: Int
    let label: String
    let reason: String
}

final class TokenBackupImporter {
    private let store: TokenStore
    private let iconStorage: TokenIconStorage
    private struct PreparedEntry {
        let index: Int
        let label: String
        let identifier: String
        let components: URLComponents
        let iconData: Data?
    }

    init(store: TokenStore = TokenStore(), iconStorage: TokenIconStorage = TokenIconStorage()) {
        self.store = store
        self.iconStorage = iconStorage
    }

    func importBackup(from url: URL) throws -> [TokenImportFailure] {
        let needsAccess = url.startAccessingSecurityScopedResource()
        defer {
            if needsAccess {
                url.stopAccessingSecurityScopedResource()
            }
        }

        let data = try Data(contentsOf: url)
        let plan = try prepareEntries(from: data)

        try iconStorage.clearAll()
        store.eraseAll()

        var failures = plan.failures
        for entry in plan.validEntries.reversed() {
            guard let token = store.add(entry.components) else {
                let reason = TokenImportError.addFailed.errorDescription ?? "Failed to import token."
                failures.append(TokenImportFailure(index: entry.index, label: entry.label, reason: reason))
                continue
            }

            if let iconData = entry.iconData {
                do {
                    let fileURL = try iconStorage.saveIcon(data: iconData, identifier: entry.identifier)
                    token.image = fileURL.absoluteString
                    _ = Token.store.save(token)
                } catch {
                    let reason = TokenImportError.iconStorageFailed.errorDescription ?? "Failed to save icon."
                    failures.append(TokenImportFailure(index: entry.index, label: entry.label, reason: reason))
                }
            }
        }

        failures.sort { $0.index < $1.index }
        return failures
    }

    private func prepareEntries(from data: Data) throws -> (validEntries: [PreparedEntry], failures: [TokenImportFailure]) {
        let decoder = JSONDecoder()
        let backup = try decoder.decode(TokenBackup.self, from: data)

        guard backup.tokenOrder.count == backup.tokens.count else {
            throw TokenImportError.mismatchedCounts
        }

        let pairs = Array(zip(backup.tokenOrder, backup.tokens))
        var successes: [PreparedEntry] = []
        var failures: [TokenImportFailure] = []

        for (idx, pair) in pairs.enumerated() {
            let entry = pair.1
            let identifier = pair.0
            do {
                let components = try makeComponents(for: entry)
                let iconData = decodeIconData(entry.icon, index: idx + 1, label: entry.label, failures: &failures)
                successes.append(PreparedEntry(index: idx + 1, label: entry.label, identifier: identifier, components: components, iconData: iconData))
            } catch {
                failures.append(TokenImportFailure(index: idx + 1, label: entry.label, reason: error.localizedDescription))
            }
        }

        return (successes, failures)
    }

    private func decodeIconData(_ base64: String?, index: Int, label: String, failures: inout [TokenImportFailure]) -> Data? {
        guard let base64 = base64 else {
            return nil
        }

        if let data = Data(base64Encoded: base64) {
            return data
        }

        failures.append(TokenImportFailure(index: index, label: label, reason: "picture decode failed"))
        return nil
    }

    private func makeComponents(for entry: TokenBackup.Entry) throws -> URLComponents {
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
            URLQueryItem(name: "algorithm", value: entry.algo.uppercased()),
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

        return components
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

        return combined
    }

    private func dataFrom(secretArray: [Int]) -> Data? {
        var bytes = [UInt8]()
        bytes.reserveCapacity(secretArray.count)

        for value in secretArray {
            var normalized = value
            if normalized < 0 {
                normalized += 256
            }

            guard normalized >= 0 && normalized <= 255 else {
                return nil
            }
            bytes.append(UInt8(normalized))
        }

        return Data(bytes)
    }
}
