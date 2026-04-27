// Cities shown when the app first launches.
// The first city is treated as the local/base city by ContentView.
let defaultCities: [CityTimeZone] = [
    CityTimeZone(city: "Bali", timeZoneIdentifier: "Asia/Makassar", isLocal: true),
]

// Static MVP catalog used by AddCitySheetView.
// Each entry uses an IANA time zone identifier so Foundation can calculate
// daylight saving time and offsets correctly.
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
