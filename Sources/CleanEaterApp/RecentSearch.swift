import Foundation

struct RecentSearch: Identifiable, Codable, Hashable {
    let id: UUID
    var cuisineQuery: String
    var locationText: String
    var date: Date

    init(id: UUID = UUID(), cuisineQuery: String, locationText: String, date: Date = Date()) {
        self.id = id
        self.cuisineQuery = cuisineQuery
        self.locationText = locationText
        self.date = date
    }

    var displayTitle: String {
        locationText.isEmpty ? cuisineQuery : "\(cuisineQuery) near \(locationText)"
    }
}

/// Persists the sidebar's recent-search list to `UserDefaults` as JSON. A dozen
/// entries of two short strings and a date is well within reasonable `UserDefaults`
/// use; this isn't data that warrants a database.
@MainActor
final class RecentSearchStore: ObservableObject {
    @Published private(set) var searches: [RecentSearch] = []

    private let defaultsKey = "recentSearches"
    private let maxEntries = 15
    private let defaults: UserDefaults

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        load()
    }

    func record(cuisineQuery: String, locationText: String) {
        let entry = RecentSearch(cuisineQuery: cuisineQuery, locationText: locationText)
        searches.removeAll { $0.cuisineQuery == cuisineQuery && $0.locationText == locationText }
        searches.insert(entry, at: 0)
        if searches.count > maxEntries {
            searches.removeLast(searches.count - maxEntries)
        }
        save()
    }

    func remove(_ search: RecentSearch) {
        searches.removeAll { $0.id == search.id }
        save()
    }

    private func load() {
        guard let data = defaults.data(forKey: defaultsKey) else { return }
        searches = (try? JSONDecoder().decode([RecentSearch].self, from: data)) ?? []
    }

    private func save() {
        guard let data = try? JSONEncoder().encode(searches) else { return }
        defaults.set(data, forKey: defaultsKey)
    }
}
