import SwiftUI

struct TimeZoneCardListView: View {
    let cities: [CityTimeZone]
    let referenceDate: Date
    let baseTZ: TimeZone
    let onDeleteCity: (CityTimeZone) -> Void

    var body: some View {
        List {
            ForEach(cities) { city in
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
