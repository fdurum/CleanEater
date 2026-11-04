import XCTest
@testable import CleanEater

final class InspectionAggregatorTests: XCTestCase {
    private let calendar = Calendar(identifier: .gregorian)

    func testCleanRestaurantHasNoViolations() {
        let now = Date()
        let cutoff = calendar.date(byAdding: .year, value: -2, to: now)!
        let rows = [
            FoodEstablishmentInspection(name: "A", inspectionDate: now, inspectionType: "Routine"),
        ]
        let summary = InspectionAggregator.summarize(rows: rows, since: cutoff)
        XCTAssertEqual(summary.inspectionCount, 1)
        XCTAssertEqual(summary.violationCount, 0)
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

    func testTotalViolationPointsSumsAcrossViolationRowsOnly() {
        let now = Date()
        let cutoff = calendar.date(byAdding: .year, value: -2, to: now)!
        let rows = [
            FoodEstablishmentInspection(name: "A", inspectionDate: now, violationDescription: "Minor", violationPoints: 3),
            FoodEstablishmentInspection(name: "A", inspectionDate: now, violationDescription: "Minor", violationPoints: 4),
            FoodEstablishmentInspection(name: "A", inspectionDate: now, inspectionType: "Routine"), // no violation, no points
        ]
        let summary = InspectionAggregator.summarize(rows: rows, since: cutoff)
        XCTAssertEqual(summary.totalViolationPoints, 7)
    }

    func testExcellentAllowsMinorViolationsUnderThreshold() {
        let now = Date()
        let cutoff = calendar.date(byAdding: .year, value: -2, to: now)!
        let rows = [
            FoodEstablishmentInspection(name: "A", inspectionDate: now, violationDescription: "Minor", violationPoints: 5),
        ]
        let summary = InspectionAggregator.summarize(rows: rows, since: cutoff)
        XCTAssertFalse(summary.isClean)
        XCTAssertTrue(summary.isExcellent(maxViolationPoints: 10))
        XCTAssertFalse(summary.isExcellent(maxViolationPoints: 4))
    }

    func testExcellentStillRequiresNeverClosed() {
        let now = Date()
        let cutoff = calendar.date(byAdding: .year, value: -2, to: now)!
        let rows = [
            FoodEstablishmentInspection(name: "A", inspectionDate: now, inspectionClosedBusiness: true, violationDescription: "Minor", violationPoints: 1),
        ]
        let summary = InspectionAggregator.summarize(rows: rows, since: cutoff)
        XCTAssertFalse(summary.isExcellent(maxViolationPoints: 50))
    }
}
