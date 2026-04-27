//
//  HorizontalDialSliderView.swift
//  WorldClockTest
//
//  Created by shafrial on 23/04/26.
//

import SwiftUI

// A custom horizontal slider that allows users to adjust time in 5-minute increments.
// It creates an illusion of infinite scrolling by using a massive range of integer "slots".
struct HorizontalDialSliderView: View {
    // The centralized time the app is currently displaying
    let referenceDate: Date
    // The base time zone to perform calendar calculations against
    let baseTZ: TimeZone
    // Callback fired when the user scrolls to a new time
    let onDateChange: (Date) -> Void

    // Each slot on the dial represents 5 minutes
    private let slotMinutes = 5
    // A massive range of slots (-20,000 to 20,000) that gives the illusion of an infinite slider
    private let slotRange = -20_000...20_000
    // The horizontal spacing between each tick mark
    private let tickSpacing: CGFloat = 8

    // The start of the current day, used as a zero-point for calculating times from slot indices
    @State private var anchorDate: Date?
    // The currently centered slot index in the scroll view
    @State private var scrollPosition: Int?
    // Tracks the physical size of the view to dynamically pad the scroll edges
    @State private var viewSize: CGSize = .zero
    // Ensures the view is fully set up before triggering scroll change callbacks
    @State private var initialized: Bool = false
    // A flag to prevent an infinite feedback loop between the app changing the date and the scroll view updating
    @State private var isSyncingFromReferenceDate: Bool = false

    var body: some View {
        ScrollView(.horizontal) {
            LazyHStack(alignment: .bottom, spacing: tickSpacing) {
                // Renders the 40,000 tick marks lazily as the user scrolls
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
            // Establish the zero-point anchor based on the initial date
            anchorDate = startOfDay(for: referenceDate)
            // Move the scroll view to the correct position for the initial date
            syncScrollPosition(to: referenceDate)

            // Allow the UI a moment to layout before enabling interactive callbacks
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                initialized = true
            }
        }
        .onChange(of: referenceDate) { _, newDate in
            // When the app's time updates externally (e.g., from live ticking or calendar),
            // calculate the corresponding slot.
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
            // When the user drags to a new slot, we notify the app of the new time.
            // We ignore this if the view isn't ready or if the app itself caused the scroll.
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

    // Renders the visual line and optional text label for a single slot
    private func tickView(for slot: Int) -> some View {
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

    // Updates the scroll view programmatically to match a target Date
    private func syncScrollPosition(to date: Date) {
        var targetSlot = slotIndex(for: date)

        // If the date is so far away that it exceeds our 40,000 slot range,
        // we re-center the anchor date to the new day and recalculate the slot.
        if !slotRange.contains(targetSlot) {
            anchorDate = startOfDay(for: date)
            targetSlot = slotIndex(for: date)
        }

        // Safety check to ensure we don't crash by scrolling out of bounds
        guard slotRange.contains(targetSlot) else { return }

        // Set the flag to true so the onChange(scrollPosition) doesn't fire backwards
        isSyncingFromReferenceDate = true
        scrollPosition = targetSlot

        // Turn the flag off on the next run loop after the scroll completes
        DispatchQueue.main.async {
            isSyncingFromReferenceDate = false
        }
    }

    // Calculates which integer slot represents the given date, relative to the anchorDate
    private func slotIndex(for date: Date) -> Int {
        let anchor = resolvedAnchorDate(for: date)
        // Find total minutes difference from the start of the day
        let minutes = date.timeIntervalSince(anchor) / 60
        // Divide by 5 (slotMinutes) and round to the nearest slot
        return Int((minutes / Double(slotMinutes)).rounded())
    }

    // Calculates the actual Date corresponding to an integer slot index
    private func date(for slot: Int) -> Date {
        let anchor = resolvedAnchorDate(for: referenceDate)
        // Add (slot * 5 minutes) to the start of the day
        return calendar.date(
            byAdding: .minute,
            value: slot * slotMinutes,
            to: anchor
        ) ?? anchor.addingTimeInterval(TimeInterval(slot * slotMinutes * 60))
    }

    // Standardizes the time into a 24-hour minute value (0-1439) to determine if it's an hour, midnight, etc.
    private func minuteOfDay(for slot: Int) -> Int {
        let minutesPerDay = 24 * 60
        let minutes = slot * slotMinutes
        // Uses double modulo logic to correctly handle negative slots
        return ((minutes % minutesPerDay) + minutesPerDay) % minutesPerDay
    }

    // Safely unwraps the established anchorDate, or creates a new one if missing
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