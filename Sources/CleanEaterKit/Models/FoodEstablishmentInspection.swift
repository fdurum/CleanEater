import Foundation

/// One row from King County's "Food Establishment Inspection Data" Socrata dataset
/// (current dataset id: `r878-4sxa`). One inspection commonly produces multiple rows,
/// one per violation, plus a violation-free row for a clean inspection.
///
/// Field names below are confirmed against live sample rows (see git history / PR
/// discussion), including `businessID`/`inspectionSerialNumber`, which are King
/// County's own stable identifiers and are more reliable for grouping rows than name
/// or address text.
public struct FoodEstablishmentInspection: Decodable, Hashable, Sendable {
    public let name: String
    public let classification: String?
    public let address: String?
    public let city: String?
    public let zipCode: String?
    public let inspectionDate: Date
    public let inspectionType: String?
    public let inspectionResult: String?
    public let inspectionScore: Double?
    public let inspectionClosedBusiness: Bool
    public let seatingRange: String?
    public let riskCategory: String?
    public let violationType: String?
    public let violationDescription: String?
    public let violationPoints: Int?
    public let grade: String?
    public let parcelNumber: String?
    /// King County's own stable identifier for this business location (e.g.
    /// `"PFE-PR-3147569"`), constant across every inspection row for that location
    /// even when the on-file name text varies. Prefer this over name/address
    /// matching once a row has been positively matched to a `PlaceCandidate`.
    public let businessID: String?
    /// King County's identifier for the specific inspection visit (e.g.
    /// `"PFE-DAPY60A5G"`), shared by every violation row from that one visit.
    public let inspectionSerialNumber: String?

    enum CodingKeys: String, CodingKey {
        case name
        case classification
        case address
        case city
        case zipCode = "zip_code"
        case inspectionDate = "inspection_date"
        case inspectionType = "inspection_type"
        case inspectionResult = "inspection_result"
        case inspectionScore = "inspection_score"
        case inspectionClosedBusiness = "inspection_closed_business"
        case seatingRange = "seating_range"
        case riskCategory = "risk_category"
        case violationType = "violation_type"
        case violationDescription = "violation_description"
        case violationPoints = "violation_points"
        case grade
        case parcelNumber = "parcel_number"
        case businessID = "business_id"
        case inspectionSerialNumber = "inspection_serial_num"
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        name = try container.decode(String.self, forKey: .name)
        classification = try container.decodeIfPresent(String.self, forKey: .classification)
        address = try container.decodeIfPresent(String.self, forKey: .address)
        city = try container.decodeIfPresent(String.self, forKey: .city)
        zipCode = try container.decodeIfPresent(String.self, forKey: .zipCode)
        inspectionDate = try container.decode(Date.self, forKey: .inspectionDate)
        inspectionType = try container.decodeIfPresent(String.self, forKey: .inspectionType)
        inspectionResult = try container.decodeIfPresent(String.self, forKey: .inspectionResult)
        inspectionScore = try Self.decodeLenientDouble(container, forKey: .inspectionScore)
        inspectionClosedBusiness = try Self.decodeLenientBool(container, forKey: .inspectionClosedBusiness) ?? false
        seatingRange = try container.decodeIfPresent(String.self, forKey: .seatingRange)
        riskCategory = try container.decodeIfPresent(String.self, forKey: .riskCategory)
        violationType = try container.decodeIfPresent(String.self, forKey: .violationType)
        violationDescription = try container.decodeIfPresent(String.self, forKey: .violationDescription)
        violationPoints = try Self.decodeLenientInt(container, forKey: .violationPoints)
        grade = try container.decodeIfPresent(String.self, forKey: .grade)
        parcelNumber = try container.decodeIfPresent(String.self, forKey: .parcelNumber)
        businessID = try container.decodeIfPresent(String.self, forKey: .businessID)
        inspectionSerialNumber = try container.decodeIfPresent(String.self, forKey: .inspectionSerialNumber)
    }

    public init(
        name: String,
        classification: String? = nil,
        address: String? = nil,
        city: String? = nil,
        zipCode: String? = nil,
        inspectionDate: Date,
        inspectionType: String? = nil,
        inspectionResult: String? = nil,
        inspectionScore: Double? = nil,
        inspectionClosedBusiness: Bool = false,
        seatingRange: String? = nil,
        riskCategory: String? = nil,
        violationType: String? = nil,
        violationDescription: String? = nil,
        violationPoints: Int? = nil,
        grade: String? = nil,
        parcelNumber: String? = nil,
        businessID: String? = nil,
        inspectionSerialNumber: String? = nil
    ) {
        self.name = name
        self.classification = classification
        self.address = address
        self.city = city
        self.zipCode = zipCode
        self.inspectionDate = inspectionDate
        self.inspectionType = inspectionType
        self.inspectionResult = inspectionResult
        self.inspectionScore = inspectionScore
        self.inspectionClosedBusiness = inspectionClosedBusiness
        self.seatingRange = seatingRange
        self.riskCategory = riskCategory
        self.violationType = violationType
        self.violationDescription = violationDescription
        self.violationPoints = violationPoints
        self.grade = grade
        self.parcelNumber = parcelNumber
        self.businessID = businessID
        self.inspectionSerialNumber = inspectionSerialNumber
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

    /// `inspection_score` comes back as a decimal-formatted string (e.g. `"0.00"`,
    /// `"15.00"`), which `Int.init(String)` rejects outright, so this needs its own
    /// lenient path rather than reusing `decodeLenientInt`.
    private static func decodeLenientDouble(_ container: KeyedDecodingContainer<CodingKeys>, forKey key: CodingKeys) throws -> Double? {
        if let doubleValue = try? container.decodeIfPresent(Double.self, forKey: key) {
            return doubleValue
        }
        if let stringValue = try container.decodeIfPresent(String.self, forKey: key) {
            return Double(stringValue)
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
