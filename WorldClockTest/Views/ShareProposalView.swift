import SwiftUI

// A view that generates a textual summary of selected times and allows the user to copy or share it
struct ShareProposalView: View {
    // The list of chosen cities
    let cities: [CityTimeZone]
    // The specific time being proposed
    let referenceDate: Date
    // Environment property to close the sheet
    @Environment(\.dismiss) private var dismiss

    // Local state to track if the text was just copied, triggering a brief UI change
    @State private var copied = false

    // MARK: - Share text

    // Dynamically generates the human-readable proposal sentence
    private var shareMessage: String {
        guard let base = cities.first else { return "" }

        // Setup formatters relative to the base/local time zone
        let dayFmt = DateFormatter()
        dayFmt.timeZone = base.timeZone
        dayFmt.dateFormat = "EEEE"

        let dateFmt = DateFormatter()
        dateFmt.timeZone = base.timeZone
        dateFmt.dateFormat = "d MMMM yyyy"

        let timeFmt = DateFormatter()
        timeFmt.timeZone = base.timeZone
        timeFmt.dateFormat = "h:mm a"

        // Format the base string components
        let day  = dayFmt.string(from: referenceDate)
        let date = dateFmt.string(from: referenceDate)
        let time = timeFmt.string(from: referenceDate)

        // Generate the time strings for all other non-base cities
        let others = cities.dropFirst().map { city -> String in
            timeFmt.timeZone = city.timeZone
            return "\(timeFmt.string(from: referenceDate)) for \(city.city)"
        }

        // Join the other city times with "and"
        let othersStr = others.joined(separator: " and ")
        
        // Assemble the final message
        return "How's \(day), \(date) at \(time)? That's \(othersStr)."
    }

    // MARK: - Body

    var body: some View {
        NavigationStack{
            VStack(alignment: .leading, spacing: 20) {
                // Visual card displaying the generated message
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Image(systemName: "clock.badge.checkmark")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.green)
                        Text("Message Preview")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(Color(white: 0.5))
                    }

                    // Display the generated share message
                    Text(shareMessage)
                        .font(.system(size: 16))
                        .foregroundColor(.white)
                        .lineSpacing(4)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding(16)
                .background(Color(white: 0.13))
                .cornerRadius(16)

                // List showing the time status for each city
                VStack(spacing: 10) {
                    ForEach(cities) { city in
                        timeRow(city: city)
                    }
                }
                .padding(16)
                .background(Color(white: 0.13))
                .cornerRadius(16)

                Spacer()

                // A large button that copies the message to the clipboard
                Button(action: copyMessage) {
                    Label(copied ? "Copied!" : "Copy Text",
                          systemImage: copied ? "checkmark" : "doc.on.doc")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(Color(white: 0.22))
                        .cornerRadius(14)
                }
            }
            .padding(20)
            .navigationTitle("Share Event")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar{
                // Top-left button to close the sheet
                ToolbarItem(placement: .topBarLeading) {
                    Button("", systemImage: "xmark"){
                        dismiss()
                    }
                }
            }
            // Limit sheet size to medium (half-screen)
            .presentationDetents([.medium])
        }
    }

    // MARK: - Sub-views

    // A reusable row component showing a city, its time, and its working hour status
    @ViewBuilder
    private func timeRow(city: CityTimeZone) -> some View {
        HStack {
            // Indicator dot showing green for working hours, gray for outside
            Circle()
                .fill(city.isWorkingHour(for: referenceDate) ? Color.green : Color(white: 0.35))
                .frame(width: 8, height: 8)

            VStack(alignment: .leading, spacing: 1) {
                Text(city.city)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.white)
                // Text status indicator
                Text(city.isWorkingHour(for: referenceDate) ? "Working hours" : "Outside hours")
                    .font(.system(size: 12))
                    .foregroundColor(city.isWorkingHour(for: referenceDate) ? .green : Color(white: 0.45))
            }

            Spacer()

            // Formatted time display
            Text(city.formattedHourMinute(for: referenceDate) + " " + city.formattedAmPm(for: referenceDate))
                .font(.system(size: 15, weight: .medium, design: .monospaced))
                .foregroundColor(.white)
        }
    }

    // MARK: - Actions

    // Copies the generated message to the system clipboard and toggles the UI state temporarily
    private func copyMessage() {
        UIPasteboard.general.string = shareMessage
        withAnimation { copied = true }
        
        // Reset the "Copied!" state back to "Copy Text" after 2 seconds
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            withAnimation { copied = false }
        }
    }

    // Unused alternative: Opens the native iOS share sheet instead of just copying to clipboard
    private func triggerNativeShare() {
        let av = UIActivityViewController(
            activityItems: [shareMessage],
            applicationActivities: nil
        )
        guard
            let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
            let root  = scene.windows.first?.rootViewController
        else { return }

        // Present from the top-most presented controller in the view hierarchy
        var topVC = root
        while let presented = topVC.presentedViewController { topVC = presented }
        topVC.present(av, animated: true)
    }
}