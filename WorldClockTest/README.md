# World Clock Test

## Overview

World Clock Test is a SwiftUI app for comparing one selected time across multiple cities. The app keeps one shared `referenceDate`, then each city formats that same absolute date in its own time zone.

The main use case is meeting planning:

- See the current time in the local city and added cities.
- Scrub time forward or backward with a horizontal dial.
- Jump to another calendar day.
- Add or delete cities.
- Copy a proposed meeting message.

## Core Idea

The most important concept is `referenceDate`.

`referenceDate` is the single source of truth for the time currently being inspected. It lives in `ContentView`, then flows down into child views:

- `TimeZoneCardListView` uses it to render all city cards.
- `HorizontalDialSliderView` uses it to position the dial.
- `CalendarSheetView` receives it as the initial selected day.
- `ShareProposalView` uses it to generate the proposal text.

When a child view needs to change the selected time, it does not directly mutate `referenceDate`. Instead, it sends an event back to `ContentView` using a callback closure. `ContentView` then updates its own state.

## App Flow

### Live Clock

When the app opens, `referenceDate` starts as `Date()`. `ContentView` has a timer that fires every second and updates `referenceDate` to the current time.

This live behavior continues while `isLiveClockPaused == false`.

### Manual Time Selection

When the user changes the time using the horizontal dial or calendar:

1. The child view sends a new `Date` back to `ContentView`.
2. `ContentView` calls `selectReferenceDate(_:)`.
3. `selectReferenceDate(_:)` sets `isLiveClockPaused = true`.
4. `referenceDate` changes.
5. SwiftUI re-renders the cards, dial, and share sheet content using the new date.

This pause is important. Without it, the one-second timer would immediately replace the user's selected time with the current real-world time.

### Reset To Now

The "Reset to now" toolbar button appears only after the user manually changes the date or time. When tapped:

1. `isLiveClockPaused` becomes `false`.
2. `referenceDate` becomes `Date()`.
3. The live timer continues updating the app every second.

## Main Files

### `WorldClockTestApp.swift`

This is the app entry point. It creates the first `WindowGroup` and loads `ContentView`.

### `ContentView.swift`

This is the screen coordinator and main state owner.

It owns:

- `referenceDate`: the currently selected time.
- `isLiveClockPaused`: whether the live timer should stop updating the selected time.
- `cities`: the selected city list.
- Sheet visibility state for add city, calendar, and share.

It passes state down into child views and receives events back through callbacks:

- `onDateChange` from `HorizontalDialSliderView`.
- `onDeleteCity` from `TimeZoneCardListView`.
- `onSelectCity` from `AddCitySheetView`.
- `onSelectDate` from `CalendarSheetView`.

## Views

### `TimeZoneCardListView.swift`

This view displays the list of selected cities using SwiftUI `List`.

It exists so `ContentView` does not need to own card-list UI details. It also owns the native swipe-to-delete behavior. When the user deletes a row, this view calls `onDeleteCity(city)`, and `ContentView` performs the actual city removal.

The local/base city cannot be deleted. The UI disables full-swipe delete for that city, and `ContentView.deleteCity(_:)` also protects it.

### `TimeZoneCardView.swift`

This view renders one city card.

It receives:

- one `CityTimeZone`
- the shared `referenceDate`
- the base time zone

It asks the `CityTimeZone` model to format the time, calculate day/night, calculate working hours, and calculate the offset from the base city. This keeps most time-zone logic out of the view body.

### `HorizontalDialSliderView.swift`

This is the custom time scrubber. It converts horizontal scrolling into a `Date`.

The dial uses "slots":

- 1 slot = 5 minutes.
- slot `0` = `anchorDate`.
- slot `1` = `anchorDate + 5 minutes`.
- slot `-1` = `anchorDate - 5 minutes`.
- 288 slots = 1 full day because `24 * 60 / 5 = 288`.

`anchorDate` is usually midnight at the start of the selected day in the base time zone. For example, if the selected time is Monday 14:30, the anchor is Monday 00:00.

The important data flow is:

1. The user scrolls the dial.
2. SwiftUI updates `scrollPosition` with the centered tick id.
3. `HorizontalDialSliderView` converts that slot into a `Date`.
4. It calls `onDateChange(newDate)`.
5. `ContentView` receives the new date and updates `referenceDate`.
6. All city cards re-render using the new shared date.

The infinite-feeling behavior comes from a very large finite range: `-20_000...20_000`. SwiftUI still needs a real range for `ForEach`, but this gives enough room to scroll many days backward or forward. If a programmatic date is too far outside the current range, the dial recenters the `anchorDate` and recalculates the slot.

Moving past midnight does not need special day-changing code. For example, if `anchorDate` is Monday 00:00:

- slot `287` = Monday 23:55
- slot `288` = Tuesday 00:00
- slot `-1` = Sunday 23:55

### `CalendarSheetView.swift`

This sheet lets the user choose a calendar day.

It uses local `draftDate` while the sheet is open. Tapping Cancel discards the draft. Tapping Done sends the selected day back to `ContentView`.

`ContentView` then combines the selected day with the current selected time. For example, if the app currently shows 14:30 and the user selects Friday, the final result is Friday at 14:30 in the base time zone.

### `AddCitySheetView.swift`

This sheet displays a searchable list from `cityCatalog`.

It receives `selectedCities` so it can hide cities that are already added. When the user taps a row, it calls `onSelectCity(city)` and dismisses.

This uses a callback instead of `@Binding` because the child is reporting an event: "the user selected this city." `ContentView` still owns the actual city list and duplicate prevention.

### `ShareProposalView.swift`

This sheet creates a meeting proposal message from the selected cities and `referenceDate`.

It treats the first city as the base city. Other cities are formatted as equivalent times for the same absolute date.

## Models And Data

### `Models/CityTimeZone.swift`

`CityTimeZone` represents one city and its time zone identifier.

It also contains helper methods for:

- formatting hour and minute
- formatting AM/PM
- formatting date text
- checking working hours
- checking day/night
- calculating the offset from the base time zone

These helpers keep date-formatting logic in one place instead of duplicating it across views.

### `Models/WorkingHours.swift`

This file stores the app's working-hours rule:

- start: 9:00
- end: 17:00

The end hour is exclusive, so 17 means working time ends before 5:00 PM.

### `Data/CityCatalog.swift`

This file stores static city data for the MVP.

- `defaultCities` controls the cities shown when the app launches.
- `cityCatalog` controls the cities shown in the add-city sheet.

The first default city is important because `ContentView` treats it as the local/base city.
