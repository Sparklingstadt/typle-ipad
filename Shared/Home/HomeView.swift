import SwiftUI
import TypleCore

/// The home dashboard (src/components/Dashboard/Dashboard.tsx): this week's summary, lists to practise next and each
/// list's trend. With no records yet it shows how to start instead.
struct HomeView: View {
  @Environment(AppModel.self) private var app
  @State private var now = Date()

  var body: some View {
    ScrollView {
      VStack(alignment: .leading, spacing: 44) {
        if app.lists.contains(where: { !$0.records.isEmpty }) { dashboard } else { welcome }
      }
      .padding(.horizontal, 64)
      .padding(.vertical, 56)
      .frame(maxWidth: 1280, alignment: .leading)
      .card()
      .padding(.horizontal, 48)
      .padding(.vertical, 32)
      .frame(maxWidth: .infinity)
    }
    .background(Palette.page)
  }

  private var welcome: some View {
    VStack(alignment: .leading, spacing: 16) {
      Text(L("home.welcomeTitle")).font(.system(size: 30, weight: .regular))
      Text(L("home.welcomeDescription")).font(.system(size: 14)).foregroundStyle(Palette.mutedForeground)
      startButtons
    }
  }

  private var startButtons: some View {
    HStack(spacing: 12) {
      Button { app.navigate(.practice) } label: { Label(L("dashboard.practice"), systemImage: "keyboard") }.buttonStyle(.typle(.primary, size: .lg))
      Button { app.navigate(.createList) } label: { Label(L("dashboard.create"), systemImage: "plus") }.buttonStyle(.typle(.outline, size: .lg))
    }
  }

  @ViewBuilder
  private var dashboard: some View {
    let summary = summarize(app.lists, now: now)
    VStack(alignment: .leading, spacing: 16) {
      VStack(alignment: .leading, spacing: 8) {
        Text(L("dashboard.title")).font(.system(size: 30, weight: .regular))
        Text(app.storage == .account ? L("dashboard.sourceAccount") : L("dashboard.sourceLocal")).font(.system(size: 14)).foregroundStyle(Palette.mutedForeground)
      }
      startButtons
    }
    section(L("dashboard.week.title"), L("dashboard.week.description", Format.dateWithWeekday(summary.weekStart),
                                          Format.dateWithWeekday(Calendar.current.date(byAdding: .day, value: 6, to: summary.weekStart)!))) {
      LazyVGrid(columns: [GridItem(.flexible(), spacing: 16), GridItem(.flexible(), spacing: 16)], spacing: 16) {
        stat(L("dashboard.week.count"), [("\(summary.weekCount)", L("dashboard.week.countUnit"))],
             weekDelta(summary.weekCount, summary.previousWeekCount) { L("dashboard.week.times", Int($0)) })
        stat(L("dashboard.week.streak"), [("\(summary.streak)", L("dashboard.week.streakUnit"))], summary.practicedToday
             ? Delta(icon: "checkmark", good: true, text: L("dashboard.week.practisedToday"))
             : Delta(icon: "keyboard", good: false, text: L("dashboard.week.streakNext", summary.streak + 1)))
        stat(L("dashboard.week.accuracy", summary.accuracy?.recentCount ?? 10),
             summary.accuracy.map { [(String(format: "%.1f", $0.recent), "%")] } ?? [("—", "")],
             summary.accuracy?.change.map { changeDelta($0, lowerIsBetter: false, describe: pointDifference, namedRecent: false) }
               ?? Delta(icon: "minus", good: false, text: L(summary.accuracy == nil ? "dashboard.week.noAccuracy" : "dashboard.week.noComparison")))
        stat(L("dashboard.week.time"), Format.totalParts(summary.weekSeconds),
             weekDelta(Int(summary.weekSeconds.rounded()), Int(summary.previousWeekSeconds.rounded())) { Format.total(Double($0)) })
      }
    }
    section(L("dashboard.next.title"), L("dashboard.next.description", staleDays, Int(lowAccuracy))) {
      nextLists
    }
    section(L("dashboard.trends.title"), L("dashboard.trends.description")) {
      LazyVGrid(columns: [GridItem(.flexible(), spacing: 16, alignment: .top), GridItem(.flexible(), spacing: 16, alignment: .top)], alignment: .leading, spacing: 16) {
        ForEach(listTrends(app.lists)) { trend in TrendCard(trend: trend, now: now) }
      }
    }
  }

