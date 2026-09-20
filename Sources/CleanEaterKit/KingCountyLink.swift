import Foundation

/// Builds a link to King County's public ArcGIS Experience Builder inspection map,
/// pre-filtered and zoomed to one business by its stable `business_id`.
///
/// Confirmed against a real share link copied from King County's site:
/// `https://experience.arcgis.com/experience/d7adc44a99e8406fbf86bdaf0a856136/page/Home-Page#data_s=where:dataSource_4-19cdd730adc-layer-18:Business_Record_ID='PFE-PR-3147569'&zoom_to_selection=true`
/// filters the map to that one business, using the same identifier Socrata exposes as
/// `business_id` (`FoodEstablishmentInspection.businessID`).
///
/// Everything after `#` is a URL fragment that the app's own JavaScript parses
/// client-side — it's never sent to a server, so this only works opened in a browser,
/// not as an API call.
public enum KingCountyLink {
    private static let experienceAppID = "d7adc44a99e8406fbf86bdaf0a856136"
    private static let businessLayerDataSourceID = "dataSource_4-19cdd730adc-layer-18"

    /// Characters left unescaped in the `data_s` fragment value, matching the encoding
    /// King County's own share links use (everything else — notably `:`, `=`, `'` — is
    /// percent-encoded).
    private static let fragmentValueAllowedCharacters: CharacterSet = {
        var allowed = CharacterSet.alphanumerics
        allowed.insert(charactersIn: "-_")
        return allowed
    }()

    public static func inspectionReportURL(businessID: String) -> URL? {
        let trimmedID = businessID.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedID.isEmpty else { return nil }

        // Business IDs are King County's own fixed-format identifiers and don't
        // contain quotes, but escape defensively since this drops straight into a
        // quoted clause.
        let escapedID = trimmedID.replacingOccurrences(of: "'", with: "''")
        let whereClause = "where:\(businessLayerDataSourceID):Business_Record_ID='\(escapedID)'"
        guard let encodedWhereClause = whereClause.addingPercentEncoding(withAllowedCharacters: fragmentValueAllowedCharacters) else {
            return nil
        }

        return URL(string: "https://experience.arcgis.com/experience/\(experienceAppID)/page/Home-Page#data_s=\(encodedWhereClause)&zoom_to_selection=true")
    }
}
