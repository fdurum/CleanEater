import Foundation

/// Collapses the multi-row-per-inspection shape of the King County dataset into a
/// single compliance summary for one business.
public enum InspectionAggregator {
    /// - Parameters:
    ///   - rows: All inspection rows already known to belong to one business
    ///     (see `RestaurantMatcher`), in any order, any date range.
    ///   - cutoff: Only rows on or after this date count toward the summary.
    public static func summarize(rows: [FoodEstablishmentInspection], since cutoff: Date) -> RestaurantComplianceSummary {
        let inWindow = rows.filter { $0.inspectionDate >= cutoff }

        // The dataset repeats a row per violation, so one inspection "event" is
        // identified by its date + type rather than by row count.
        let inspectionEvents = Set(inWindow.map { InspectionEventKey(date: $0.inspectionDate, type: $0.inspectionType ?? "") })

        let violationRows = inWindow.filter { $0.isViolationRow }
        let violationCount = violationRows.count
        let totalViolationPoints = violationRows.reduce(0) { $0 + ($1.violationPoints ?? 0) }
        let mostRecent = inWindow.map(\.inspectionDate).max()
        let wasEverClosed = inWindow.contains { $0.inspectionClosedBusiness }

        return RestaurantComplianceSummary(
            inspectionCount: inspectionEvents.count,
            violationCount: violationCount,
            totalViolationPoints: totalViolationPoints,
            mostRecentInspectionDate: mostRecent,
            wasEverClosed: wasEverClosed
        )
    }

    private struct InspectionEventKey: Hashable {
        let date: Date
        let type: String
    }
}
