// Central place for the app's "working hours" rule.
// CityTimeZone uses these constants so the rule is not duplicated in views.
struct WorkingHours {
    // The end hour is exclusive, so 17 means working time ends before 5:00 PM.
    static let startHour: Int = 9
    static let endHour: Int = 17
}
