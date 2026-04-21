import SwiftUI
internal import Combine

struct ContentView: View {

    // MARK: - State

    @State private var referenceDate: Date = Date()
    @State private var isDragging: Bool = false
    @State private var showShare: Bool = false

    private let cities = CityTimeZone.defaultCities
    private var baseTZ: TimeZone { cities[0].timeZone }

    // Auto-update every second when not dragging
    private let ticker = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    // MARK: - Slider fraction (0–1 within Bali's day)

    private var sliderFraction: Double {
        var cal = Calendar.current
        cal.timeZone = baseTZ
        let startOfDay = cal.startOfDay(for: referenceDate)
        let elapsed = referenceDate.timeIntervalSince(startOfDay)
        return max(0, min(1, elapsed / 86_400))
    }

    // MARK: - Body

    var body: some View {
        NavigationStack{
            ZStack {
                
                VStack() {
                    HStack(alignment: .top, spacing: 0) {
                        // ── Clock cards ──────────────────────────────────────────
                        ScrollView(showsIndicators: false) {
                            VStack(spacing: 12) {
                                ForEach(cities) { city in
                                    TimeZoneCardView(
                                        city: city,
                                        referenceDate: referenceDate,
                                        baseTZ: baseTZ
                                    )
                                }
                            }
                            .padding(.horizontal, 16)
                            .padding(.vertical, 12)
                        }
                        
                        // ── Vertical slider ──────────────────────────────────────
                        VerticalTimeSlider(
                            cities: cities,
                            baseTZ: baseTZ,
                            fraction: sliderFraction,
                            onDrag: { f in
                                isDragging = true
                                setReferenceDate(fraction: f)
                            }
                        )
                        .padding(.top, 14)
                        .padding(.trailing, 14)
                        .padding(.leading, 8)
                    }
                }
            }
            .onReceive(ticker) { _ in
                guard !isDragging else { return }
                referenceDate = Date()
            }
            .navigationTitle("Match Time")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing){
                    Button("", systemImage: "plus"){}
                }
                ToolbarItem(placement: .bottomBar){
                    Button("", systemImage: "calendar"){}
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
        .sheet(isPresented: $showShare){
            ShareProposalView(cities: cities, referenceDate: referenceDate)
        }
    }
        
    // MARK: - Helpers

    private func resetToNow() {
        isDragging = false
        referenceDate = Date()
    }

    /// Convert a 0–1 slider fraction into a Date within the base TZ's day.
    private func setReferenceDate(fraction: Double) {
        var cal = Calendar.current
        cal.timeZone = baseTZ
        let startOfDay = cal.startOfDay(for: referenceDate)
        referenceDate = startOfDay.addingTimeInterval(fraction * 86_400)
    }
}

// MARK: - Preview

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
            .preferredColorScheme(.dark)
    }
}
