//
//  CalendarSheetView.swift
//  WorldClockTest
//
//  Created by shafrial on 24/04/26.
//

import SwiftUI

// A sheet containing a graphical calendar to quickly jump to a specific date.
// It uses local draftDate while the sheet is open, then sends the final choice
// back to ContentView only when the user taps Done.
struct CalendarSheetView: View {
    // Environment property to close the sheet programmatically
    @Environment(\.dismiss) private var dismiss
    // Callback executed when the user confirms their date selection.
    // @escaping is required in the initializer because the closure is stored
    // in this struct and called later, after init has finished.
    let onSelectDate: (Date) -> Void

    // Local state representing the currently selected date in the picker before confirming
    @State private var draftDate: Date

    // Custom initializer to seed the draftDate with the app's current reference date
    init(selectedDate: Date, onSelectDate: @escaping (Date) -> Void) {
        self.onSelectDate = onSelectDate
        self._draftDate = State(initialValue: selectedDate)
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Standard iOS graphical date picker
                DatePicker(
                    "Date",
                    selection: $draftDate,
                    displayedComponents: [.date] // Only allow day/month/year selection, no time
                )
                .datePickerStyle(.graphical)
                .labelsHidden()
            }
            .padding()
            .navigationTitle("Select Date")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                // Top-left cancel button to close without making changes
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel", systemImage: "xmark") {
                        dismiss()
                    }
                }

                // Top-right done button to confirm the selection
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        onSelectDate(draftDate)
                        dismiss()
                    }
                }
            }
        }
        // Show a drag indicator handle at the top of the sheet
        .presentationDragIndicator(.visible)
        // Limit the sheet height to roughly half the screen
        .presentationDetents([.medium])
    }
}
