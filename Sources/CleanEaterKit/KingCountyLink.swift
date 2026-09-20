import Foundation

/// Builds a browser-facing link to King County's public dataset page for a
/// restaurant, so the UI can offer "view the source record" alongside the
/// app's own summary.
///
/// UNVERIFIED: written in an environment with no network access to
/// `data.kingcounty.gov`, so this could not be checked against the live site.
/// The base URL (King County's Socrata dataset page for `r878-4sxa`) is solid —
/// it's the same one from the original research this app was built from. The
/// `?name=` filter is Socrata's long-standing convention for a simple
/// single-column equality filter on a dataset's human-facing grid page, but
/// that behavior specifically has not been confirmed live. Open a generated
/// link in a browser and confirm it actually filters to the right restaurant
/// before relying on it; if it doesn't, this is the one place to fix.
public enum KingCountyLink {
    private static let datasetPageURL = "https://data.kingcounty.gov/Health-Wellness/Food-Establishment-Inspection-Data/r878-4sxa"

    public static func inspectionReportURL(forRestaurantNamed name: String) -> URL? {
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedName.isEmpty, var components = URLComponents(string: datasetPageURL) else {
            return nil
        }
        components.queryItems = [URLQueryItem(name: "name", value: trimmedName)]
        return components.url
    }
}
