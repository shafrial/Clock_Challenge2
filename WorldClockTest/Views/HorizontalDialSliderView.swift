//
//  HorizontalDialSliderView.swift
//  WorldClockTest
//
//  Created by shafrial on 23/04/26.
//

import SwiftUI

struct HorizontalDialSliderView: View {
    let referenceDate: Date
    let baseTZ: TimeZone
    let onDateChange: (Date) -> Void

    private let slotMinutes = 5
    private let slotRange = -20_000...20_000
    private let tickSpacing: CGFloat = 8

    @State private var anchorDate: Date?
    @State private var scrollPosition: Int?
    @State private var viewSize: CGSize = .zero
    @State private var initialized: Bool = false
    @State private var isSyncingFromReferenceDate: Bool = false

    var body: some View {
        ScrollView(.horizontal) {
            LazyHStack(alignment: .bottom, spacing: tickSpacing) {
                ForEach(slotRange, id: \.self) { slot in
                    tickView(for: slot)
                        .id(slot)
                }
            }
            .padding(.vertical, 16)
            .scrollTargetLayout()
        }
        .onAppear {
            anchorDate = startOfDay(for: referenceDate)
            syncScrollPosition(to: referenceDate)

            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                initialized = true
            }
        }
        .onChange(of: referenceDate) { _, newDate in
            let targetSlot = slotIndex(for: newDate)
            guard scrollPosition != targetSlot else { return }
            syncScrollPosition(to: newDate)
        }
        .scrollTargetBehavior(.viewAligned(anchor: .center))
        .scrollIndicators(.hidden)
        .scrollPosition(id: $scrollPosition, anchor: .center)
        .defaultScrollAnchor(.center, for: .alignment)
        .defaultScrollAnchor(.center, for: .initialOffset)
        .defaultScrollAnchor(.center, for: .sizeChanges)
        .onChange(of: scrollPosition) { _, newSlot in
            guard initialized, !isSyncingFromReferenceDate, let newSlot else { return }
            onDateChange(date(for: newSlot))
        }
        .safeAreaPadding(.horizontal, viewSize.width / 2)
        .background {
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
                .scaleEffect(y: isSelected ? 1.15 : 1, anchor: .bottom)
                .animation(.default.speed(1.2), value: isSelected)
                .sensoryFeedback(.selection, trigger: isSelected && initialized)

            if isHour {
                Text(hourLabel(forMinuteOfDay: minute))
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .frame(width: 46)
            } else {
                Color.clear.frame(width: 2, height: 13)
            }
        }
        .frame(width: 2, height: 54, alignment: .bottom)
    }

    private func tickHeight(isMidnight: Bool, isHour: Bool, isQuarterHour: Bool) -> CGFloat {
        if isMidnight { return 34 }
        if isHour { return 30 }
        if isQuarterHour { return 22 }
        return 14
    }

    private func tickColor(isSelected: Bool, isHour: Bool, isQuarterHour: Bool) -> Color {
        if isSelected { return .primary }
        if isHour { return .primary.opacity(0.85) }
        if isQuarterHour { return .secondary.opacity(0.75) }
        return .secondary.opacity(0.45)
    }

    private func hourLabel(forMinuteOfDay minute: Int) -> String {
        let hour = minute / 60
        let displayedHour = hour % 12 == 0 ? 12 : hour % 12
        let suffix = hour < 12 ? "AM" : "PM"
        return "\(displayedHour)\(suffix)"
    }

    // MARK: - Date Mapping

    private func syncScrollPosition(to date: Date) {
        var targetSlot = slotIndex(for: date)

        if !slotRange.contains(targetSlot) {
            anchorDate = startOfDay(for: date)
            targetSlot = slotIndex(for: date)
        }

        guard slotRange.contains(targetSlot) else { return }

        isSyncingFromReferenceDate = true
        scrollPosition = targetSlot

        DispatchQueue.main.async {
            isSyncingFromReferenceDate = false
        }
    }

    private func slotIndex(for date: Date) -> Int {
        let anchor = resolvedAnchorDate(for: date)
        let minutes = date.timeIntervalSince(anchor) / 60
        return Int((minutes / Double(slotMinutes)).rounded())
    }

    private func date(for slot: Int) -> Date {
        let anchor = resolvedAnchorDate(for: referenceDate)
        return calendar.date(
            byAdding: .minute,
            value: slot * slotMinutes,
            to: anchor
        ) ?? anchor.addingTimeInterval(TimeInterval(slot * slotMinutes * 60))
    }

    private func minuteOfDay(for slot: Int) -> Int {
        let minutesPerDay = 24 * 60
        let minutes = slot * slotMinutes
        return ((minutes % minutesPerDay) + minutesPerDay) % minutesPerDay
    }

    private func resolvedAnchorDate(for fallbackDate: Date) -> Date {
        anchorDate ?? startOfDay(for: fallbackDate)
    }

    private func startOfDay(for date: Date) -> Date {
        calendar.startOfDay(for: date)
    }

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
