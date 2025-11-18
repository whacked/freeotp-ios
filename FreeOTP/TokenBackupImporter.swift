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

struct TokenImportFailure {
    let index: Int
    let label: String
    let reason: String
}

final class TokenBackupImporter {
    private let store: TokenStore
    private struct PreparedEntry {
        let index: Int
        let label: String
        let components: URLComponents
    }

    init(store: TokenStore = TokenStore()) {
        self.store = store
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

        store.eraseAll()

        var failures = plan.failures
        for entry in plan.validEntries.reversed() {
            if store.add(entry.components) == nil {
                let reason = TokenImportError.addFailed.errorDescription ?? "Failed to import token."
                failures.append(TokenImportFailure(index: entry.index, label: entry.label, reason: reason))
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
            do {
                let components = try makeComponents(for: entry)
                successes.append(PreparedEntry(index: idx + 1, label: entry.label, components: components))
            } catch {
                failures.append(TokenImportFailure(index: idx + 1, label: entry.label, reason: error.localizedDescription))
            }
        }

        return (successes, failures)
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
            guard value >= 0 && value <= 255 else {
                return nil
            }
            bytes.append(UInt8(value))
        }

        return Data(bytes)
    }
}
