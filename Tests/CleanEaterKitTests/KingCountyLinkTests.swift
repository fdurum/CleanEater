import XCTest
@testable import CleanEaterKit

final class KingCountyLinkTests: XCTestCase {
    func testBuildsLinkWithNameFilter() throws {
        let url = try XCTUnwrap(KingCountyLink.inspectionReportURL(forRestaurantNamed: "Bangkok Restaurant"))
        XCTAssertEqual(url.host, "data.kingcounty.gov")
        XCTAssertTrue(url.path.hasSuffix("/r878-4sxa"))

        let components = try XCTUnwrap(URLComponents(url: url, resolvingAgainstBaseURL: false))
        XCTAssertEqual(components.queryItems, [URLQueryItem(name: "name", value: "Bangkok Restaurant")])
    }

    func testReturnsNilForEmptyName() {
        XCTAssertNil(KingCountyLink.inspectionReportURL(forRestaurantNamed: "   "))
    }
}
