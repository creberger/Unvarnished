import SwiftUI

/// The painting in its frame, zoomed so the round's focus point sits in the middle.
struct PaintingView: View {
    let painting: Painting
    let focus: Painting.Focus
    let label: String

    var body: some View {
        GeometryReader { geo in
            let size = geo.size
            image
                .resizable()
                .frame(width: size.width, height: size.height)
                .scaleEffect(focus.zoom, anchor: .topLeading)
                .offset(x: offset(focus.x) * size.width, y: offset(focus.y) * size.height)
                // Clipping hides the zoomed image beyond the frame but doesn't stop it catching
                // touches there, which blocked the answers below. The painting never needs taps.
                .allowsHitTesting(false)
        }
        .aspectRatio(painting.imageAspect, contentMode: .fit)
        .clipped()
        .overlay(alignment: .bottomLeading) {
            Text(label.uppercased())
                .font(Theme.mono(11, weight: .medium))
                .tracking(0.6)
                .foregroundStyle(.white)
                .padding(.horizontal, 8)
                .padding(.vertical, 6)
                .background(.black.opacity(0.55))
                .padding(10)
                .contentTransition(.opacity)
        }
        .padding(10)
        .background(Theme.frame)
        .shadow(color: .black.opacity(0.35), radius: 18, y: 12)
        .animation(.timingCurve(0.65, 0.05, 0.25, 1, duration: 1.1), value: focus)
        .accessibilityElement()
        .accessibilityLabel("\(painting.title) by \(painting.artist). \(painting.imageDescription)")
        .accessibilityValue(label)
    }

    private var image: Image {
        painting.uiImage.map(Image.init(uiImage:)) ?? Image(systemName: "photo")
    }

    /// How far to shift the scaled image so `centre` lands mid-frame, without showing an empty edge.
    private func offset(_ centre: Double) -> Double {
        min(0, max(1 - focus.zoom, 0.5 - focus.zoom * centre))
    }
}
