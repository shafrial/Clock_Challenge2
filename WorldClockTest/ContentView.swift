import SwiftUI
internal import Combine

struct ContentView: View {

    // MARK: - State

    @State private var referenceDate: Date = Date()
    @State private var isLiveClockPaused: Bool = false
    @State private var showShare: Bool = false
    @State private var showCalendar: Bool = false
    @State private var showAddCitySheet: Bool = false
    @State private var cities: [CityTimeZone] = defaultCities

    private var baseTZ: TimeZone { cities[0].timeZone }

    // Auto-update every second until the user manually selects a time.
    private let ticker = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    // MARK: - Body

    var body: some View {
        NavigationStack{
            ZStack {
                VStack(spacing: 0) {
                    List {
                        ForEach(cities) { city in
                            TimeZoneCardView(
                                city: city,
                                referenceDate: referenceDate,
                                baseTZ: baseTZ
                            )
                            .listRowInsets(
                                EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16)
                            )
                            .listRowSeparator(.hidden)
                            .listRowBackground(Color.clear)
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
                    HorizontalDialSliderView(
                        referenceDate: referenceDate,
                        baseTZ: baseTZ,
                        onDateChange: { newDate in
                            selectReferenceDate(newDate)
                        }
                    )
                }
            }
            .onReceive(ticker) { _ in
                guard !isLiveClockPaused else { return }
                referenceDate = Date()
            }
            .navigationTitle("Match Time")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing){
                    Button("", systemImage: "plus"){
                        showAddCitySheet = true
                    }
                }
                ToolbarItem(placement: .bottomBar){
                    Button("", systemImage: "calendar"){
                        showCalendar =  true
                    }
                }
                ToolbarItem(placement: .bottomBar) {
                        Spacer()
                }
                ToolbarItem(placement: .bottomBar) {
                    if isLiveClockPaused {
                        Button("Reset to now") {
                            resetToNow()
                        }
                    }
                }
                ToolbarItem(placement: .bottomBar) {
                        Spacer()
                }
                ToolbarItem(placement: .bottomBar){
                    Button("", systemImage: "square.and.arrow.up"){
                        showShare = true
                    }
                }
            }
        }
        .sheet(isPresented: $showAddCitySheet){
            AddCitySheetView(
                selectedCities: cities,
                onSelectCity: { city in
                    addCity(city)
                }
            )
        }
        .sheet(isPresented: $showShare){
            ShareProposalView(cities: cities, referenceDate: referenceDate)
        }
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

    private func selectReferenceDate(_ newDate: Date) {
        isLiveClockPaused = true
        referenceDate = newDate
    }

    private func resetToNow() {
        isLiveClockPaused = false
        referenceDate = Date()
    }

    private func addCity(_ city: CityTimeZone) {
        guard !cities.contains(where: { existingCity in
            existingCity.city == city.city &&
            existingCity.timeZoneIdentifier == city.timeZoneIdentifier
        }) else { return }

        cities.append(city)
    }

    private func deleteCity(_ city: CityTimeZone) {
        guard !city.isLocal else { return }

        cities.removeAll { existingCity in
            existingCity.city == city.city &&
            existingCity.timeZoneIdentifier == city.timeZoneIdentifier
        }
    }

    private func selectDay(_ selectedDay: Date) {
        selectReferenceDate(dateByKeepingCurrentTime(on: selectedDay))
    }

    private func dateByKeepingCurrentTime(on selectedDay: Date) -> Date {
        var cal = Calendar.current
        cal.timeZone = baseTZ

        let day = cal.dateComponents([.year, .month, .day], from: selectedDay)
        let time = cal.dateComponents([.hour, .minute, .second, .nanosecond], from: referenceDate)

        var components = DateComponents()
        components.timeZone = baseTZ
        components.year = day.year
        components.month = day.month
        components.day = day.day
        components.hour = time.hour
        components.minute = time.minute
        components.second = time.second
        components.nanosecond = time.nanosecond

        return cal.date(from: components) ?? selectedDay
    }
}

// MARK: - Preview
#Preview {
    ContentView().preferredColorScheme(.dark)
}
