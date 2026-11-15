import SwiftUI
import TypleCore

/// The web app's line chart (src/components/Dashboard/TrendChart.tsx): three gridlines, the line with a soft fill and
/// a dot on the latest point.
struct TrendChart: View {
  var points: [TrendPoint]
  var scale: Scale
  var height: CGFloat = 72

  var body: some View {
    VStack(alignment: .leading, spacing: 4) {
      HStack(spacing: 6) {
        GeometryReader { proxy in
          ZStack(alignment: .topTrailing) {
            ForEach(scale.ticks.indices, id: \.self) { index in
              Text(String(format: "%.\(scale.decimals)f", scale.ticks[index]))
                .font(.system(size: 11)).monospacedDigit().foregroundStyle(Palette.mutedForeground)
                .position(x: proxy.size.width / 2, y: y(scale.ticks[index], proxy.size.height))
            }
          }
        }
        .frame(width: 32)
        GeometryReader { proxy in
          let size = proxy.size
          ZStack {
            ForEach(scale.ticks.indices, id: \.self) { index in
              Path { path in
                let y = y(scale.ticks[index], size.height)
                path.move(to: CGPoint(x: 0, y: y))
                path.addLine(to: CGPoint(x: size.width, y: y))
              }
              .stroke(Palette.border, lineWidth: 1)
            }
            area(size).fill(Palette.trend.opacity(0.1))
            line(size).stroke(Palette.trend, style: StrokeStyle(lineWidth: 2, lineCap: .round, lineJoin: .round))
            if let last = points.last {
              Circle().fill(Palette.trend).frame(width: 10, height: 10)
                .overlay(Circle().strokeBorder(Palette.card, lineWidth: 2))
                .position(x: size.width, y: y(last.value, size.height))
            }
          }
        }
        .padding(.horizontal, 4)
      }
      .frame(height: height)
      .padding(.vertical, 8)
      HStack {
        Text(shortDate(points.first?.date))
        Spacer()
        Text(shortDate(points.last?.date))
      }
      .font(.system(size: 11)).monospacedDigit().foregroundStyle(Palette.mutedForeground)
      .padding(.leading, 40)
    }
    .accessibilityElement(children: .ignore)
    .accessibilityLabel(points.map { "\(shortDate($0.date)) \(Format.number($0.value, digits: 2))" }.joined(separator: ", "))
  }

  private func shortDate(_ value: String?) -> String {
    guard let value, let date = parseDate(value) else { return "" }
    return date.formatted(.dateTime.month(.defaultDigits).day().locale(Localization.locale))
  }

  private func x(_ index: Int, _ width: CGFloat) -> CGFloat {
    points.count > 1 ? CGFloat(index) / CGFloat(points.count - 1) * width : width / 2
  }

  private func y(_ value: Double, _ height: CGFloat) -> CGFloat {
    let (low, high) = scale.domain
    return (1 - CGFloat((value - low) / max(high - low, 0.000001))) * height
  }

  private func line(_ size: CGSize) -> Path {
    Path { path in
      for (index, point) in points.enumerated() {
        let p = CGPoint(x: x(index, size.width), y: y(point.value, size.height))
        if index == 0 { path.move(to: p) } else { path.addLine(to: p) }
      }
    }
  }

  private func area(_ size: CGSize) -> Path {
    var path = line(size)
    path.addLine(to: CGPoint(x: x(points.count - 1, size.width), y: size.height))
    path.addLine(to: CGPoint(x: 0, y: size.height))
    path.closeSubpath()
    return path
  }
}
