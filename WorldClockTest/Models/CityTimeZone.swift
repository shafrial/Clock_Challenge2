import Foundation

// Core data model for a city shown in the app.
// It stores the city identity and also provides small helper methods for
// formatting the same absolute Date in that city's time zone.
struct CityTimeZone: Identifiable {
    // UUID makes each row identifiable for SwiftUI.
    // Duplicate prevention is handled manually in ContentView/AddCitySheetView
    // because two CityTimeZone instances with the same city still get different UUIDs.
    let id: UUID
    let city: String
    let timeZoneIdentifier: String

    // The local city is special: it becomes the base time zone and cannot be deleted.
    let isLocal: Bool

    init(city: String, timeZoneIdentifier: String, isLocal: Bool = false) {
        self.id = UUID()
        self.city = city
        self.timeZoneIdentifier = timeZoneIdentifier
        self.isLocal = isLocal
    }

    var timeZone: TimeZone {
        // Fallback to .current prevents a crash if a time zone identifier is mistyped.
        TimeZone(identifier: timeZoneIdentifier) ?? .current
    }

    var displayTimeZoneIdentifier: String {
        timeZoneIdentifier.replacingOccurrences(of: "_", with: " ")
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
        return h >= WorkingHours.startHour && h < WorkingHours.endHour
    }

    func isDaytime(for date: Date) -> Bool {
        let h = hour(for: date)
        return h >= 6 && h < 18
    }

    // MARK: - Offset

    func offsetString(from base: TimeZone, at date: Date) -> String {
        // Offsets are calculated at the selected date because daylight saving time
        // can make the difference between two cities change during the year.
        let myOffset = timeZone.secondsFromGMT(for: date)
        let baseOffset = base.secondsFromGMT(for: date)
        let diffHours = (myOffset - baseOffset) / 3600
        guard diffHours != 0 else { return "" }
        return diffHours > 0 ? "+\(diffHours)h" : "\(diffHours)h"
    }
}
