import XCTest
@testable import CleanEater

final class KingCountyLinkTests: XCTestCase {
    func testBuildsExpectedLinkForBusinessID() throws {
        let url = try XCTUnwrap(KingCountyLink.inspectionReportURL(businessID: "PFE-PR-3147569"))
        XCTAssertEqual(
            url.absoluteString,
            "https://experience.arcgis.com/experience/d7adc44a99e8406fbf86bdaf0a856136/page/Home-Page#data_s=where%3AdataSource_4-19cdd730adc-layer-18%3ABusiness_Record_ID%3D%27PFE-PR-3147569%27&zoom_to_selection=true"
        )
    }

    func testReturnsNilForEmptyBusinessID() {
        XCTAssertNil(KingCountyLink.inspectionReportURL(businessID: "   "))
    }
}
