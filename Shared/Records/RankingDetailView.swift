import SwiftUI
import TypleCore

/// One list's rankings: its figures, the time trend and the top records, in the chosen order.
struct RankingDetailView: View {
  @Environment(AppModel.self) private var app
  var ranking: ListRanking
  var order: RankOrder
  /// Every ranked record instead of the top ones.
  @Binding var showAll: Bool

  var body: some View {
    let stats = rankingStats(ranking.ranked)
    let shown = showAll ? ranking.ranked : Array(ranking.ranked.prefix(rankingTop))
    VStack(alignment: .leading, spacing: 24) {
      Button { app.rankingsList = nil } label: {
        HStack(spacing: 6) { Image(systemName: "arrow.left").font(.system(size: 12)); Text(L("rankings.detail.back")) }
          .font(.system(size: 13, weight: .medium))
      }
      .buttonStyle(.plain)
      HStack(alignment: .top) {
        VStack(alignment: .leading, spacing: 6) {
          Text(ranking.list.name).font(.system(size: 22, weight: .bold))
          Text([L("rankings.detail.words", ranking.list.words.count), L("rankings.detail.records", ranking.records.count),
                ranking.lastPracticed.map { L("rankings.detail.lastPracticed", Format.day($0)) }].compactMap { $0 }.joined(separator: "  ·  "))
            .font(.system(size: 13)).foregroundStyle(Palette.mutedForeground)
        }
        Spacer()
        Button { app.navigate(.records) } label: {
          HStack(spacing: 6) { Text(L("rankings.detail.viewRecords")); Image(systemName: "arrow.right").font(.system(size: 11)) }
        }
        .buttonStyle(.typle(.ghost))
        Button { app.practice(listId: ranking.list.id) } label: { Label(L("rankings.detail.practice"), systemImage: "keyboard") }
          .buttonStyle(.typle())
      }
      if ranking.records.isEmpty {
        VStack(alignment: .leading, spacing: 6) {
          Text(L("rankings.detail.notPractised.title")).font(.system(size: 16, weight: .semibold))
          Text(L("rankings.detail.notPractised.description")).font(.system(size: 14)).foregroundStyle(Palette.mutedForeground)
        }
        .padding(20).frame(maxWidth: .infinity, alignment: .leading)
        .callout(.muted)
      } else {
        HStack(spacing: 12) {
          if let best = ranking.best {
            figure(L("rankings.detail.stats.best"), Format.seconds(best.time), unit: L("format.secondsUnit"),
                   note: L("rankings.detail.stats.bestNote", formatAccuracy(best.accuracy), parseDate(best.date).map { Format.day($0) } ?? ""), highlight: true)
          }
          figure(L("rankings.detail.stats.recentAverage", stats.recentCount), stats.recentTime.map(Format.seconds) ?? "—", unit: L("format.secondsUnit"),
                 note: stats.recentTime.flatMap { recent in ranking.best.map { recent - $0.time } }.map { $0 < 0.005 ? L("rankings.detail.stats.sameAsBest") : L("rankings.detail.stats.behindBest", Format.seconds($0)) } ?? "")
          figure(L("rankings.detail.stats.accuracy"), stats.recentAccuracy.map { String(format: "%.1f", $0) } ?? "—", unit: "%",
                 note: L("rankings.detail.stats.recent", stats.recentCount))
          figure(L("rankings.detail.stats.runs"), "\(ranking.ranked.count)", unit: L("rankings.detail.stats.runsUnit"),
                 note: L("rankings.detail.stats.atCount", ranking.list.words.count))
        }
        VStack(alignment: .leading, spacing: 10) {
          HStack(alignment: .firstTextBaseline, spacing: 6) {
            Text(L("rankings.detail.trend.title")).font(.system(size: 14, weight: .bold))
            Text(L("rankings.detail.trend.recent", stats.points.count)).font(.system(size: 14)).foregroundStyle(Palette.mutedForeground)
          }
          if stats.points.count > 1 {
            TrendChart(points: stats.points.map { TrendPoint(date: $0.date, value: $0.value) }, scale: speedScale(stats.points.map { $0.value }))
              .padding(14)
              .callout(.muted)
          } else {
            Text(L("rankings.detail.trend.needTwo")).font(.system(size: 14)).foregroundStyle(Palette.mutedForeground)
              .padding(14).frame(maxWidth: .infinity, alignment: .leading)
              .callout(.muted)
          }
        }
        if ranking.fallback {
          Text(L("rankings.fallback", ranking.list.words.count)).font(.system(size: 13)).foregroundStyle(Palette.mutedForeground)
        }
        VStack(alignment: .leading, spacing: 4) {
          HStack(alignment: .firstTextBaseline, spacing: 6) {
            Text(L("rankings.detail.top.title")).font(.system(size: 14, weight: .bold))
            Text(L(order == .accuracy ? "rankings.detail.top.accuracy" : "rankings.detail.top.speed")).font(.system(size: 14)).foregroundStyle(Palette.mutedForeground)
            Spacer()
            Text(L("rankings.detail.top.shown", shown.count, ranking.ranked.count)).font(.system(size: 12)).foregroundStyle(Palette.mutedForeground)
          }
          HStack(spacing: 12) {
            Text(L("rankings.detail.columns.rank")).frame(width: 36, alignment: .leading)
            Text(L("records.columns.duration")).frame(width: 130, alignment: .leading)
            Text(L("records.columns.accuracy")).frame(width: 70, alignment: .leading)
            Text(L("records.columns.mistakes")).frame(width: 46, alignment: .leading)
            Text(L("rankings.detail.columns.device")).frame(maxWidth: .infinity, alignment: .leading)
            Text(L("rankings.detail.columns.date")).frame(width: 110, alignment: .trailing)
          }
          .font(.system(size: 12)).foregroundStyle(Palette.mutedForeground)
          .padding(.horizontal, 8).padding(.vertical, 8)
          .hairline(.bottom)
          ForEach(shown.indices, id: \.self) { index in
            let record = shown[index]
            let recent = parseDate(record.date).map { Date().timeIntervalSince($0) < improvedDays * 86400 } ?? false
            HStack(spacing: 12) {
              RankBadge(rank: index + 1).frame(width: 36, alignment: .leading)
              SecondsText(seconds: record.time)
                .frame(width: 130, alignment: .leading)
              Text(formatAccuracy(record.accuracy)).font(.system(size: 14)).monospacedDigit().frame(width: 70, alignment: .leading)
              Text(record.mistakes.map(String.init) ?? "—").font(.system(size: 14)).foregroundStyle(Palette.mutedForeground).frame(width: 46, alignment: .leading)
              Text(Format.device(record.device)).font(.system(size: 14)).lineLimit(1).frame(maxWidth: .infinity, alignment: .leading)
              Text(Format.date(record.date)).font(.system(size: 13, weight: recent ? .medium : .regular))
                .foregroundStyle(recent ? Palette.success : Palette.mutedForeground).frame(width: 110, alignment: .trailing)
            }
            .padding(.horizontal, 8)
            .frame(height: 44)
            .background(index == 0 ? Palette.amberSoft.opacity(0.4) : .clear)
          }
          if ranking.ranked.count > rankingTop {
            Button(showAll ? L("rankings.detail.top.showTop", rankingTop) : L("rankings.detail.top.showAll", ranking.ranked.count)) { showAll.toggle() }
              .buttonStyle(.typle(.ghost, size: .sm))
          }
        }
      }
    }
    .padding(24)
    .card()
  }

  private func figure(_ term: String, _ value: String, unit: String, note: String, highlight: Bool = false) -> some View {
    VStack(alignment: .leading, spacing: 4) {
      HStack(spacing: 4) {
        if highlight { Image(systemName: "trophy").font(.system(size: 11)).foregroundStyle(Palette.amber) }
        Text(term)
      }
      .font(.system(size: 12)).foregroundStyle(Palette.mutedForeground)
      ValueWithUnit(value: value, unit: unit, size: 24)
      Text(note).font(.system(size: 12)).foregroundStyle(Palette.mutedForeground).lineLimit(1)
    }
    .frame(maxWidth: .infinity, alignment: .leading)
    .padding(16)
    .background(highlight ? Palette.amberSoft.opacity(0.35) : Palette.card, in: RoundedRectangle(cornerRadius: Radius.xl))
    .outlined(color: highlight ? Palette.amberBorder : Palette.border)
  }
}
