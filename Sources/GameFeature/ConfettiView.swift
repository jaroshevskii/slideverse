import SwiftUI

/// A lightweight confetti burst that replays whenever `trigger` changes. No dependencies.
struct ConfettiView: View {
  let trigger: Int

  private let colors: [Color] = [.red, .orange, .yellow, .green, .blue, .purple, .pink]

  var body: some View {
    GeometryReader { proxy in
      ZStack {
        ForEach(0..<60, id: \.self) { index in
          ConfettiPiece(
            color: colors[index % colors.count],
            size: proxy.size,
            seed: index,
            trigger: trigger
          )
        }
      }
    }
    .allowsHitTesting(false)
  }
}

private struct ConfettiPiece: View {
  let color: Color
  let size: CGSize
  let seed: Int
  let trigger: Int

  @State private var fall = false

  private var startX: CGFloat {
    CGFloat((seed * 2_654_435_761) % max(Int(size.width), 1))
  }
  private var drift: CGFloat {
    CGFloat((seed * 40) % 120) - 60
  }
  private var delay: Double {
    Double(seed % 10) * 0.04
  }

  var body: some View {
    RoundedRectangle(cornerRadius: 2)
      .fill(color)
      .frame(width: 7, height: 11)
      .position(x: startX, y: fall ? size.height + 20 : -20)
      .offset(x: fall ? drift : 0)
      .rotationEffect(.degrees(fall ? Double(seed * 47 % 360) : 0))
      .opacity(fall ? 0 : 1)
      .onAppear { animate() }
      .onChange(of: trigger) { animate() }
  }

  private func animate() {
    fall = false
    withAnimation(.easeIn(duration: 1.8).delay(delay)) {
      fall = true
    }
  }
}