  private func section<Content: View>(_ title: String, _ description: String, @ViewBuilder content: () -> Content) -> some View {
    VStack(alignment: .leading, spacing: 16) {
      VStack(alignment: .leading, spacing: 4) {
        Text(title).font(.system(size: 20)).accessibilityAddTraits(.isHeader)
        Text(description).font(.system(size: 14)).foregroundStyle(Palette.mutedForeground).fixedSize(horizontal: false, vertical: true)
      }
      content()
    }
  }

  private func stat(_ label: String, _ parts: [(String, String)], _ delta: Delta) -> some View {
    VStack(alignment: .leading, spacing: 8) {
      Text(label).font(.system(size: 13)).foregroundStyle(Palette.mutedForeground)
      HStack(alignment: .firstTextBaseline, spacing: 2) {
        ForEach(parts.indices, id: \.self) { index in
          Text(parts[index].0).font(.system(size: 26, weight: .semibold)).monospacedDigit()
          Text(parts[index].1).font(.system(size: 14)).foregroundStyle(Palette.mutedForeground).padding(.trailing, 4)
        }
      }
      DeltaText(delta: delta)
    }
    .frame(maxWidth: .infinity, alignment: .leading)
    .padding(16)
    .outlined()
    .accessibilityElement(children: .combine)
  }

  private var nextLists: some View {
    let items = TypleCore.nextLists(app.lists, now: now)
    return Group {
      if items.isEmpty {
        Text(L("dashboard.next.allPractised")).font(.system(size: 14)).padding(16).frame(maxWidth: .infinity, alignment: .leading).outlined()
      } else {
        VStack(spacing: 0) {
          ForEach(items.indices, id: \.self) { index in
            if index > 0 { Hairline() }
            nextRow(items[index])
          }
        }
        .outlined()
      }
    }
  }

  private func nextRow(_ item: NextList) -> some View {
    let badge: (String, String) = {
      switch item.reason {
      case .new: return ("sparkles", L("dashboard.next.new"))
      case .stale(let days): return ("clock", L("dashboard.next.stale", days))
      case .accuracy(let accuracy, let count): return ("target", L("dashboard.next.lowAccuracy", count, String(format: "%.1f", accuracy)))
      }
    }()
    return HStack(spacing: 16) {
      VStack(alignment: .leading, spacing: 2) {
        Text(item.list.name).font(.system(size: 16, weight: .medium))
        Text(L("dashboard.next.words", item.list.words.count) + " · " + (item.lastPracticed.map { L("dashboard.next.lastPracticed", Format.day($0, now: now)) } ?? L("dashboard.next.noRecords")))
          .font(.system(size: 13)).foregroundStyle(Palette.mutedForeground)
      }
      Spacer(minLength: 0)
      Pill(height: 24) {
        Image(systemName: badge.0).font(.system(size: 10))
        Text(badge.1)
      }
      Button(L("dashboard.next.practice")) { app.practice(listId: item.list.id) }.buttonStyle(.typle(.outline, size: .lg))
    }
    .padding(.horizontal, 20)
    .padding(.vertical, 16)
  }

  private func weekDelta(_ current: Int, _ previous: Int, format: (Int) -> String) -> Delta {
    if current == previous { return Delta(icon: "minus", good: false, text: L("dashboard.week.sameAsLastWeek")) }
    let more = current > previous
    return Delta(icon: more ? "chart.line.uptrend.xyaxis" : "chart.line.downtrend.xyaxis", good: more,
                 text: L(more ? "dashboard.week.moreThanLastWeek" : "dashboard.week.lessThanLastWeek", format(abs(current - previous))))
  }
}
