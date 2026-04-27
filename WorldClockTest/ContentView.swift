import SwiftUI
internal import Combine

struct ContentView: View {

    // MARK: - State

    // The central date that all views synchronize with. Defaults to current date/time.
    @State private var referenceDate: Date = Date()
    // Tracks whether the live ticking clock is paused (happens when user interacts with the timeline)
    @State private var isLiveClockPaused: Bool = false
    // Controls the presentation of the Share proposal sheet
    @State private var showShare: Bool = false
    // Controls the presentation of the Calendar date picker sheet
    @State private var showCalendar: Bool = false
    // Controls the presentation of the Add City search sheet
    @State private var showAddCitySheet: Bool = false
    // The user's currently selected list of cities
    @State private var cities: [CityTimeZone] = defaultCities

    // Computes the base time zone using the first city in the list (assumed to be local)
    private var baseTZ: TimeZone { cities[0].timeZone }

    // A timer that fires every second to keep the clock updating in real-time.
    // It auto-connects upon view creation.
    private let ticker = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    // MARK: - Body

    var body: some View {
        NavigationStack{
            ZStack {
                VStack(spacing: 0) {
                    // List of all selected cities displaying their respective times
                    List {
                        ForEach(cities) { city in
                            TimeZoneCardView(
                                city: city,
                                referenceDate: referenceDate,
                                baseTZ: baseTZ
                            )
                            // Remove default list padding and styling for a cleaner look
                            .listRowInsets(
                                EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16)
                            )
                            .listRowSeparator(.hidden)
                            .listRowBackground(Color.clear)
                            // Allow users to delete non-local cities with a swipe gesture
                            .swipeActions(edge: .trailing, allowsFullSwipe: !city.isLocal) {
                                if !city.isLocal {
                                    Button(role: .destructive) {
                                        deleteCity(city)
                                    } label: {
                                        Label("Delete", systemImage: "trash")
                                    }
                                }
                            }
                        }
                    }
                    .listStyle(.plain)
                    .scrollContentBackground(.hidden)
                    
                    // The custom timeline slider for adjusting the time manually
                    HorizontalDialSliderView(
                        referenceDate: referenceDate,
                        baseTZ: baseTZ,
                        onDateChange: { newDate in
                            // When the user drags the slider, update the global reference date
                            selectReferenceDate(newDate)
                        }
                    )
                }
            }
            // Listen to the 1-second timer to update the reference date if not paused
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
                    selectDay(selectedDay)
                }
            )
            .environment(\.timeZone, baseTZ)
        }
    }
        
    // MARK: - Helpers

    // Updates the central date and pauses the live ticking clock
    private func selectReferenceDate(_ newDate: Date) {
        isLiveClockPaused = true
        referenceDate = newDate
    }

    // Resumes the live ticking clock and sets the time back to current
    private func resetToNow() {
        isLiveClockPaused = false
        referenceDate = Date()
    }

    // Appends a new city to the list if it isn't already present
    private func addCity(_ city: CityTimeZone) {
        guard !cities.contains(where: { existingCity in
            existingCity.city == city.city &&
            existingCity.timeZoneIdentifier == city.timeZoneIdentifier
        }) else { return }

        cities.append(city)
    }

    // Removes a city from the list, safeguarding the local base city
    private func deleteCity(_ city: CityTimeZone) {
        guard !city.isLocal else { return }

        cities.removeAll { existingCity in
            existingCity.city == city.city &&
            existingCity.timeZoneIdentifier == city.timeZoneIdentifier
        }
    }

    // Updates the current date to a newly selected day, preserving the current time components
    private func selectDay(_ selectedDay: Date) {
        selectReferenceDate(dateByKeepingCurrentTime(on: selectedDay))
    }

    // Helper that merges the year/month/day from the selected day with the hour/minute/second of the current reference date
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