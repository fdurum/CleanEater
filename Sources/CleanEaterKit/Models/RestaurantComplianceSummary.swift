import Foundation

/// The result of aggregating a business's inspection rows over a lookback window.
public struct RestaurantComplianceSummary: Hashable, Sendable {
    public let inspectionCount: Int
    public let violationCount: Int
    public let mostRecentInspectionDate: Date?
    public let wasEverClosed: Bool
    /// King County's stable identifier for this business location (see
    /// `FoodEstablishmentInspection.businessID`), carried through so the UI can link
    /// out to King County's own inspection report without depending on name text.
    public let businessID: String?

    public init(inspectionCount: Int, violationCount: Int, mostRecentInspectionDate: Date?, wasEverClosed: Bool, businessID: String? = nil) {
        self.inspectionCount = inspectionCount
        self.violationCount = violationCount
        self.mostRecentInspectionDate = mostRecentInspectionDate
        self.wasEverClosed = wasEverClosed
        self.businessID = businessID
    }

    /// "Zero violations" as defined for CleanEater: at least one inspection occurred
    /// in the window, none of them had a cited violation, and the business was never
    /// closed by the health department during that window.
    public var isClean: Bool {
        inspectionCount > 0 && violationCount == 0 && !wasEverClosed
    }
}

/// A place plus its King County compliance record, ready to display.
public struct CleanRestaurantResult: Identifiable, Hashable, Sendable {
    public let place: PlaceCandidate
    public let summary: RestaurantComplianceSummary

    public var id: String { place.id }

    public init(place: PlaceCandidate, summary: RestaurantComplianceSummary) {
        self.place = place
        self.summary = summary
    }
}
