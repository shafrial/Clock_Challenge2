import SwiftUI
internal import Combine

// ContentView is the coordinator for the screen.
// It owns the important app state, passes that state into child views,
// and receives events back from children through callback closures.
struct ContentView: View {

    // MARK: - State

    // This is the single source of truth for "the time the app is showing".
    // Every time-zone card and the horizontal dial reads from this same Date.
    @State private var referenceDate: Date = Date()

    // When false, the timer below keeps replacing referenceDate with Date().
    // When true, the user has chosen a custom time/date, so the live clock stops
    // until the user taps "Reset to now".
    @State private var isLiveClockPaused: Bool = false

    // Controls the presentation of the Share proposal sheet
    @State private var showShare: Bool = false

    // Controls the presentation of the Calendar date picker sheet
    @State private var showCalendar: Bool = false

    // Controls the presentation of the Add City search sheet
    @State private var showAddCitySheet: Bool = false

    // The user's currently selected list of cities
    @State private var cities: [CityTimeZone] = defaultCities

    // The first city is treated as the user's base/local city.
    // Other views use this to calculate offsets and to interpret calendar days.
    private var baseTZ: TimeZone { cities[0].timeZone }

    // A timer that fires every second to keep the clock updating in real-time.
    // It only changes the UI while isLiveClockPaused is false.
    private let ticker = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    // MARK: - Body

    var body: some View {
        NavigationStack{
            ZStack {
                VStack(spacing: 0) {
                    // Child views do not own the city list or selected date.
                    // They receive the data from ContentView so the screen stays synchronized.
                    TimeZoneCardListView(
                        cities: cities,
                        referenceDate: referenceDate,
                        baseTZ: baseTZ,
                        onDeleteCity: { city in
                            // TimeZoneCardListView only reports which city was deleted.
                            // ContentView performs the actual state mutation.
                            deleteCity(city)
                        }
                    )
                    
                    // The dial converts scrolling into a Date, then sends that Date
                    // back through onDateChange. ContentView decides what to do with it.
                    HorizontalDialSliderView(
                        referenceDate: referenceDate,
                        baseTZ: baseTZ,
                        onDateChange: { newDate in
                            selectReferenceDate(newDate)
                        }
                    )
                }
            }
            // This keeps the app live while the user is not manually exploring another time.
            .onReceive(ticker) { _ in
                guard !isLiveClockPaused else { return }
                referenceDate = Date()
            }
            .navigationTitle("Match Time")
            .toolbar {
                // Top right button to add a new city
                ToolbarItem(placement: .topBarTrailing){
                    Button("", systemImage: "plus"){
                        showAddCitySheet = true
                    }
                }
                // Bottom left button to pick a specific date
                ToolbarItem(placement: .bottomBar){
                    Button("", systemImage: "calendar"){
                        showCalendar =  true
                    }
                }
                // Flexible spacer
                ToolbarItem(placement: .bottomBar) {
                        Spacer()
                }
                // Center button that only appears if the user has manually changed the time
                ToolbarItem(placement: .bottomBar) {
                    if isLiveClockPaused {
                        Button("Reset to now") {
                            resetToNow()
                        }
                    }
                }
                // Flexible spacer
                ToolbarItem(placement: .bottomBar) {
                        Spacer()
                }
                // Bottom right button to share the proposed time
                ToolbarItem(placement: .bottomBar){
                    Button("", systemImage: "square.and.arrow.up"){
                        showShare = true
                    }
                }
            }
        }
        // Sheet for searching and adding new cities
        .sheet(isPresented: $showAddCitySheet){
            AddCitySheetView(
                selectedCities: cities,
                onSelectCity: { city in
                    // The sheet sends the selected city back here.
                    // Keeping the append logic in ContentView prevents the sheet
                    // from directly owning or mutating the main city list.
                    addCity(city)
                }
            )
        }
        // Sheet for generating and sharing a meeting proposal message
        .sheet(isPresented: $showShare){
            ShareProposalView(cities: cities, referenceDate: referenceDate)
        }
        // Sheet for picking a specific calendar date
        .sheet(isPresented: $showCalendar){
            CalendarSheetView(
                selectedDate: referenceDate,
                onSelectDate: { selectedDay in
                    // CalendarSheetView selects only a day.
                    // ContentView combines that day with the current time.
                    selectDay(selectedDay)
                }
            )
            .environment(\.timeZone, baseTZ)
        }
    }
        
    // MARK: - Helpers

    // Any manual time change goes through this helper.
    // That gives one consistent rule: manual selection pauses the live clock.
    private func selectReferenceDate(_ newDate: Date) {
        isLiveClockPaused = true
        referenceDate = newDate
    }

    // Resumes the live clock and immediately returns the app to the current time.
    private func resetToNow() {
        isLiveClockPaused = false
        referenceDate = Date()
    }

    // Appends a new city to the list if it is not already present.
    // The duplicate check uses city + time zone because UUID is different
    // for every CityTimeZone instance.
    private func addCity(_ city: CityTimeZone) {
        guard !cities.contains(where: { existingCity in
            existingCity.city == city.city &&
            existingCity.timeZoneIdentifier == city.timeZoneIdentifier
        }) else { return }

        cities.append(city)
    }

    // Removes a city from the list, but never removes the local/base city.
    // The first city is important because baseTZ depends on it.
    private func deleteCity(_ city: CityTimeZone) {
        guard !city.isLocal else { return }

        cities.removeAll { existingCity in
            existingCity.city == city.city &&
            existingCity.timeZoneIdentifier == city.timeZoneIdentifier
        }
    }

    // Calendar selection changes the day, not the current hour/minute.
    // Example: if the app shows 14:30 and user picks Friday,
    // the result should be Friday at 14:30 in the base time zone.
    private func selectDay(_ selectedDay: Date) {
        selectReferenceDate(dateByKeepingCurrentTime(on: selectedDay))
    }

    // Merges the selected calendar day with the current selected time.
    // This uses baseTZ so "day" means the day in the user's local/base city,
    // not accidentally the device/default calendar time zone.
    private func dateByKeepingCurrentTime(on selectedDay: Date) -> Date {
        var cal = Calendar.current
        cal.timeZone = baseTZ

        // Extract day components from the chosen calendar day
        let day = cal.dateComponents([.year, .month, .day], from: selectedDay)
        // Extract time components from the currently active reference date
        let time = cal.dateComponents([.hour, .minute, .second, .nanosecond], from: referenceDate)

        // Combine them into a single DateComponents object
        var components = DateComponents()
        components.timeZone = baseTZ
        components.year = day.year
        components.month = day.month
        components.day = day.day
        components.hour = time.hour
        components.minute = time.minute
        components.second = time.second
        components.nanosecond = time.nanosecond

        // Generate and return the new Date, falling back to the selected day if it fails
        return cal.date(from: components) ?? selectedDay
    }
}

// MARK: - Preview
#Preview {
    ContentView().preferredColorScheme(.dark)
}
