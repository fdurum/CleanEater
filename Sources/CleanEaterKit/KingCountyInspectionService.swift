import Foundation

public enum KingCountyInspectionServiceError: Error, Equatable {
    case invalidQuery
    case badResponse(statusCode: Int)
}

public protocol KingCountyInspectionServiceProtocol: Sendable {
    /// Fetches inspection rows for businesses whose name contains `name` (case
    /// insensitive), inspected on or after `cutoff`. Returns raw rows that still need
    /// to be narrowed down with `RestaurantMatcher`, since name search can return
    /// multiple locations of a chain.
    func fetchInspections(matchingName name: String, since cutoff: Date, limit: Int) async throws -> [FoodEstablishmentInspection]
}

/// Client for King County's Socrata "Food Establishment Inspection Data" API
/// (current dataset id `r878-4sxa`, https://data.kingcounty.gov/resource/r878-4sxa.json).
///
/// See the note on `FoodEstablishmentInspection` regarding field-name verification.
public final class KingCountyInspectionService: KingCountyInspectionServiceProtocol, @unchecked Sendable {
    public static let currentDatasetID = "r878-4sxa"

    private let baseURL: URL
    private let session: URLSession

    public init(datasetID: String = KingCountyInspectionService.currentDatasetID, session: URLSession = .shared) {
        self.baseURL = URL(string: "https://data.kingcounty.gov/resource/\(datasetID).json")!
        self.session = session
    }

    public func fetchInspections(matchingName name: String, since cutoff: Date, limit: Int = 1000) async throws -> [FoodEstablishmentInspection] {
        let url = try Self.buildURL(baseURL: baseURL, name: name, since: cutoff, limit: limit)
        let (data, response) = try await session.data(from: url)
        guard let httpResponse = response as? HTTPURLResponse else {
            throw KingCountyInspectionServiceError.badResponse(statusCode: -1)
        }
        guard (200..<300).contains(httpResponse.statusCode) else {
            throw KingCountyInspectionServiceError.badResponse(statusCode: httpResponse.statusCode)
        }
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .custom(Self.decodeSocrataDate)
        return try decoder.decode([FoodEstablishmentInspection].self, from: data)
    }

    /// Builds a SoQL query of the form:
    /// `?$where=upper(name) like upper('%NAME%') AND inspection_date >= 'CUTOFF'&$limit=...&$order=inspection_date DESC`
    static func buildURL(baseURL: URL, name: String, since cutoff: Date, limit: Int) throws -> URL {
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedName.isEmpty, limit > 0 else {
            throw KingCountyInspectionServiceError.invalidQuery
        }

        let escapedName = soqlEscaped(trimmedName)
        let cutoffLiteral = floatingTimestampFormatter.string(from: cutoff)
        let whereClause = "upper(name) like upper('%\(escapedName)%') AND inspection_date >= '\(cutoffLiteral)'"

        guard var components = URLComponents(url: baseURL, resolvingAgainstBaseURL: false) else {
            throw KingCountyInspectionServiceError.invalidQuery
        }
        components.queryItems = [
            URLQueryItem(name: "$where", value: whereClause),
            URLQueryItem(name: "$order", value: "inspection_date DESC"),
            URLQueryItem(name: "$limit", value: String(limit)),
        ]
        guard let url = components.url else {
            throw KingCountyInspectionServiceError.invalidQuery
        }
        return url
    }

    /// SoQL string literals are single-quoted; escape embedded quotes by doubling
    /// them (e.g. `O'Brien's` -> `O''Brien''s`) to avoid breaking out of the literal.
    private static func soqlEscaped(_ value: String) -> String {
        value.replacingOccurrences(of: "'", with: "''")
    }

    private static let floatingTimestampFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone(identifier: "UTC")
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss"
        return formatter
    }()

    private static let responseDateFormatters: [DateFormatter] = {
        let withFraction = DateFormatter()
        withFraction.locale = Locale(identifier: "en_US_POSIX")
        withFraction.timeZone = TimeZone(identifier: "UTC")
        withFraction.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSS"

        let withoutFraction = DateFormatter()
        withoutFraction.locale = Locale(identifier: "en_US_POSIX")
        withoutFraction.timeZone = TimeZone(identifier: "UTC")
        withoutFraction.dateFormat = "yyyy-MM-dd'T'HH:mm:ss"

        let dateOnly = DateFormatter()
        dateOnly.locale = Locale(identifier: "en_US_POSIX")
        dateOnly.timeZone = TimeZone(identifier: "UTC")
        dateOnly.dateFormat = "yyyy-MM-dd"

        return [withFraction, withoutFraction, dateOnly]
    }()

    static func decodeSocrataDate(_ decoder: Decoder) throws -> Date {
        let container = try decoder.singleValueContainer()
        let string = try container.decode(String.self)
        for formatter in responseDateFormatters {
            if let date = formatter.date(from: string) {
                return date
            }
        }
        throw DecodingError.dataCorruptedError(in: container, debugDescription: "Unrecognized Socrata date format: \(string)")
    }
}
