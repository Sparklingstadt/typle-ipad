import SwiftUI
import TypleCore

struct Delta {
  var icon: String
  var good: Bool
  var text: String
}

struct DeltaText: View {
  var delta: Delta
  var body: some View {
    HStack(alignment: .top, spacing: 4) {
      Image(systemName: delta.icon).font(.system(size: 10)).padding(.top, 2)
      Text(delta.text).fixedSize(horizontal: false, vertical: true)
    }
    .font(.system(size: 12))
    .foregroundStyle(delta.good ? Palette.success : Palette.mutedForeground)
  }
}

func secondsDifference(_ difference: Double) -> String? {
  let value = String(format: "%.2f", abs(difference))
  return value == "0.00" ? nil : L(difference > 0 ? "dashboard.change.slower" : "dashboard.change.faster", value)
}

func pointDifference(_ difference: Double) -> String? {
  let value = String(format: "%.1f", abs(difference))
  return value == "0.0" ? nil : L(difference > 0 ? "dashboard.change.pointsUp" : "dashboard.change.pointsDown", value)
}

/// 「直近5回の平均は、その前の5回より 0.12 秒速い」, or without the recent window when the label already names it.
func changeDelta(_ change: Change, lowerIsBetter: Bool, describe: (Double) -> String?, namedRecent: Bool = true) -> Delta {
  let recent = !namedRecent ? "" : change.recentCount == 1 ? L("dashboard.change.latest") : L("dashboard.change.recentAverage", change.recentCount)
  let previous = change.previousCount == 1 ? L("dashboard.change.previousLatest") : L("dashboard.change.previousAverage", change.previousCount)
  let difference = change.recent - change.previous
  guard let text = describe(difference) else {
    return Delta(icon: "minus", good: false, text: capitalizedFirst(L("dashboard.change.same", recent, previous)))
  }
  return Delta(icon: difference > 0 ? "chart.line.uptrend.xyaxis" : "chart.line.downtrend.xyaxis", good: (difference > 0) != lowerIsBetter,
               text: capitalizedFirst(L("dashboard.change.different", recent, previous, text)))
}

/// English sentences that start with a part left out still start with a capital.
func capitalizedFirst(_ text: String) -> String {
  text.prefix(1).uppercased() + text.dropFirst()
}
