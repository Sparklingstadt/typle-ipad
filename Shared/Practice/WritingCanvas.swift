import SwiftUI

/// One stroke, in the canvas's points.
struct WritingStroke: Equatable {
  var points: [CGPoint]
}

/// A one-line canvas to write a word on with a finger, a pen, a mouse or a trackpad: SwiftUI's Canvas and a drag, not
/// PencilKit, so that it works on the Mac too. A drag gives no pressure, so lines have one width.
struct WritingCanvas: View {
  @Binding var strokes: [WritingStroke]
  var onStrokeStart: () -> Void
  var onStrokeEnd: () -> Void

  static let lineWidth: CGFloat = 4
  @State private var drawing = false

  var body: some View {
    Canvas { context, size in
      // A guide for the height of the writing, like a line in a notebook.
      var guide = Path()
      guide.move(to: CGPoint(x: 16, y: size.height * 0.75))
      guide.addLine(to: CGPoint(x: size.width - 16, y: size.height * 0.75))
      context.stroke(guide, with: .color(Palette.border), style: StrokeStyle(lineWidth: 1, dash: [6, 4]))
      Self.draw(strokes, in: &context, color: Palette.foreground)
    }
    .contentShape(Rectangle())
    .gesture(
      DragGesture(minimumDistance: 0, coordinateSpace: .local)
        .onChanged { value in
          if !drawing {
            drawing = true
            strokes.append(WritingStroke(points: [value.startLocation]))
            onStrokeStart()
          }
          strokes[strokes.count - 1].points.append(value.location)
        }
        .onEnded { _ in
          drawing = false
          onStrokeEnd()
        }
    )
    .accessibilityElement()
    .accessibilityLabel(L("practice.writing.canvasLabel"))
  }

  static func draw(_ strokes: [WritingStroke], in context: inout GraphicsContext, color: Color) {
    for stroke in strokes {
      var path = Path()
      guard let first = stroke.points.first else { continue }
      path.move(to: first)
      // A tap leaves a dot.
      if stroke.points.count == 1 { path.addLine(to: CGPoint(x: first.x + 0.5, y: first.y)) }
      for point in stroke.points.dropFirst() { path.addLine(to: point) }
      context.stroke(path, with: .color(color), style: StrokeStyle(lineWidth: lineWidth, lineCap: .round, lineJoin: .round))
    }
  }

  /// The writing as Vision reads it: black on white, at twice the size.
  @MainActor
  static func image(of strokes: [WritingStroke], size: CGSize) -> CGImage? {
    let renderer = ImageRenderer(content: Canvas { context, _ in
      context.fill(Path(CGRect(origin: .zero, size: size)), with: .color(.white))
      draw(strokes, in: &context, color: .black)
    }.frame(width: size.width, height: size.height))
    renderer.scale = 2
    return renderer.cgImage
  }
}
