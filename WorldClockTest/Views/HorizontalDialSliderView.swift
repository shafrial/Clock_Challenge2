//
//  HorizontalDialSliderView.swift
//  WorldClockTest
//
//  Created by shafrial on 23/04/26.
//

import SwiftUI

// HorizontalDialSliderView turns horizontal scrolling into a Date.
//
// Mental model:
// - The dial does not store "hour" and "minute" directly.
// - It stores a centered integer slot in scrollPosition.
// - Each slot is 5 minutes.
// - slot 0 means anchorDate.
// - slot 1 means anchorDate + 5 minutes.
// - slot -1 means anchorDate - 5 minutes.
//
// Because slot values can be negative or positive, scrolling left can move to
// previous days and scrolling right can move to future days.
struct HorizontalDialSliderView: View {
    // The centralized time the app is currently displaying.
    // ContentView owns this value and passes it down here.
    let referenceDate: Date

    // The base time zone defines what "start of day", "midnight", and labels mean.
    // Without this, Calendar.current could use a different time zone than the base city.
    let baseTZ: TimeZone

    // Callback fired when the user scrolls to a new time.
    // This view calculates the Date, but ContentView decides how to store it.
    let onDateChange: (Date) -> Void

    // Each visual tick represents 5 minutes.
    // 24 hours * 60 minutes / 5 = 288 slots per day.
    private let slotMinutes = 5

    // SwiftUI needs a finite ForEach range, so this is not truly infinite.
    // It is intentionally huge enough that the user can scroll many days away.
    // If a programmatic date ever lands outside this range, syncScrollPosition
    // recenters anchorDate and recalculates the slot.
    private let slotRange = -20_000...20_000

    // The horizontal spacing between each tick mark
    private let tickSpacing: CGFloat = 8

    // The zero-point for the slot system.
    // Usually this is midnight at the start of the current referenceDate's day
    // in baseTZ. Example: if referenceDate is Apr 27, 14:30, anchorDate is
    // Apr 27, 00:00 in the base time zone.
    @State private var anchorDate: Date?

    // The id of the tick currently aligned to the center of the ScrollView.
    // SwiftUI updates this because of .scrollPosition(id:anchor:).
    @State private var scrollPosition: Int?

    // Tracks the physical size of the view to dynamically pad the scroll edges
    @State private var viewSize: CGSize = .zero

    // Prevents the first programmatic scroll setup from being treated like a user drag.
    @State private var initialized: Bool = false

    // Prevents a feedback loop:
    // 1. ContentView changes referenceDate.
    // 2. This view updates scrollPosition to match that Date.
    // 3. scrollPosition changes.
    // 4. Without this flag, step 3 would call onDateChange and send the same
    //    update back to ContentView again.
    @State private var isSyncingFromReferenceDate: Bool = false

