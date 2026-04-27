# World Clock Test

## Overview
This application is a global time-matching and event-scheduling tool built with SwiftUI. It allows users to view current times across multiple time zones, find overlapping working hours, and share proposed meeting times with others.

## Architecture & System Flow

### Models (`Models.swift`)
- **`CityTimeZone`**: The core data structure representing a city, its time zone identifier, and utility methods to format time and check if a given date falls within working hours or daytime.
- **Data Stores**: Contains default cities and a catalog of available cities to choose from.

### App & Main Entry (`WorldClockTestApp.swift` & `ContentView.swift`)
- **`WorldClockTestApp`**: The main entry point initializing the app.
- **`ContentView`**: The primary view and source of truth for the app's state. It holds the `referenceDate` (the time being inspected) and the list of user-selected `cities`. It coordinates the time zone cards, the slider, and the presentation of sheets (Calendar, Share, Add City).
- A `Timer` publishes every second to keep the clock live until the user interacts with the timeline or calendar, at which point the live clock pauses.

### Views (`Views/`)
- **`TimeZoneCardView`**: Displays a city's name, relative offset from the base time zone, current time based on the `referenceDate`, and badges indicating if it's currently working hours or daytime.
- **`HorizontalDialSliderView`**: A custom, infinite-feeling timeline slider. It allows users to drag left or right to move time backward or forward in 5-minute increments. It syncs bidirectionally with the `ContentView`'s `referenceDate`.
- **`AddCitySheetView`**: A searchable list to add new cities from the catalog to the main view.
- **`CalendarSheetView`**: Allows the user to jump to a specific date. It retains the current time but changes the day, month, and year.
- **`ShareProposalView`**: Generates a shareable summary of the selected date and time across all chosen time zones. Useful for proposing meeting times.