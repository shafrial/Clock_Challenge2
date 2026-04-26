//
//  CalendarSheetView.swift
//  WorldClockTest
//
//  Created by shafrial on 24/04/26.
//

import SwiftUI

struct CalendarSheetView: View {
    @Environment(\.dismiss) private var dismiss
    @Binding private var date: Date

    @State private var draftDate: Date

    init(date: Binding<Date>) {
        self._date = date
        self._draftDate = State(initialValue: date.wrappedValue)
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
                        date = draftDate
                        dismiss()
                    }
                }
            }
        }
        .presentationDragIndicator(.visible)
        .presentationDetents([.medium])
    }
}

