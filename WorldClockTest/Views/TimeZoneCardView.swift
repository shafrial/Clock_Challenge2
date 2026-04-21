import SwiftUI

struct TimeZoneCardView: View {
    let city: CityTimeZone
    let referenceDate: Date
    let baseTZ: TimeZone

    // MARK: - Computed

    private var offset: String {
        city.offsetString(from: baseTZ, at: referenceDate)
    }

    private var isWorking: Bool {
        city.isWorkingHour(for: referenceDate)
    }

    private var isDaytime: Bool {
        city.isDaytime(for: referenceDate)
    }

    // MARK: - Theming

    private var cardBg: Color {
        city.isLocal ? Color.primary : Color(white: 0.13)
    }

    private var primaryText: Color {
        city.isLocal ? .black : .white
    }

    private var secondaryText: Color {
        city.isLocal ? Color(white: 0.45) : Color(white: 0.55)
    }

    // MARK: - Body

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            // Row 1: city name + icons
            HStack(spacing: 8) {
                Text(city.city)
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(primaryText)

                if city.isLocal {
                    Image(systemName: "location.fill")
                        .font(.system(size: 13))
                        .foregroundColor(.green)
                }

                if !offset.isEmpty {
                    Text(offset)
                        .font(.system(size: 15, weight: .medium))
                        .foregroundColor(secondaryText)
                }

                Image(systemName: isDaytime ? "sun.max.fill" : "moon.fill")
                    .font(.system(size: 15))
                    .foregroundColor(isDaytime ? .yellow : .cyan)

                Spacer()
            }

            // Row 2: large time
            HStack(alignment: .lastTextBaseline, spacing: 3) {
                Text(city.formattedHourMinute(for: referenceDate))
                    .font(.system(size: 54, weight: .thin, design: .default))
                    .foregroundColor(primaryText)

                Text(city.formattedAmPm(for: referenceDate))
                    .font(.system(size: 22, weight: .light))
                    .foregroundColor(primaryText)
            }
            .padding(.top, -2)

            // Row 3: date + status badge
            HStack(spacing: 12) {
                Text(city.formattedDate(for: referenceDate))
                    .font(.system(size: 14))
                    .foregroundColor(secondaryText)
                

                if isWorking {
                    workingBadge
                } else {
                    outsideBadge
                }
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(cardBg)
        .cornerRadius(20)
        .shadow(color: .black.opacity(0.25), radius: 4, y: 2)
    }

    // MARK: - Sub-views

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
                ForEach(CityTimeZone.defaultCities) { city in
                    TimeZoneCardView(
                        city: city,
                        referenceDate: Date(),
                        baseTZ: CityTimeZone.defaultCities[0].timeZone
                    )
                }
            }
            .padding()
        }
        .preferredColorScheme(.dark)
    }
}
