import SwiftUI

/// A draggable vertical bar that shows working-hour overlaps for all cities
/// and lets the user scrub through the 24-hour day (anchored to the base timezone).
struct VerticalTimeSlider: View {
    let cities: [CityTimeZone]
    let baseTZ: TimeZone
    /// 0.0 = midnight, 1.0 = next midnight (in base timezone)
    let fraction: Double
    let onDrag: (Double) -> Void

    // Segments across the 24h day
    private let segmentCount = 48 // every 30 min

    var body: some View {
        GeometryReader { geo in
            let h = geo.size.height
            ZStack(alignment: .top) {
                // ── Colour bands ──────────────────────────────────────────────
                Canvas { ctx, size in
                    let segH = size.height / CGFloat(segmentCount)

                    for i in 0..<segmentCount {
                        let f = Double(i) / Double(segmentCount)
                        let slotDate = dateFor(fraction: f)
                        let count = cities.filter { $0.isWorkingHour(for: slotDate) }.count

                        let color: Color = {
                            switch count {
                            case 3:  return Color(red: 0.18, green: 0.78, blue: 0.40)
                            case 2:  return Color(red: 0.65, green: 0.85, blue: 0.25)
                            case 1:  return Color(red: 0.85, green: 0.75, blue: 0.10)
                            default: return Color(white: 0.18)
                            }
                        }()

                        let rect = CGRect(
                            x: 3,
                            y: CGFloat(i) * segH + 1,
                            width: size.width - 6,
                            height: segH - 2
                        )
                        ctx.fill(
                            Path(roundedRect: rect, cornerRadius: 2),
                            with: .color(color)
                        )
                    }
                }

                // ── Draggable thumb ───────────────────────────────────────────
                thumbView
                    .offset(y: max(0, min(h - 18, CGFloat(fraction) * h - 9)))
            }
            .contentShape(Rectangle())
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { v in
                        let f = max(0, min(1, Double(v.location.y / h)))
                        onDrag(f)
                    }
            )
        }
        .frame(width: 22)
    }

    // MARK: - Thumb

    private var thumbView: some View {
        VStack(spacing: 1) {
            Capsule().fill(Color.white).frame(width: 22, height: 3)
            Capsule().fill(Color.white).frame(width: 22, height: 3)
            Capsule().fill(Color.white).frame(width: 22, height: 3)
        }
        .shadow(color: .black.opacity(0.5), radius: 3)
    }

    // MARK: - Helpers

    /// Returns a Date for `fraction` (0–1) of today in the base timezone.
    private func dateFor(fraction: Double) -> Date {
        var cal = Calendar.current
        cal.timeZone = baseTZ
        let today = cal.startOfDay(for: Date())
        return today.addingTimeInterval(fraction * 86_400)
    }
}
