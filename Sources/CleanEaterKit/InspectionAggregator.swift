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
        // identified by King County's own per-visit serial number rather than by row
        // count. Fall back to date + type if a row is ever missing that field.
        let inspectionEvents = Set(inWindow.map { row -> InspectionEventKey in
            if let serial = row.inspectionSerialNumber, !serial.isEmpty {
                return .serial(serial)
            }
            return .dateAndType(date: row.inspectionDate, type: row.inspectionType ?? "")
        })

        let violationCount = inWindow.filter { $0.isViolationRow }.count
        let mostRecent = inWindow.map(\.inspectionDate).max()
        let wasEverClosed = inWindow.contains { $0.inspectionClosedBusiness }

        return RestaurantComplianceSummary(
            inspectionCount: inspectionEvents.count,
            violationCount: violationCount,
            mostRecentInspectionDate: mostRecent,
            wasEverClosed: wasEverClosed
        )
    }

    private enum InspectionEventKey: Hashable {
        case serial(String)
        case dateAndType(date: Date, type: String)
    }
}