    var body: some View {
        ScrollView(.horizontal) {
            LazyHStack(alignment: .bottom, spacing: tickSpacing) {
                // LazyHStack means SwiftUI does not render all 40,001 ticks at once.
                // It creates views near the visible scroll area as needed.
                ForEach(slotRange, id: \.self) { slot in
                    tickView(for: slot)
                        .id(slot)
                }
            }
            .padding(.vertical, 16)
            // Marks this layout as the target for scroll snapping behavior
            .scrollTargetLayout()
        }
        .onAppear {
            // 1. Pick the zero-point for calculations.
            anchorDate = startOfDay(for: referenceDate)

            // 2. Move the dial so the current referenceDate is centered.
            syncScrollPosition(to: referenceDate)

            // 3. Delay user callbacks briefly so initial layout changes do not
            // accidentally pause the live clock in ContentView.
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                initialized = true
            }
        }
        .onChange(of: referenceDate) { _, newDate in
            // This runs when the parent changes the date, for example:
            // - live timer tick
            // - calendar sheet selection
            // - reset to now
            //
            // The dial must visually follow referenceDate, so we convert Date -> slot.
            let targetSlot = slotIndex(for: newDate)

            // Only scroll if we aren't already at that slot
            guard scrollPosition != targetSlot else { return }
            syncScrollPosition(to: newDate)
        }
        // iOS 17 feature: Snaps the scroll view cleanly to the nearest view in the target layout
        .scrollTargetBehavior(.viewAligned(anchor: .center))
        .scrollIndicators(.hidden)
        // Binds the currently centered view's ID to our scrollPosition state
        .scrollPosition(id: $scrollPosition, anchor: .center)
        .defaultScrollAnchor(.center, for: .alignment)
        .defaultScrollAnchor(.center, for: .initialOffset)
        .defaultScrollAnchor(.center, for: .sizeChanges)
        .onChange(of: scrollPosition) { _, newSlot in
            // This runs when the centered tick changes.
            //
            // If the user dragged the dial, this is the main output path:
            // scrollPosition -> Date -> onDateChange -> ContentView.referenceDate.
            //
            // If the app changed referenceDate first, isSyncingFromReferenceDate is true,
            // so we do not send the same change back to the parent.
            guard initialized, !isSyncingFromReferenceDate, let newSlot else { return }
            onDateChange(date(for: newSlot))
        }
        // Pads the beginning and end of the scroll view so the first/last items can reach the center
        .safeAreaPadding(.horizontal, viewSize.width / 2)
        .background {
            // Invisible geometry reader to capture the exact width of the scroll area
            GeometryReader { geometry in
                Color.clear
                    .onAppear {
                        viewSize = geometry.size
                    }
                    .onChange(of: geometry.size) { _, newSize in
                        viewSize = newSize
                    }
            }
        }
        .frame(height: 86)
    }

    // MARK: - Ticks

    // Renders the visual line and optional text label for a single slot.
    // This function is visual only. The actual date calculation happens in date(for:).
    private func tickView(for slot: Int) -> some View {
        // Convert the absolute slot into a minute inside one 24-hour day.
        // Example: slot 288 is next midnight, but its minuteOfDay is still 0.
        let minute = minuteOfDay(for: slot)
        let isSelected = slot == scrollPosition
        let isHour = minute % 60 == 0
        let isQuarterHour = minute % 15 == 0
        let isMidnight = minute == 0

        return VStack(spacing: 4) {
            RoundedRectangle(cornerRadius: 2)
                .fill(tickColor(isSelected: isSelected, isHour: isHour, isQuarterHour: isQuarterHour))
                .frame(width: isSelected ? 3 : 2, height: tickHeight(isMidnight: isMidnight, isHour: isHour, isQuarterHour: isQuarterHour))
                // Slightly magnify the centered tick
                .scaleEffect(y: isSelected ? 1.15 : 1, anchor: .bottom)
                .animation(.default.speed(1.2), value: isSelected)
                // Provide haptic feedback when scrolling across ticks
                .sensoryFeedback(.selection, trigger: isSelected && initialized)

            // Show text labels only on full hours to prevent clutter
            if isHour {
                Text(hourLabel(forMinuteOfDay: minute))
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .frame(width: 46)
            } else {
                // Invisible spacer to keep alignment consistent with labeled ticks
                Color.clear.frame(width: 2, height: 13)
            }
        }
        .frame(width: 2, height: 54, alignment: .bottom)
    }

    // Determines how tall the tick mark should be based on its time significance
    private func tickHeight(isMidnight: Bool, isHour: Bool, isQuarterHour: Bool) -> CGFloat {
        if isMidnight { return 34 }
        if isHour { return 30 }
        if isQuarterHour { return 22 }
        return 14 // Standard 5-minute tick
    }

    // Determines the color and opacity of the tick mark
    private func tickColor(isSelected: Bool, isHour: Bool, isQuarterHour: Bool) -> Color {
        if isSelected { return .primary }
        if isHour { return .primary.opacity(0.85) }
        if isQuarterHour { return .secondary.opacity(0.75) }
        return .secondary.opacity(0.45)
    }

    // Formats the minute integer into an AM/PM hour label
    private func hourLabel(forMinuteOfDay minute: Int) -> String {
        let hour = minute / 60
        let displayedHour = hour % 12 == 0 ? 12 : hour % 12
        let suffix = hour < 12 ? "AM" : "PM"
        return "\(displayedHour)\(suffix)"
    }

    // MARK: - Date Mapping

    // Updates the scroll view programmatically to match a target Date.
    //
    // This is used when the parent owns the change.
    // Example: ContentView sets referenceDate from the calendar sheet, so the dial
    // needs to jump to the matching slot.
    private func syncScrollPosition(to date: Date) {
        var targetSlot = slotIndex(for: date)

        // The range is large but finite. If a target date is too far from the
        // current anchorDate, make the target date's day the new zero-point.
        // This keeps the visual range usable without needing a truly infinite ForEach.
        if !slotRange.contains(targetSlot) {
            anchorDate = startOfDay(for: date)
            targetSlot = slotIndex(for: date)
        }

        // Safety check to ensure we don't crash by scrolling out of bounds
        guard slotRange.contains(targetSlot) else { return }

        // Programmatic scroll update starts here.
        // The flag tells onChange(scrollPosition) to ignore this particular change.
        isSyncingFromReferenceDate = true
        scrollPosition = targetSlot

        // Turn the flag off on the next run loop after the scroll completes
        DispatchQueue.main.async {
            isSyncingFromReferenceDate = false
        }
    }

    // Converts Date -> slot.
    //
    // Formula:
    // minutesFromAnchor = date - anchorDate
    // slot = minutesFromAnchor / 5
    //
    // Example when anchorDate is Monday 00:00:
    // Monday 00:00 -> slot 0
    // Monday 00:05 -> slot 1
    // Monday 01:00 -> slot 12
    // Tuesday 00:00 -> slot 288
    private func slotIndex(for date: Date) -> Int {
        let anchor = resolvedAnchorDate(for: date)
        let minutes = date.timeIntervalSince(anchor) / 60

        // Round to the nearest 5-minute slot so seconds from the live clock
        // do not create fractional positions.
        return Int((minutes / Double(slotMinutes)).rounded())
    }

    // Converts slot -> Date.
    //
    // This is called when the user scrolls.
    // Example: slot 289 means anchorDate + 1 day + 5 minutes.
    // That is why the dial can move to tomorrow or yesterday without needing
    // special "next day" code.
    private func date(for slot: Int) -> Date {
        let anchor = resolvedAnchorDate(for: referenceDate)

        return calendar.date(
            byAdding: .minute,
            value: slot * slotMinutes,
            to: anchor
        ) ?? anchor.addingTimeInterval(TimeInterval(slot * slotMinutes * 60))
    }

    // Converts any slot into a display minute inside a single day, from 0 to 1439.
    //
    // Important difference:
    // - date(for:) preserves the actual day movement.
    // - minuteOfDay(for:) only decides how the tick should look and what label to show.
    private func minuteOfDay(for slot: Int) -> Int {
        let minutesPerDay = 24 * 60
        let minutes = slot * slotMinutes

        // Swift's % can return a negative result for negative inputs.
        // This double-modulo pattern wraps negative slots back into 0...1439.
        // Example: -5 minutes becomes 1435, which is 11:55 PM.
        return ((minutes % minutesPerDay) + minutesPerDay) % minutesPerDay
    }

    // Safely unwraps the established anchorDate.
    // The fallback protects previews or unusual timing where calculations run
    // before onAppear has assigned anchorDate.
    private func resolvedAnchorDate(for fallbackDate: Date) -> Date {
        anchorDate ?? startOfDay(for: fallbackDate)
    }

    // Strips the time components, returning 12:00 AM of the given date
    private func startOfDay(for date: Date) -> Date {
        calendar.startOfDay(for: date)
    }

    // A helper that returns a Calendar configured for the base time zone
    private var calendar: Calendar {
        var cal = Calendar.current
        cal.timeZone = baseTZ
        return cal
    }
}

#Preview {
    HorizontalDialSliderView(
        referenceDate: Date(),
        baseTZ: defaultCities[0].timeZone,
        onDateChange: { _ in }
    ).preferredColorScheme(.dark)
}
