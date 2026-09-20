import Foundation

/// One row from King County's "Food Establishment Inspection Data" Socrata dataset
/// (current dataset id: `r878-4sxa`). One inspection commonly produces multiple rows,
/// one per violation, plus a violation-free row for a clean inspection.
///
/// IMPORTANT: The `CodingKeys` below are King County's Socrata field names as of this
/// writing. This code could not be verified against the live API in the environment
/// it was written in (outbound access to data.kingcounty.gov was blocked). Before
/// relying on this, fetch `https://data.kingcounty.gov/resource/r878-4sxa.json?$limit=1`
/// yourself and confirm these keys match, adjusting `CodingKeys` if the schema differs.
public struct FoodEstablishmentInspection: Decodable, Hashable, Sendable {
    public let name: String
    public let programIdentifier: String?
    public let address: String?
    public let city: String?
    public let zipCode: String?
    public let inspectionDate: Date
    public let inspectionType: String?
    public let inspectionResult: String?
    public let inspectionScore: Int?
    public let inspectionClosedBusiness: Bool
    public let violationType: String?
    public let violationDescription: String?
    public let violationPoints: Int?

    enum CodingKeys: String, CodingKey {
        case name
        case programIdentifier = "program_identifier"
        case address
        case city
        case zipCode = "zip_code"
        case inspectionDate = "inspection_date"
        case inspectionType = "inspection_type"
        case inspectionResult = "inspection_result"
        case inspectionScore = "inspection_score"
        case inspectionClosedBusiness = "inspection_closed_business"
        case violationType = "violation_type"
        case violationDescription = "violation_description"
        case violationPoints = "violation_points"
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        name = try container.decode(String.self, forKey: .name)
        programIdentifier = try container.decodeIfPresent(String.self, forKey: .programIdentifier)
        address = try container.decodeIfPresent(String.self, forKey: .address)
        city = try container.decodeIfPresent(String.self, forKey: .city)
        zipCode = try container.decodeIfPresent(String.self, forKey: .zipCode)
        inspectionDate = try container.decode(Date.self, forKey: .inspectionDate)
        inspectionType = try container.decodeIfPresent(String.self, forKey: .inspectionType)
        inspectionResult = try container.decodeIfPresent(String.self, forKey: .inspectionResult)
        inspectionScore = try Self.decodeLenientInt(container, forKey: .inspectionScore)
        inspectionClosedBusiness = try Self.decodeLenientBool(container, forKey: .inspectionClosedBusiness) ?? false
        violationType = try container.decodeIfPresent(String.self, forKey: .violationType)
        violationDescription = try container.decodeIfPresent(String.self, forKey: .violationDescription)
        violationPoints = try Self.decodeLenientInt(container, forKey: .violationPoints)
    }

    public init(
        name: String,
        programIdentifier: String? = nil,
        address: String? = nil,
        city: String? = nil,
        zipCode: String? = nil,
        inspectionDate: Date,
        inspectionType: String? = nil,
        inspectionResult: String? = nil,
        inspectionScore: Int? = nil,
        inspectionClosedBusiness: Bool = false,
        violationType: String? = nil,
        violationDescription: String? = nil,
        violationPoints: Int? = nil
    ) {
        self.name = name
        self.programIdentifier = programIdentifier
        self.address = address
        self.city = city
        self.zipCode = zipCode
        self.inspectionDate = inspectionDate
        self.inspectionType = inspectionType
        self.inspectionResult = inspectionResult
        self.inspectionScore = inspectionScore
        self.inspectionClosedBusiness = inspectionClosedBusiness
        self.violationType = violationType
        self.violationDescription = violationDescription
        self.violationPoints = violationPoints
    }

    /// Socrata's Open Data API renders numbers as JSON strings for some legacy
    /// datasets and as native numbers for others, so accept either.
    private static func decodeLenientInt(_ container: KeyedDecodingContainer<CodingKeys>, forKey key: CodingKeys) throws -> Int? {
        if let intValue = try? container.decodeIfPresent(Int.self, forKey: key) {
            return intValue
        }
        if let stringValue = try container.decodeIfPresent(String.self, forKey: key) {
            return Int(stringValue)
        }
        return nil
    }

    private static func decodeLenientBool(_ container: KeyedDecodingContainer<CodingKeys>, forKey key: CodingKeys) throws -> Bool? {
        if let boolValue = try? container.decodeIfPresent(Bool.self, forKey: key) {
            return boolValue
        }
        if let stringValue = try container.decodeIfPresent(String.self, forKey: key) {
            return ["true", "yes", "y", "1"].contains(stringValue.lowercased())
        }
        return nil
    }

    /// True when this row represents an actual cited violation (as opposed to a
    /// "no violations found" row for a clean inspection).
    public var isViolationRow: Bool {
        if let description = violationDescription, !description.trimmingCharacters(in: .whitespaces).isEmpty {
            return true
        }
        if let type = violationType, !type.trimmingCharacters(in: .whitespaces).isEmpty {
            return true
        }
        return false
    }
}
