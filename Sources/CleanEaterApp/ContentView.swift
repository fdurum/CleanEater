import SwiftUI

struct ContentView: View {
    @StateObject private var viewModel = SearchViewModel()
    @StateObject private var recentSearches = RecentSearchStore()

    @AppStorage(SettingsKey.lookbackYears) private var lookbackYears = SettingsDefault.lookbackYears
    @AppStorage(SettingsKey.searchRadiusMiles) private var searchRadiusMiles = SettingsDefault.searchRadiusMiles
    @AppStorage(SettingsKey.showAllResults) private var showAllResults = SettingsDefault.showAllResults

    @State private var showInspector = false
    @State private var viewMode: ResultsViewMode = .list

    private var visibleResults: [CleanRestaurantResult] {
        showAllResults ? viewModel.results : viewModel.results.filter(\.summary.isClean)
    }

    var body: some View {
        NavigationSplitView {
            sidebar
        } detail: {
            detail
        }
        .inspector(isPresented: $showInspector) {
            if let selected = viewModel.selectedResult {
                RestaurantDetailView(result: selected)
            } else {
                ContentUnavailableView("No Selection", systemImage: "fork.knife.circle")
            }
        }
        .onChange(of: viewModel.selection) { _, newValue in
            showInspector = newValue != nil
        }
    }

    private var sidebar: some View {
        List {
            Section("Recent Searches") {
                if recentSearches.searches.isEmpty {
                    Text("Your searches will appear here.")
                        .foregroundStyle(.secondary)
                        .font(.callout)
                }
                ForEach(recentSearches.searches) { search in
                    Button {
                        viewModel.cuisineQuery = search.cuisineQuery
                        viewModel.locationText = search.locationText
                        runSearch()
                    } label: {
                        VStack(alignment: .leading) {
                            Text(search.cuisineQuery)
                            Text(search.locationText)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .buttonStyle(.plain)
                }
                .onDelete { offsets in
                    offsets.map { recentSearches.searches[$0] }.forEach(recentSearches.remove)
                }
            }
        }
        .navigationSplitViewColumnWidth(min: 180, ideal: 220)
    }

    private var detail: some View {
        VStack(spacing: 0) {
            searchBar
            Divider()
            Group {
                switch viewMode {
                case .list:
                    resultsList
                case .map:
                    RestaurantMapView(viewModel: viewModel, results: visibleResults, lookbackYears: lookbackYears)
                }
            }
        }
        .navigationTitle("CleanEater")
        .toolbar {
            ToolbarItem(placement: .automatic) {
                Picker("View", selection: $viewMode) {
                    ForEach(ResultsViewMode.allCases) { mode in
                        Text(mode.title).tag(mode)
                    }
                }
                .pickerStyle(.segmented)
            }
            ToolbarItem(placement: .automatic) {
                Toggle("Show All Results", isOn: $showAllResults)
                    .toggleStyle(.checkbox)
                    .help("When off, only restaurants with zero violations in the lookback window are shown.")
            }
        }
    }

    private enum ResultsViewMode: String, CaseIterable, Identifiable {
        case list, map

        var id: Self { self }

        var title: String {
            switch self {
            case .list: return "List"
            case .map: return "Map"
            }
        }
    }

    private var searchBar: some View {
        HStack {
            TextField("What (e.g. Thai food)", text: $viewModel.cuisineQuery)
                .textFieldStyle(.roundedBorder)
                .frame(minWidth: 160)
            TextField("Where (e.g. Capitol Hill, Seattle)", text: $viewModel.locationText)
                .textFieldStyle(.roundedBorder)
                .frame(minWidth: 200)
            Button {
                runSearch()
            } label: {
                if viewModel.isSearching {
                    ProgressView()
                        .controlSize(.small)
                } else {
                    Text("Search")
                }
            }
            .keyboardShortcut(.defaultAction)
            .disabled(viewModel.isSearching)
        }
        .padding()
    }

    @ViewBuilder
    private var resultsList: some View {
        if let errorMessage = viewModel.errorMessage {
            ContentUnavailableView {
                Label("Search Problem", systemImage: "exclamationmark.triangle")
            } description: {
                Text(errorMessage)
            }
        } else if viewModel.results.isEmpty && !viewModel.isSearching {
            ContentUnavailableView(
                "Search for a Restaurant",
                systemImage: "fork.knife",
                description: Text("CleanEater shows only places with zero King County health-code violations in the last \(lookbackYears) year\(lookbackYears == 1 ? "" : "s"), unless you turn on “Show All Results.”")
            )
        } else {
            Table(visibleResults, selection: $viewModel.selection) {
                TableColumn("Name") { result in
                    Text(result.place.name)
                }
                TableColumn("Address") { result in
                    Text(result.place.streetAddress ?? "—")
                        .foregroundStyle(.secondary)
                }
                TableColumn("Status") { result in
                    StatusBadge(summary: result.summary)
                }
                TableColumn("Inspections") { result in
                    Text("\(result.summary.inspectionCount)")
                }
                TableColumn("Report") { result in
                    if let businessID = result.summary.businessID,
                       let reportURL = KingCountyLink.inspectionReportURL(businessID: businessID) {
                        Link("View", destination: reportURL)
                    }
                }
                .width(60)
            }
        }
    }

    private func runSearch() {
        Task {
            await viewModel.search(lookbackYears: lookbackYears, radiusMiles: searchRadiusMiles)
            if viewModel.errorMessage == nil {
                recentSearches.record(cuisineQuery: viewModel.cuisineQuery, locationText: viewModel.locationText)
            }
        }
    }
}

#Preview {
    ContentView()
}
