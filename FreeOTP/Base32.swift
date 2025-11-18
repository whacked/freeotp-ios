//
//  Base32.swift
//  FreeOTP
//
//  Created by OpenAI Codex.
//

import Foundation

private enum Base32Decoder {
    static let alphabet: [Character: UInt8] = {
        let chars = Array("ABCDEFGHIJKLMNOPQRSTUVWXYZ234567")
        var dict: [Character: UInt8] = [:]
        for (idx, char) in chars.enumerated() {
            dict[char] = UInt8(idx)
        }
        return dict
    }()

    static func value(for character: Character) -> UInt8? {
        if let value = alphabet[character] {
            return value
        }

        switch character {
        case "0":
            return alphabet["O"]
        case "1":
            return alphabet["L"]
        default:
            return nil
        }
    }
}

extension String {
    /// Decodes a Base32 string following RFC 4648. Whitespace and dashes are ignored and
    /// secrets that contain invalid symbols return `nil` to match the previous behaviour.
    var base32DecodedData: Data? {
        let filtered = uppercased()
            .replacingOccurrences(of: "=", with: "")
            .replacingOccurrences(of: " ", with: "")
            .replacingOccurrences(of: "-", with: "")
            .filter { !$0.isWhitespace }

        guard filtered.isEmpty == false else { return nil }

        var buffer: UInt32 = 0
        var bits = 0
        var output = Data()

        for character in filtered {
            guard let value = Base32Decoder.value(for: character) else {
                return nil
            }

            buffer = (buffer << 5) | UInt32(value)
            bits += 5

            while bits >= 8 {
                let shift = bits - 8
                let byte = UInt8((buffer >> shift) & 0xFF)
                output.append(byte)
                bits -= 8
                buffer &= (1 << bits) - 1
            }
        }

        if bits > 0 && (buffer & ((1 << bits) - 1)) != 0 {
            return nil
        }

        return output
    }
}
