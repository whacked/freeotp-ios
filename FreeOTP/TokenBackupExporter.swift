//
// FreeOTP
//
// Token backup/export helpers.
//

import Foundation

struct TokenBackup: Codable {
    struct Entry: Codable {
        let algo: String
        let counter: Int
        let digits: Int
        let issuerExt: String
        let label: String
        let period: Int
        let secret: [Int]
        let type: String
        let icon: String?
    }

    let tokenOrder: [String]
    let tokens: [Entry]
}

enum TokenExportError: LocalizedError {
    case missingOTP(account: String)

    var errorDescription: String? {
        switch self {
        case .missingOTP:
            return "A stored OTP could not be located for one of the tokens."
        }
    }
}

final class TokenBackupExporter {
    private let store: TokenStore
    private let iconStorage: TokenIconStorage

    init(store: TokenStore = TokenStore(), iconStorage: TokenIconStorage = TokenIconStorage()) {
        self.store = store
        self.iconStorage = iconStorage
    }

    func exportFileURL() throws -> URL {
        let tokens = store.getAllTokens()
        var order = [String]()
        var entries = [TokenBackup.Entry]()

        for token in tokens {
            guard let otp = OTP.store.load(token.account) else {
                throw TokenExportError.missingOTP(account: token.account)
            }

            let identifier = Self.identifier(for: token)
            order.append(identifier)
            let iconString = iconStorage.iconData(for: identifier)?.base64EncodedString()
            entries.append(TokenBackup.Entry(
                algo: otp.algorithmName,
                counter: Int(token.counterValue),
                digits: otp.digitsCount,
                issuerExt: token.issuer ?? "",
                label: token.label ?? "",
                period: Int(token.periodValue),
                secret: otp.secretBytes,
                type: token.kind.exportTypeDescription,
                icon: iconString
            ))
        }

        let backup = TokenBackup(tokenOrder: order, tokens: entries)
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        let data = try encoder.encode(backup)
        return try write(data: data)
    }

    private func write(data: Data) throws -> URL {
        let tempDir = FileManager.default.temporaryDirectory
        let filename = "freeotp-export-\(Int(Date().timeIntervalSince1970)).json"
        let url = tempDir.appendingPathComponent(filename)
        try data.write(to: url, options: .atomic)
        return url
    }

    private static func identifier(for token: Token) -> String {
        let issuer = token.issuer?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        let label = token.label?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""

        if issuer.isEmpty {
            return label
        } else if label.isEmpty {
            return issuer
        }

        return "\(issuer):\(label)"
    }
}

extension Token.Kind {
    var exportTypeDescription: String {
        switch self {
        case .hotp:
            return "HOTP"
        case .totp:
            return "TOTP"
        }
    }
}
