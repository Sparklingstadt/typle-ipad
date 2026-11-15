import SwiftUI
import TypleCore

/// Lays children out in rows, wrapping to the next row when one is full, centred like the web's flex-wrap text.
struct FlowLayout: Layout {
  var spacing: CGFloat = 8
  var lineSpacing: CGFloat = 8
  var alignment: HorizontalAlignment = .center

  func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
    let rows = arrange(subviews, width: proposal.width ?? .infinity)
    return CGSize(width: proposal.width ?? rows.map(\.width).max() ?? 0, height: rows.last.map { $0.y + $0.height } ?? 0)
  }

  func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
    for row in arrange(subviews, width: bounds.width) {
      var x = bounds.minX + (alignment == .center ? (bounds.width - row.width) / 2 : 0)
      for index in row.members {
        let size = subviews[index].sizeThatFits(.unspecified)
        subviews[index].place(at: CGPoint(x: x, y: bounds.minY + row.y + (row.height - size.height)), proposal: ProposedViewSize(width: min(size.width, bounds.width), height: size.height))
        x += size.width + spacing
      }
    }
  }

  private struct Row { var members: [Int] = []; var y: CGFloat = 0; var width: CGFloat = 0; var height: CGFloat = 0 }

  private func arrange(_ subviews: Subviews, width: CGFloat) -> [Row] {
    var rows: [Row] = []
    var row = Row()
    for index in subviews.indices {
      let size = subviews[index].sizeThatFits(.unspecified)
      if !row.members.isEmpty && row.width + spacing + size.width > width {
        rows.append(row)
        row = Row(y: row.y + row.height + lineSpacing)
      }
      row.width += (row.members.isEmpty ? 0 : spacing) + size.width
      row.height = max(row.height, size.height)
      row.members.append(index)
    }
    if !row.members.isEmpty { rows.append(row) }
    return rows
  }
}
