import XCTest
@testable import CleanEater

final class InspectionAggregatorTests: XCTestCase {
    private let calendar = Calendar(identifier: .gregorian)

    func testCleanRestaurantHasNoViolations() {
        let now = Date()
        let cutoff = calendar.date(byAdding: .year, value: -2, to: now)!
        let rows = [
            FoodEstablishmentInspection(name: "A", inspectionDate: now, inspectionType: "Routine", grade: "Excellent"),
        ]
        let summary = InspectionAggregator.summarize(rows: rows, since: cutoff)
        XCTAssertEqual(summary.inspectionCount, 1)
        XCTAssertEqual(summary.violationCount, 0)
        XCTAssertTrue(summary.isClean)
    }

    /// Zero violations alone isn't enough — the most recent inspection also has to
    /// carry King County's "Excellent" grade.
    func testZeroViolationsButNonExcellentLastGradeIsNotClean() {
        let now = Date()
        let cutoff = calendar.date(byAdding: .year, value: -2, to: now)!
        let rows = [
            FoodEstablishmentInspection(name: "A", inspectionDate: now, inspectionType: "Routine", grade: "Good"),
        ]
        let summary = InspectionAggregator.summarize(rows: rows, since: cutoff)
        XCTAssertEqual(summary.violationCount, 0)
        XCTAssertFalse(summary.isClean)
    }

    /// The grade that counts is the one from the most recent visit, not an older one.
    func testUsesGradeFromMostRecentInspectionOnly() {
        let now = Date()
        let cutoff = calendar.date(byAdding: .year, value: -2, to: now)!
        let sixMonthsAgo = calendar.date(byAdding: .month, value: -6, to: now)!
        let rows = [
            FoodEstablishmentInspection(name: "A", inspectionDate: sixMonthsAgo, inspectionType: "Routine", grade: "Good"),
            FoodEstablishmentInspection(name: "A", inspectionDate: now, inspectionType: "Routine", grade: "Excellent"),
        ]
        let summary = InspectionAggregator.summarize(rows: rows, since: cutoff)
        XCTAssertEqual(summary.lastGrade, "Excellent")
        XCTAssertTrue(summary.isClean)
    }

    func testOneInspectionMultipleViolationRowsCountsAsOneInspectionButMultipleViolations() {
        let now = Date()
        let cutoff = calendar.date(byAdding: .year, value: -2, to: now)!
        let rows = [
            FoodEstablishmentInspection(name: "A", inspectionDate: now, inspectionType: "Routine", violationDescription: "Improper cold holding"),
            FoodEstablishmentInspection(name: "A", inspectionDate: now, inspectionType: "Routine", violationDescription: "Handwashing sink blocked"),
        ]
        let summary = InspectionAggregator.summarize(rows: rows, since: cutoff)
        XCTAssertEqual(summary.inspectionCount, 1, "Two rows for the same inspection date+type are one inspection event")
        XCTAssertEqual(summary.violationCount, 2)
        XCTAssertFalse(summary.isClean)
    }

    func testRowsBeforeCutoffAreExcluded() {
        let now = Date()
        let cutoff = calendar.date(byAdding: .year, value: -2, to: now)!
        let threeYearsAgo = calendar.date(byAdding: .year, value: -3, to: now)!
        let rows = [
            FoodEstablishmentInspection(name: "A", inspectionDate: threeYearsAgo, violationDescription: "Old violation"),
        ]
        let summary = InspectionAggregator.summarize(rows: rows, since: cutoff)
        XCTAssertEqual(summary.inspectionCount, 0)
        XCTAssertEqual(summary.violationCount, 0)
        XCTAssertFalse(summary.isClean, "No inspections in the window means we can't vouch for it")
    }

    /// Two visits sharing the same date and type (e.g. a routine inspection redone
    /// the same day) would collapse into one event under the old date+type key, but
    /// King County's `inspection_serial_num` disambiguates them correctly.
    func testDistinctSerialNumbersOnSameDateAndTypeCountAsTwoInspections() {
        let now = Date()
        let cutoff = calendar.date(byAdding: .year, value: -2, to: now)!
        let rows = [
            FoodEstablishmentInspection(name: "A", inspectionDate: now, inspectionType: "Routine", inspectionSerialNumber: "SERIAL-1"),
            FoodEstablishmentInspection(name: "A", inspectionDate: now, inspectionType: "Routine", inspectionSerialNumber: "SERIAL-2"),
        ]
        let summary = InspectionAggregator.summarize(rows: rows, since: cutoff)
        XCTAssertEqual(summary.inspectionCount, 2)
    }

    /// `businessID` doesn't depend on the lookback window, so it should come through
    /// even from a row that falls outside `cutoff`.
    func testBusinessIDIsCarriedThroughFromAnyRow() {
        let now = Date()
        let cutoff = calendar.date(byAdding: .year, value: -2, to: now)!
        let threeYearsAgo = calendar.date(byAdding: .year, value: -3, to: now)!
        let rows = [
            FoodEstablishmentInspection(name: "A", inspectionDate: threeYearsAgo, businessID: "PFE-PR-3147569"),
        ]
        let summary = InspectionAggregator.summarize(rows: rows, since: cutoff)
        XCTAssertEqual(summary.businessID, "PFE-PR-3147569")
    }

    func testClosureWithinWindowIsNeverClean() {
        let now = Date()
        let cutoff = calendar.date(byAdding: .year, value: -2, to: now)!
        let rows = [
            FoodEstablishmentInspection(name: "A", inspectionDate: now, inspectionClosedBusiness: true),
        ]
        let summary = InspectionAggregator.summarize(rows: rows, since: cutoff)
        XCTAssertTrue(summary.wasEverClosed)
        XCTAssertFalse(summary.isClean)
    }
}
