import SwiftUI
import TypleCore

/// A practised list among the rankings: its best time and accuracy, whether it improved lately, and its runs.
struct RankingListRow: View {
  @Environment(AppModel.self) private var app
  var ranking: ListRanking

  var body: some View {
    Button { app.rankingsList = ranking.list.id } label: {
      HStack(spacing: 12) {
        VStack(alignment: .leading, spacing: 3) {
          Text(ranking.list.name).font(.system(size: 15, weight: .medium)).foregroundStyle(Palette.foreground)
          if let best = ranking.best {
            HStack(spacing: 8) {
              Image(systemName: "trophy").font(.system(size: 11)).foregroundStyle(Palette.amber)
              HStack(alignment: .firstTextBaseline, spacing: 1) {
                Text(Format.seconds(best.time)).font(.system(size: 13, weight: .semibold)).monospacedDigit()
                Text(L("format.secondsUnit")).font(.system(size: 10)).foregroundStyle(Palette.mutedForeground)
              }
              Text(formatAccuracy(best.accuracy)).font(.system(size: 13)).foregroundStyle(Palette.mutedForeground)
              if ranking.improved {
                HStack(spacing: 2) {
                  Image(systemName: "chart.line.uptrend.xyaxis").font(.system(size: 9))
                  Text(L("rankings.list.improved"))
                }
                .font(.system(size: 12, weight: .medium)).foregroundStyle(Palette.success)
              }
            }
          }
        }
        Spacer()
        VStack(alignment: .trailing, spacing: 3) {
          Text(ranking.lastPracticed.map { Format.day($0) } ?? "").font(.system(size: 12)).foregroundStyle(Palette.mutedForeground)
          Text(L("rankings.list.runs", ranking.records.count)).font(.system(size: 12)).foregroundStyle(Palette.mutedForeground)
        }
        Image(systemName: "chevron.right").font(.system(size: 12)).foregroundStyle(Palette.mutedForeground)
      }
      .padding(.horizontal, 16)
      .padding(.vertical, 12)
      .contentShape(Rectangle())
    }
    .buttonStyle(.plain)
  }
}
