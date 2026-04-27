import SwiftUI

// MARK: - City Time Zone Model

// Represents a city and its associated time zone, providing utility methods for time formatting and status checks.
struct CityTimeZone: Identifiable {
    // Unique identifier for the list
    let id: UUID
    // Display name of the city
    let city: String
    // Standard IANA time zone identifier (e.g., "America/New_York")
    let timeZoneIdentifier: String
    // Flags if this city is the local/base city
    let isLocal: Bool

    init(city: String, timeZoneIdentifier: String, isLocal: Bool = false) {
        self.id = UUID()
        self.city = city
        self.timeZoneIdentifier = timeZoneIdentifier
        self.isLocal = isLocal
    }

    // Resolves the string identifier into an actual TimeZone object, falling back to the current device time zone if invalid
    var timeZone: TimeZone {
        TimeZone(identifier: timeZoneIdentifier) ?? .current
    }

    // MARK: - Time Formatting

    // Returns the hour and minute (e.g., "4:30") for a given date in this city's time zone
    func formattedHourMinute(for date: Date) -> String {
        let f = DateFormatter()
        f.timeZone = timeZone
        f.dateFormat = "h:mm"
        return f.string(from: date)
    }

    // Returns the AM/PM designator (e.g., "am") for a given date in this city's time zone
    func formattedAmPm(for date: Date) -> String {
        let f = DateFormatter()
        f.timeZone = timeZone
        f.dateFormat = "a"
        return f.string(from: date).lowercased()
    }

    // Returns a formatted date string (e.g., "Mon, Jan 1") for a given date in this city's time zone
    func formattedDate(for date: Date) -> String {
        let f = DateFormatter()
        f.timeZone = timeZone
        f.dateFormat = "EEE, MMM d"
        return f.string(from: date)
    }

    // Returns a complete time string for sharing purposes (e.g., "4:30 PM")
    func formattedShareTime(for date: Date) -> String {
        let f = DateFormatter()
        f.timeZone = timeZone
        f.dateFormat = "h:mm a"
        return f.string(from: date)
    }

    // MARK: - Time State Checks

    // Extracts just the hour component from a date in this city's time zone
    func hour(for date: Date) -> Int {
        var cal = Calendar.current
        cal.timeZone = timeZone
        return cal.component(.hour, from: date)
    }

    // Determines if the given date falls within typical working hours (9 AM to 5 PM)
    func isWorkingHour(for date: Date) -> Bool {
        let h = hour(for: date)
        return h >= 9 && h < 17
    }

    // Determines if the given date is during the daytime (6 AM to 6 PM)
    func isDaytime(for date: Date) -> Bool {
        let h = hour(for: date)
        return h >= 6 && h < 18
    }

    // MARK: - Offset

    // Calculates the time difference in hours between this city and a base time zone
    func offsetString(from base: TimeZone, at date: Date) -> String {
        // Get total seconds from GMT for both time zones at the specific date
        let myOffset = timeZone.secondsFromGMT(for: date)
        let baseOffset = base.secondsFromGMT(for: date)
        
        // Calculate the difference in hours
        let diffHours = (myOffset - baseOffset) / 3600
        
        // If there's no difference, return an empty string
        guard diffHours != 0 else { return "" }
        
        // Format with a "+" sign for positive offsets
        return diffHours > 0 ? "+\(diffHours)h" : "\(diffHours)h"
    }
}

// MARK: - City Data

// The initial list of cities loaded when the app starts
let defaultCities: [CityTimeZone] = [
    CityTimeZone(city: "Bali",     timeZoneIdentifier: "Asia/Makassar",     isLocal: true),
]

// The full catalog of cities available for the user to add
let cityCatalog: [CityTimeZone] = [
    CityTimeZone(city: "Bali", timeZoneIdentifier: "Asia/Makassar", isLocal: true),
    CityTimeZone(city: "New York", timeZoneIdentifier: "America/New_York"),
    CityTimeZone(city: "Los Angeles", timeZoneIdentifier: "America/Los_Angeles"),
    CityTimeZone(city: "San Francisco", timeZoneIdentifier: "America/Los_Angeles"),
    CityTimeZone(city: "Chicago", timeZoneIdentifier: "America/Chicago"),
    CityTimeZone(city: "Toronto", timeZoneIdentifier: "America/Toronto"),
    CityTimeZone(city: "Mexico City", timeZoneIdentifier: "America/Mexico_City"),
    CityTimeZone(city: "Sao Paulo", timeZoneIdentifier: "America/Sao_Paulo"),
    CityTimeZone(city: "London", timeZoneIdentifier: "Europe/London"),
    CityTimeZone(city: "Paris", timeZoneIdentifier: "Europe/Paris"),
    CityTimeZone(city: "Berlin", timeZoneIdentifier: "Europe/Berlin"),
    CityTimeZone(city: "Amsterdam", timeZoneIdentifier: "Europe/Amsterdam"),
    CityTimeZone(city: "Madrid", timeZoneIdentifier: "Europe/Madrid"),
    CityTimeZone(city: "Rome", timeZoneIdentifier: "Europe/Rome"),
    CityTimeZone(city: "Dubai", timeZoneIdentifier: "Asia/Dubai"),
    CityTimeZone(city: "Mumbai", timeZoneIdentifier: "Asia/Kolkata"),
    CityTimeZone(city: "Bangkok", timeZoneIdentifier: "Asia/Bangkok"),
    CityTimeZone(city: "Jakarta", timeZoneIdentifier: "Asia/Jakarta"),
    CityTimeZone(city: "Singapore", timeZoneIdentifier: "Asia/Singapore"),
    CityTimeZone(city: "Hong Kong", timeZoneIdentifier: "Asia/Hong_Kong"),
    CityTimeZone(city: "Shanghai", timeZoneIdentifier: "Asia/Shanghai"),
    CityTimeZone(city: "Seoul", timeZoneIdentifier: "Asia/Seoul"),
    CityTimeZone(city: "Tokyo", timeZoneIdentifier: "Asia/Tokyo"),
    CityTimeZone(city: "Sydney", timeZoneIdentifier: "Australia/Sydney"),
    CityTimeZone(city: "Melbourne", timeZoneIdentifier: "Australia/Melbourne"),
    CityTimeZone(city: "Auckland", timeZoneIdentifier: "Pacific/Auckland"),
    CityTimeZone(city: "Cairo", timeZoneIdentifier: "Africa/Cairo"),
    CityTimeZone(city: "Johannesburg", timeZoneIdentifier: "Africa/Johannesburg"),
    CityTimeZone(city: "Nairobi", timeZoneIdentifier: "Africa/Nairobi"),
]
// MARK: - Working Hours Config

// Configuration constants defining what constitutes a working hour
struct WorkingHours {
    static let startHour: Int = 9
    static let endHour: Int = 17
}