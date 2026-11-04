import Foundation

/// The result of aggregating a business's inspection rows over a lookback window.
public struct RestaurantComplianceSummary: Hashable, Sendable {
    public let inspectionCount: Int
    public let violationCount: Int
    public let totalViolationPoints: Int
    public let mostRecentInspectionDate: Date?
    public let wasEverClosed: Bool

    public init(
        inspectionCount: Int,
        violationCount: Int,
        totalViolationPoints: Int,
        mostRecentInspectionDate: Date?,
        wasEverClosed: Bool
    ) {
        self.inspectionCount = inspectionCount
        self.violationCount = violationCount
        self.totalViolationPoints = totalViolationPoints
        self.mostRecentInspectionDate = mostRecentInspectionDate
        self.wasEverClosed = wasEverClosed
    }

    /// "Zero violations" as defined for CleanEater: at least one inspection occurred
    /// in the window, none of them had a cited violation, and the business was never
    /// closed by the health department during that window.
    public var isClean: Bool {
        inspectionCount > 0 && violationCount == 0 && !wasEverClosed
    }

    /// A looser bar than `isClean`: a restaurant can have cited violations and still
    /// qualify, as long as they were minor enough that the accumulated
    /// `violation_points` across the window stay at or under `maxViolationPoints`,
    /// and the business was never closed. Any restaurant that's `isClean` also
    /// satisfies this (0 points is always under the threshold).
    public func isExcellent(maxViolationPoints: Int) -> Bool {
        inspectionCount > 0 && !wasEverClosed && totalViolationPoints <= maxViolationPoints
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
