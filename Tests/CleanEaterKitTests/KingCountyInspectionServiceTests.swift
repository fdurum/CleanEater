import XCTest
@testable import CleanEaterKit

final class KingCountyInspectionServiceTests: XCTestCase {
    private let baseURL = URL(string: "https://data.kingcounty.gov/resource/r878-4sxa.json")!

    func testBuildURLEscapesSingleQuotesInName() throws {
        let cutoff = Date(timeIntervalSince1970: 1_700_000_000) // fixed for a deterministic assertion
        let url = try KingCountyInspectionService.buildURL(baseURL: baseURL, name: "O'Brien's Pub", since: cutoff, limit: 500)
        let components = URLComponents(url: url, resolvingAgainstBaseURL: false)!
        let whereClause = components.queryItems?.first { $0.name == "$where" }?.value
        XCTAssertEqual(whereClause, "upper(name) like upper('%O''Brien''s Pub%') AND inspection_date >= '2023-11-14T22:13:20'")
    }

    func testBuildURLRejectsEmptyName() {
        XCTAssertThrowsError(try KingCountyInspectionService.buildURL(baseURL: baseURL, name: "   ", since: Date(), limit: 500))
    }

    func testBuildURLRejectsNonPositiveLimit() {
        XCTAssertThrowsError(try KingCountyInspectionService.buildURL(baseURL: baseURL, name: "Cafe", since: Date(), limit: 0))
    }

    func testDecodesInspectionRowsWithFractionalAndPlainDates() throws {
        let json = """
        [
          {
            "name": "SOME THAI RESTAURANT LLC",
            "address": "123 MAIN STREET",
            "city": "SEATTLE",
            "inspection_date": "2024-08-12T00:00:00.000",
            "inspection_type": "Routine Inspection",
            "inspection_result": "Satisfactory",
            "inspection_score": "5",
            "inspection_closed_business": "false",
            "violation_description": ""
          },
          {
            "name": "SOME THAI RESTAURANT LLC",
            "address": "123 MAIN STREET",
            "inspection_date": "2024-01-01",
            "inspection_closed_business": true
          }
        ]
        """.data(using: .utf8)!

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .custom(KingCountyInspectionService.decodeSocrataDate)
        let rows = try decoder.decode([FoodEstablishmentInspection].self, from: json)

        XCTAssertEqual(rows.count, 2)
        XCTAssertEqual(rows[0].inspectionScore, 5)
        XCTAssertEqual(rows[0].inspectionClosedBusiness, false)
        XCTAssertFalse(rows[0].isViolationRow)
        XCTAssertTrue(rows[1].inspectionClosedBusiness)
    }
}
