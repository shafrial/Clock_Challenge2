//
//  AddCitySheetView.swift
//  WorldClockTest
//
//  Created by shafrial on 26/04/26.
//

import SwiftUI

// A sheet that provides a searchable list to add a new city from the global catalog
struct AddCitySheetView: View {
    // Environment property to close the sheet programmatically
    @Environment(\.dismiss) private var dismiss
    // State to bind the search bar input
    @State private var searchText: String = ""

    // The list of cities the user has already added, passed in to filter them out of the catalog
    let selectedCities: [CityTimeZone]
    // Callback executed when the user taps on a city to add it
    let onSelectCity: (CityTimeZone) -> Void

    // Dynamically computes the list of cities to display based on existing selections and the search text
    private var filteredCities: [CityTimeZone] {
        // First, filter out any cities the user already has in their main list
        let availableCities = cityCatalog.filter { city in
            !selectedCities.contains { selectedCity in
                selectedCity.city == city.city &&
                selectedCity.timeZoneIdentifier == city.timeZoneIdentifier
            }
        }

        // If the user isn't searching, return all available unselected cities
        guard !searchText.isEmpty else { return availableCities }

        // Filter the available cities by matching the search text against city name or time zone identifier
        return availableCities.filter { city in
            city.city.localizedCaseInsensitiveContains(searchText) ||
            city.timeZoneIdentifier.localizedCaseInsensitiveContains(searchText)
        }
    }
    
    var body: some View {
        NavigationStack {
            List {
                // Display an empty state if the search yields no results
                if filteredCities.isEmpty {
                    ContentUnavailableView(
                        "No Cities Found",
                        systemImage: "magnifyingglass",
                        description: Text("Try another search.")
                    )
                    .listRowSeparator(.hidden)
                } else {
                    // Display the filtered cities as tappable buttons
                    ForEach(filteredCities) { city in
                        Button {
                            // Trigger the add callback and close the sheet
                            onSelectCity(city)
                            dismiss()
                        } label: {
                            VStack(alignment: .leading, spacing: 4) {
                                // City Name
                                Text(city.city)
                                    .font(.body)
                                    .foregroundStyle(.primary)

                                // Time Zone Identifier
                                Text(city.timeZoneIdentifier)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            // Ensure the entire row area is tappable
                            .contentShape(Rectangle())
                        }
                        // Use plain style to avoid default blue text on buttons
                        .buttonStyle(.plain)
                    }
                }
            }
            .listStyle(.plain)
            .navigationTitle("Choose a city")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                // Top-left cancel button to close the sheet without adding
                ToolbarItem(placement: .topBarLeading){
                    Button("Cancel", systemImage: "xmark"){
                        dismiss()
                    }
                }
            }
            // Attaches a standard iOS search bar to the navigation stack
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