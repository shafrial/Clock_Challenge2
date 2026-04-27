import SwiftUI

// Displays one city at one shared referenceDate.
// This view does not own time state. When referenceDate changes in ContentView,
// SwiftUI re-renders this card and all formatted values update automatically.
struct TimeZoneCardView: View {
    // The city data model
    let city: CityTimeZone
    // The central date selected in the app
    let referenceDate: Date
    // The time zone of the primary local city (used for calculating time offsets)
    let baseTZ: TimeZone

    // MARK: - Computed

    // Formatted string showing the time difference from the base city (e.g., "+3h").
    // It is recalculated for referenceDate because daylight saving time can change offsets.
    private var offset: String {
        city.offsetString(from: baseTZ, at: referenceDate)
    }

    // These booleans keep the body easier to read.
    // The time-zone-specific logic stays inside CityTimeZone.
    private var isWorking: Bool {
        city.isWorkingHour(for: referenceDate)
    }

    // Boolean indicating if the reference date is during daylight hours
    private var isDaytime: Bool {
        city.isDaytime(for: referenceDate)
    }

    // MARK: - Theming

    // The background color of the card. Local cities are highlighted with the primary color, others are dark gray.
    private var cardBg: Color {
        city.isLocal ? Color.primary : Color(white: 0.13)
    }

    // The primary text color, inverted based on whether it's the local city
    private var primaryText: Color {
        city.isLocal ? .black : .white
    }

    // The secondary text color, slightly adjusted based on whether it's the local city
    private var secondaryText: Color {
        city.isLocal ? Color(white: 0.45) : Color(white: 0.55)
    }

    // MARK: - Body

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            // Row 1: city name + icons
            HStack(spacing: 8) {
                // City Name
                Text(city.city)
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(primaryText)

                // Location icon displayed only for the primary local city
                if city.isLocal {
                    Image(systemName: "location.fill")
                        .font(.system(size: 13))
                        .foregroundColor(.green)
                }

                // Display the offset in hours (e.g., "+3h") if it differs from the base
                if !offset.isEmpty {
                    Text(offset)
                        .font(.system(size: 15, weight: .medium))
                        .foregroundColor(secondaryText)
                }

                // Day/Night indicator icon
                Image(systemName: isDaytime ? "sun.max.fill" : "moon.fill")
                    .font(.system(size: 15))
                    .foregroundColor(isDaytime ? .yellow : .cyan)

                Spacer()
            }

            // Row 2: large time
            HStack(alignment: .lastTextBaseline, spacing: 3) {
                // Large primary time text
                Text(city.formattedHourMinute(for: referenceDate))
                    .font(.system(size: 54, weight: .thin, design: .default))
                    .foregroundColor(primaryText)

                // Smaller AM/PM indicator aligned to the baseline
                Text(city.formattedAmPm(for: referenceDate))
                    .font(.system(size: 22, weight: .light))
                    .foregroundColor(primaryText)
            }
            .padding(.top, -2)

            // Row 3: date + status badge
            HStack(spacing: 12) {
                // Formatted date string
                Text(city.formattedDate(for: referenceDate))
                    .font(.system(size: 14))
                    .foregroundColor(secondaryText)
                
                // Visual badge showing if the time falls within working hours
                if isWorking {
                    workingBadge
                } else {
                    outsideBadge
                }
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 20)
        // Ensure the card stretches to fill the horizontal space
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(cardBg)
        .cornerRadius(20)
        // Subtle drop shadow for depth
        .shadow(color: .black.opacity(0.25), radius: 4, y: 2)
    }

    // MARK: - Sub-views

    // A green pill-shaped badge indicating working hours
    private var workingBadge: some View {
        HStack(spacing: 5) {
            Circle()
                .fill(Color.green)
                .frame(width: 7, height: 7)
            Text("Working hours")
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(.green)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 4)
        .background(Color.green.opacity(0.15))
        .cornerRadius(20)
    }
    
    // An orange pill-shaped badge indicating outside working hours
    private var outsideBadge: some View {
        HStack(spacing: 5) {
            Circle()
                .fill(Color.orange)
                .frame(width: 7, height: 7)
            Text("Outside hours")
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(.orange)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 4)
        .background(Color.orange.opacity(0.15))
        .cornerRadius(20)
    }
}

// MARK: - Preview

struct TimeZoneCardView_Previews: PreviewProvider {
    static var previews: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            VStack(spacing: 12) {
                ForEach(defaultCities) { city in
                    TimeZoneCardView(
                        city: city,
                        referenceDate: Date(),
                        baseTZ: defaultCities[0].timeZone
                    )
                }
            }
            .padding()
        }
        .preferredColorScheme(.dark)
    }
}
