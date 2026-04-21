import SwiftUI

struct ShareProposalView: View {
    let cities: [CityTimeZone]
    let referenceDate: Date
    @Environment(\.dismiss) private var dismiss

    @State private var copied = false

    // MARK: - Share text

    private var shareMessage: String {
        guard let base = cities.first else { return "" }

        let dayFmt = DateFormatter()
        dayFmt.timeZone = base.timeZone
        dayFmt.dateFormat = "EEEE"

        let dateFmt = DateFormatter()
        dateFmt.timeZone = base.timeZone
        dateFmt.dateFormat = "d MMMM yyyy"

        let timeFmt = DateFormatter()
        timeFmt.timeZone = base.timeZone
        timeFmt.dateFormat = "h:mm a"

        let day  = dayFmt.string(from: referenceDate)
        let date = dateFmt.string(from: referenceDate)
        let time = timeFmt.string(from: referenceDate)

        let others = cities.dropFirst().map { city -> String in
            timeFmt.timeZone = city.timeZone
            return "\(timeFmt.string(from: referenceDate)) for \(city.city)"
        }

        let othersStr = others.joined(separator: " and ")
        return "How's \(day), \(date) at \(time)? That's \(othersStr)."
    }

    // MARK: - Body

    var body: some View {
        NavigationStack{
            VStack(alignment: .leading, spacing: 20) {
                // Message preview card
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Image(systemName: "clock.badge.checkmark")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.green)
                        Text("Message Preview")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(Color(white: 0.5))
                    }

                    Text(shareMessage)
                        .font(.system(size: 16))
                        .foregroundColor(.white)
                        .lineSpacing(4)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding(16)
                .background(Color(white: 0.13))
                .cornerRadius(16)

                // Time summary rows
                VStack(spacing: 10) {
                    ForEach(cities) { city in
                        timeRow(city: city)
                    }
                }
                .padding(16)
                .background(Color(white: 0.13))
                .cornerRadius(16)

                Spacer()

                // Action buttons
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
                ToolbarItem(placement: .topBarLeading) {
                    Button("", systemImage: "xmark"){
                        dismiss()
                    }
                }
            }
            .presentationDetents([.medium])
        }
    }

    // MARK: - Sub-views

    @ViewBuilder
    private func timeRow(city: CityTimeZone) -> some View {
        HStack {
            // Working hours dot
            Circle()
                .fill(city.isWorkingHour(for: referenceDate) ? Color.green : Color(white: 0.35))
                .frame(width: 8, height: 8)

            VStack(alignment: .leading, spacing: 1) {
                Text(city.city)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.white)
                Text(city.isWorkingHour(for: referenceDate) ? "Working hours" : "Outside hours")
                    .font(.system(size: 12))
                    .foregroundColor(city.isWorkingHour(for: referenceDate) ? .green : Color(white: 0.45))
            }

            Spacer()

            Text(city.formattedHourMinute(for: referenceDate) + " " + city.formattedAmPm(for: referenceDate))
                .font(.system(size: 15, weight: .medium, design: .monospaced))
                .foregroundColor(.white)
        }
    }

    // MARK: - Actions

    private func copyMessage() {
        UIPasteboard.general.string = shareMessage
        withAnimation { copied = true }
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            withAnimation { copied = false }
        }
    }

    private func triggerNativeShare() {
        let av = UIActivityViewController(
            activityItems: [shareMessage],
            applicationActivities: nil
        )
        guard
            let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
            let root  = scene.windows.first?.rootViewController
        else { return }

        // Present from the top-most presented controller
        var topVC = root
        while let presented = topVC.presentedViewController { topVC = presented }
        topVC.present(av, animated: true)
    }
}
