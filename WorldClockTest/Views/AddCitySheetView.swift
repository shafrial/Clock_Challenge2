//
//  AddCitySheetView.swift
//  WorldClockTest
//
//  Created by shafrial on 26/04/26.
//

import SwiftUI

struct AddCitySheetView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var searchText: String = ""

    let selectedCities: [CityTimeZone]
    let onSelectCity: (CityTimeZone) -> Void

    private var filteredCities: [CityTimeZone] {
        let availableCities = cityCatalog.filter { city in
            !selectedCities.contains { selectedCity in
                selectedCity.city == city.city &&
                selectedCity.timeZoneIdentifier == city.timeZoneIdentifier
            }
        }

        guard !searchText.isEmpty else { return availableCities }

        return availableCities.filter { city in
            city.city.localizedCaseInsensitiveContains(searchText) ||
            city.timeZoneIdentifier.localizedCaseInsensitiveContains(searchText)
        }
    }
    
    var body: some View {
        NavigationStack {
            List {
                if filteredCities.isEmpty {
                    ContentUnavailableView(
                        "No Cities Found",
                        systemImage: "magnifyingglass",
                        description: Text("Try another search.")
                    )
                    .listRowSeparator(.hidden)
                } else {
                    ForEach(filteredCities) { city in
                        Button {
                            onSelectCity(city)
                            dismiss()
                        } label: {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(city.city)
                                    .font(.body)
                                    .foregroundStyle(.primary)

                                Text(city.timeZoneIdentifier)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            .listStyle(.plain)
            .navigationTitle("Choose a city")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading){
                    Button("Cancel", systemImage: "xmark"){
                        dismiss()
                    }
                }
            }
            .searchable(text: $searchText, prompt: "Search city")
        }
    }
}

#Preview {
    AddCitySheetView(
        selectedCities: defaultCities,
        onSelectCity: { _ in }
    )
    .preferredColorScheme(.dark)
}
