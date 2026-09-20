import XCTest
@testable import CleanEaterKit

final class RestaurantMatcherTests: XCTestCase {
    func testMatchesDespiteLegalSuffixAndCasing() {
        let place = PlaceCandidate(
            id: "1",
            name: "Some Thai Restaurant",
            streetAddress: "123 Main St",
            city: "Seattle",
            coordinate: Coordinate(latitude: 47.6, longitude: -122.3)
        )
        let inspection = FoodEstablishmentInspection(
            name: "SOME THAI RESTAURANT LLC",
            address: "123 MAIN STREET",
            inspectionDate: Date()
        )
        XCTAssertTrue(RestaurantMatcher.isMatch(place: place, inspection: inspection))
    }

    func testRejectsSameNameDifferentStreetNumber() {
        // Chains: same name, different physical location.
        let place = PlaceCandidate(
            id: "1",
            name: "Taco Time",
            streetAddress: "100 Main St",
            city: "Seattle",
            coordinate: Coordinate(latitude: 47.6, longitude: -122.3)
        )
        let inspection = FoodEstablishmentInspection(
            name: "TACO TIME",
            address: "900 Main St",
            inspectionDate: Date()
        )
        XCTAssertFalse(RestaurantMatcher.isMatch(place: place, inspection: inspection))
    }

    func testRejectsUnrelatedNames() {
        let place = PlaceCandidate(
            id: "1",
            name: "Bangkok Restaurant",
            streetAddress: "123 Main St",
            city: "Seattle",
            coordinate: Coordinate(latitude: 47.6, longitude: -122.3)
        )
        let inspection = FoodEstablishmentInspection(
            name: "Pike Place Chowder",
            address: "123 Main St",
            inspectionDate: Date()
        )
        XCTAssertFalse(RestaurantMatcher.isMatch(place: place, inspection: inspection))
    }

    func testMissingAddressFallsBackToNameOnly() {
        let place = PlaceCandidate(
            id: "1",
            name: "Bangkok Restaurant",
            streetAddress: nil,
            city: nil,
            coordinate: Coordinate(latitude: 47.6, longitude: -122.3)
        )
        let inspection = FoodEstablishmentInspection(
            name: "Bangkok Restaurant",
            address: nil,
            inspectionDate: Date()
        )
        XCTAssertTrue(RestaurantMatcher.isMatch(place: place, inspection: inspection))
    }
}
