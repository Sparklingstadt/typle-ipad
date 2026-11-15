import SwiftUI
import TypleCore

/// One list's speed and accuracy over its latest runs.
struct TrendCard: View {
  @Environment(AppModel.self) private var app
  var trend: ListTrend
  var now: Date

  var body: some View {
    VStack(alignment: .leading, spacing: 20) {
      HStack(alignment: .firstTextBaseline) {
        Text(trend.list.name).font(.system(size: 16, weight: .medium))
        Spacer()
        Text(L("dashboard.trends.summary", trend.count, Format.day(trend.lastPracticed, now: now))).font(.system(size: 13)).foregroundStyle(Palette.mutedForeground)
      }
      if trend.count < 2 {
        Text(L("dashboard.trends.needTwo")).font(.system(size: 14)).foregroundStyle(Palette.mutedForeground)
        Button { app.practice(listId: trend.list.id) } label: { Label(L("dashboard.trends.practice"), systemImage: "keyboard") }
          .buttonStyle(.typle(.outline))
      } else {
        metric(L("dashboard.trends.speed"), trend.speed, scale: trend.speed.points.count > 1 ? speedScale(trend.speed.points.map(\.value)) : nil,
               format: { L("dashboard.trends.seconds", String(format: "%.2f", $0)) }, lowerIsBetter: true, describe: secondsDifference)
        metric(L("dashboard.trends.accuracy"), trend.accuracy, scale: trend.accuracy.points.count > 1 ? accuracyScale(trend.accuracy.points.map(\.value)) : nil,
               format: { String(format: "%.1f%%", $0) }, lowerIsBetter: false, describe: pointDifference)
        Text(L("dashboard.trends.best", trend.best.accuracy.map { "\(Format.number($0, digits: 2))%" } ?? L("dashboard.trends.notRecorded"),
               Format.seconds(trend.best.time), Format.day(parseDate(trend.best.date) ?? now, now: now)))
          .font(.system(size: 13)).foregroundStyle(Palette.mutedForeground)
          .padding(.top, 12)
          .frame(maxWidth: .infinity, alignment: .leading)
          .hairline(.top)
      }
    }
    .padding(20)
    .outlined()
  }

  private func metric(_ title: String, _ trend: Trend, scale: Scale?, format: @escaping (Double) -> String, lowerIsBetter: Bool,
                      describe: (Double) -> String?) -> some View {
    VStack(alignment: .leading, spacing: 8) {
      HStack(alignment: .firstTextBaseline) {
        Text(title).font(.system(size: 13)).foregroundStyle(Palette.mutedForeground)
        Spacer()
        if let latest = trend.points.last {
          HStack(alignment: .firstTextBaseline, spacing: 4) {
            Text(L("dashboard.trends.latest")).font(.system(size: 12)).foregroundStyle(Palette.mutedForeground)
            Text(format(latest.value)).font(.system(size: 16, weight: .semibold))
          }
        }
      }
      if let change = trend.change { DeltaText(delta: changeDelta(change, lowerIsBetter: lowerIsBetter, describe: describe)) }
      if let scale {
        TrendChart(points: trend.points, scale: scale)
      } else {
        Text(L("dashboard.trends.noChart")).font(.system(size: 14)).foregroundStyle(Palette.mutedForeground)
      }
    }
  }
}
