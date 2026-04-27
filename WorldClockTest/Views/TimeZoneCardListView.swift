import SwiftUI

// Displays all selected city cards and owns the list-specific behavior.
// ContentView still owns the city data; this view only renders it and reports
// delete actions through onDeleteCity.
struct TimeZoneCardListView: View {
    let cities: [CityTimeZone]
    let referenceDate: Date
    let baseTZ: TimeZone

    // Callback to tell the parent which city should be deleted.
    // The parent performs the actual mutation so all city state remains in one place.
    let onDeleteCity: (CityTimeZone) -> Void

    var body: some View {
        List {
            ForEach(cities) { city in
                // One card is responsible for displaying one city's local time.
                TimeZoneCardView(
                    city: city,
                    referenceDate: referenceDate,
                    baseTZ: baseTZ
                )
                .listRowInsets(
                    EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16)
                )
                .listRowSeparator(.hidden)
                .listRowBackground(Color.clear)
                // List gives us native swipe actions.
                // Full swipe is disabled for the local city because deleteCity also
                // protects it, and the UI should communicate the same rule.
                .swipeActions(edge: .trailing, allowsFullSwipe: !city.isLocal) {
                    if !city.isLocal {
                        Button(role: .destructive) {
                            onDeleteCity(city)
                        } label: {
                            Label("Delete", systemImage: "trash")
                        }
                    }
                }
            }
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
    }
}

#Preview {
    TimeZoneCardListView(
        cities: defaultCities,
        referenceDate: Date(),
        baseTZ: defaultCities[0].timeZone,
        onDeleteCity: { _ in }
    )
    .preferredColorScheme(.dark)
}
