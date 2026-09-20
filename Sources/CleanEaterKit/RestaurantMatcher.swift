import Foundation

/// Matches a place from a search provider (e.g. "Some Thai Restaurant", "123 Main St")
/// against King County inspection rows (e.g. "SOME THAI RESTAURANT LLC", "123 MAIN
/// STREET"). Name text alone is unreliable — chains and generic names collide — so
/// this requires the leading street number to agree and the name text to be similar
/// enough after normalization.
public enum RestaurantMatcher {
    /// Minimum token-overlap score (0...1) for two normalized names to be considered
    /// the same business. Tuned to tolerate "LLC"/"INC" suffixes and word reordering
    /// while still rejecting unrelated names.
    public static let nameSimilarityThreshold = 0.6

    public static func isMatch(place: PlaceCandidate, inspection: FoodEstablishmentInspection) -> Bool {
        guard nameSimilarity(place.name, inspection.name) >= nameSimilarityThreshold else {
            return false
        }
        return streetNumbersAgree(place.streetAddress, inspection.address)
    }

    /// Finds the best-matching inspection rows for `place` out of a broader candidate
    /// pool (typically everything returned by a name-based Socrata query).
    public static func matchingRows(for place: PlaceCandidate, in rows: [FoodEstablishmentInspection]) -> [FoodEstablishmentInspection] {
        rows.filter { isMatch(place: place, inspection: $0) }
    }

    // MARK: - Name similarity

    static func nameSimilarity(_ lhs: String, _ rhs: String) -> Double {
        let lhsTokens = normalizedNameTokens(lhs)
        let rhsTokens = normalizedNameTokens(rhs)
        guard !lhsTokens.isEmpty, !rhsTokens.isEmpty else { return 0 }

        let intersection = lhsTokens.intersection(rhsTokens)
        // Dice coefficient: robust when one side has an extra token (e.g. "LLC"
        // already stripped, or a generic word the other name lacks).
        let denominator = lhsTokens.count + rhsTokens.count
        guard denominator > 0 else { return 0 }
        return (2.0 * Double(intersection.count)) / Double(denominator)
    }

    private static let legalSuffixes: Set<String> = ["LLC", "INC", "INCORPORATED", "CORP", "CORPORATION", "CO", "LTD", "LP"]

    /// King County prefixes some listings with an internal store/location code, e.g.
    /// `"#807 TUTTA BELLA"` for a chain location — MapKit never includes that code, so
    /// treating it as a name token would only ever penalize the similarity score.
    private static let leadingStoreCode = try! NSRegularExpression(pattern: "^#?\\d+\\s+")

    static func normalizedNameTokens(_ name: String) -> Set<String> {
        let upper = name.uppercased()
        let withoutStoreCode = leadingStoreCode.stringByReplacingMatches(
            in: upper,
            range: NSRange(upper.startIndex..., in: upper),
            withTemplate: ""
        )
        let alphanumericOnly = withoutStoreCode.unicodeScalars.map { scalar -> Character in
            (CharacterSet.alphanumerics.contains(scalar) || scalar == " ") ? Character(scalar) : " "
        }
        let cleaned = String(alphanumericOnly)
        let tokens = cleaned.split(separator: " ").map(String.init)
        return Set(tokens.filter { !legalSuffixes.contains($0) && !$0.isEmpty })
    }

    // MARK: - Address agreement

    /// Street-name spelling and abbreviation conventions differ ("St" vs "Street"),
    /// but the leading street number is a cheap, high-precision signal that two
    /// addresses are the same physical location. Missing address data on either side
    /// falls back to trusting the name match alone.
    static func streetNumbersAgree(_ lhs: String?, _ rhs: String?) -> Bool {
        guard let lhsNumber = leadingStreetNumber(lhs) else { return true }
        guard let rhsNumber = leadingStreetNumber(rhs) else { return true }
        return lhsNumber == rhsNumber
    }

    private static func leadingStreetNumber(_ address: String?) -> String? {
        guard let address = address?.trimmingCharacters(in: .whitespaces), !address.isEmpty else { return nil }
        var digits = ""
        for character in address {
            if character.isNumber {
                digits.append(character)
            } else {
                break
            }
        }
        return digits.isEmpty ? nil : digits
    }
}
