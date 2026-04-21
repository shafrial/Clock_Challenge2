import SwiftUI

// MARK: - City Time Zone Model

struct CityTimeZone: Identifiable {
    let id: UUID
    let city: String
    let timeZoneIdentifier: String
    let isLocal: Bool

    init(city: String, timeZoneIdentifier: String, isLocal: Bool = false) {
        self.id = UUID()
        self.city = city
        self.timeZoneIdentifier = timeZoneIdentifier
        self.isLocal = isLocal
    }

    var timeZone: TimeZone {
        TimeZone(identifier: timeZoneIdentifier) ?? .current
    }

    // MARK: - Time Formatting

    func formattedHourMinute(for date: Date) -> String {
        let f = DateFormatter()
        f.timeZone = timeZone
        f.dateFormat = "h:mm"
        return f.string(from: date)
    }

    func formattedAmPm(for date: Date) -> String {
        let f = DateFormatter()
        f.timeZone = timeZone
        f.dateFormat = "a"
        return f.string(from: date).lowercased()
    }

    func formattedDate(for date: Date) -> String {
        let f = DateFormatter()
        f.timeZone = timeZone
        f.dateFormat = "EEE, MMM d"
        return f.string(from: date)
    }

    func formattedShareTime(for date: Date) -> String {
        let f = DateFormatter()
        f.timeZone = timeZone
        f.dateFormat = "h:mm a"
        return f.string(from: date)
    }

    // MARK: - Time State Checks

    func hour(for date: Date) -> Int {
        var cal = Calendar.current
        cal.timeZone = timeZone
        return cal.component(.hour, from: date)
    }

    func isWorkingHour(for date: Date) -> Bool {
        let h = hour(for: date)
        return h >= 9 && h < 17
    }

    func isDaytime(for date: Date) -> Bool {
        let h = hour(for: date)
        return h >= 6 && h < 20
    }

    // MARK: - Offset

    func offsetString(from base: TimeZone, at date: Date) -> String {
        let myOffset = timeZone.secondsFromGMT(for: date)
        let baseOffset = base.secondsFromGMT(for: date)
        let diffHours = (myOffset - baseOffset) / 3600
        guard diffHours != 0 else { return "" }
        return diffHours > 0 ? "+\(diffHours)h" : "\(diffHours)h"
    }
}

// MARK: - Hard-coded Cities

extension CityTimeZone {
    static let defaultCities: [CityTimeZone] = [
        CityTimeZone(city: "Bali",     timeZoneIdentifier: "Asia/Makassar",     isLocal: true),
        CityTimeZone(city: "New York", timeZoneIdentifier: "America/New_York",  isLocal: false),
        CityTimeZone(city: "Sydney",   timeZoneIdentifier: "Australia/Sydney",  isLocal: false),
    ]
}

// MARK: - Working Hours Config

struct WorkingHours {
    static let startHour: Int = 9
    static let endHour: Int = 17
}
