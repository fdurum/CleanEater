import XCTest
@testable import CleanEater

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

    /// Regression test: `inspection_score` comes back from the live API as a
    /// decimal-formatted string (e.g. `"0.00"`, `"15.00"`), which `Int(String)`
    /// rejects outright. This was silently dropping every row's score to nil.
    func testDecodesDecimalFormattedInspectionScore() throws {
        let json = """
        [{ "name": "A", "inspection_date": "2024-08-02", "inspection_score": "15.00" }]
        """.data(using: .utf8)!

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .custom(KingCountyInspectionService.decodeSocrataDate)
        let rows = try decoder.decode([FoodEstablishmentInspection].self, from: json)

        XCTAssertEqual(rows[0].inspectionScore, 15.0)
    }

    /// Decodes a real row pulled live from the API, confirming the fields
    /// `FoodEstablishmentInspection` didn't previously model: `classification`,
    /// `seating_range`, `risk_category`, `grade`, `parcel_number`, `business_id`, and
    /// `inspection_serial_num`.
    func testDecodesRealSampleRowWithAllFields() throws {
        let json = """
        [{"name":"#807 TUTTA BELLA","inspection_date":"2025-03-24T00:00:00.000","classification":"General Food Services","address":"2746 NE 45TH ST","city":"SEATTLE","zip_code":"98105","inspection_type":"Routine Inspection/Field Review","inspection_score":"5.00","inspection_result":"Unsatisfactory","inspection_closed_business":"No","seating_range":"0-12","risk_category":"3","violation_type":"RED","violation_description":"2120 - Proper cold holding temperatures; between 42 to 45 degrees Fahrenheit (F) (6 to 7 degrees Celsius (C))","violation_points":"5","grade":"Excellent","parcel_number":"0925049330","business_id":"PFE-PR-3147569","inspection_serial_num":"PFE-DA05TOC3V"}]
        """.data(using: .utf8)!

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .custom(KingCountyInspectionService.decodeSocrataDate)
        let row = try decoder.decode([FoodEstablishmentInspection].self, from: json)[0]

        XCTAssertEqual(row.classification, "General Food Services")
        XCTAssertEqual(row.inspectionScore, 5.0)
        XCTAssertEqual(row.seatingRange, "0-12")
        XCTAssertEqual(row.riskCategory, "3")
        XCTAssertEqual(row.grade, "Excellent")
        XCTAssertEqual(row.parcelNumber, "0925049330")
        XCTAssertEqual(row.businessID, "PFE-PR-3147569")
        XCTAssertEqual(row.inspectionSerialNumber, "PFE-DA05TOC3V")
        XCTAssertTrue(row.isViolationRow)
    }
}
