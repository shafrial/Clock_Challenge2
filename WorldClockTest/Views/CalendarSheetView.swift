//
//  CalendarSheetView.swift
//  WorldClockTest
//
//  Created by shafrial on 24/04/26.
//

import SwiftUI

struct CalendarSheetView: View {
    @Environment(\.dismiss) private var dismiss
    let onSelectDate: (Date) -> Void

    @State private var draftDate: Date

    init(selectedDate: Date, onSelectDate: @escaping (Date) -> Void) {
        self.onSelectDate = onSelectDate
        self._draftDate = State(initialValue: selectedDate)
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                DatePicker(
                    "Date",
                    selection: $draftDate,
                    displayedComponents: [.date]
                )
                .datePickerStyle(.graphical)
                .labelsHidden()
            }
            .padding()
            .navigationTitle("Select Date")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel", systemImage: "xmark") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        onSelectDate(draftDate)
                        dismiss()
                    }
                }
            }
        }
        .presentationDragIndicator(.visible)
        .presentationDetents([.medium])
    }
}
