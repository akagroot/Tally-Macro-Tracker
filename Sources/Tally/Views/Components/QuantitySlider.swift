import SwiftUI

/// A horizontal drag/tap slider for picking a stepped quantity — the SwiftUI equivalent of the
/// prototype's makeDragSlider, reused for food quantity, water amounts, and (later) targets.
struct QuantitySlider: View {
    @Binding var value: Double
    let range: ClosedRange<Double>
    let step: Double
    var tint: Color = .accentColor

    private let trackHeight: CGFloat = 6
    private let thumbSize: CGFloat = 26

    var body: some View {
        GeometryReader { geo in
            let width = geo.size.width
            let fraction = normalizedFraction
            ZStack(alignment: .leading) {
                Capsule()
                    .fill(Color.secondary.opacity(0.2))
                    .frame(height: trackHeight)
                Capsule()
                    .fill(tint)
                    .frame(width: max(thumbSize / 2, width * fraction), height: trackHeight)
                Circle()
                    .fill(tint)
                    .frame(width: thumbSize, height: thumbSize)
                    .shadow(radius: 1, y: 1)
                    .offset(x: max(0, min(width, width * fraction)) - thumbSize / 2)
            }
            .frame(height: thumbSize)
            .contentShape(Rectangle())
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { drag in setValue(atX: drag.location.x, width: width) }
            )
        }
        .frame(height: thumbSize)
    }

    private var normalizedFraction: CGFloat {
        guard range.upperBound > range.lowerBound else { return 0 }
        return CGFloat((value - range.lowerBound) / (range.upperBound - range.lowerBound))
    }

    private func setValue(atX x: CGFloat, width: CGFloat) {
        guard width > 0 else { return }
        let fraction = max(0, min(1, x / width))
        let raw = range.lowerBound + Double(fraction) * (range.upperBound - range.lowerBound)
        let stepped = (raw / step).rounded() * step
        value = max(range.lowerBound, min(range.upperBound, stepped))
    }
}
