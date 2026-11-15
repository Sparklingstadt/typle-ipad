import SwiftUI
import TypleCore

/// Each list's personal best (src/app/(workspace)/rankings/page.tsx): the lists, and for a chosen list its figures,
/// time trend and top records. Rank 1 is the best every other screen shows.
struct RankingsView: View {
  @Environment(AppModel.self) private var app
  @State private var order = RankOrder.accuracy
  @State private var sort = ListSort.recent
  @State private var device: String?
  @State private var query = ""
  @State private var showAll = false

  var body: some View {
    let devices = deviceOptions(app.lists.flatMap(\.records))
    PageScroll(maxWidth: 1088) {
      PageHeader(title: L("rankings.title"), description: L("rankings.intro"))
      // Normal, recall and Handwriting runs are ranked apart, as /rankings?mode= does.
      SegmentedPills(options: PracticeMode.allCases.map { ($0, L("rankings.mode.\($0.rawValue)")) },
                     selection: Binding(get: { app.rankingsMode }, set: { app.rankingsMode = $0 }))
        .fixedSize()
        .accessibilityLabel(L("rankings.mode.label"))
      HStack(spacing: 10) {
        Menu {
          Picker(L("rankings.filter.device"), selection: $device) {
            Text(L("rankings.filter.allDevices")).tag(String?.none)
            ForEach(devices, id: \.value) { option in
              Text(option.value == noDevice ? L("format.noDeviceRecorded") : Format.device(option.device)).tag(String?.some(option.value))
            }
          }
          .menuPicker()
        } label: {
          FilterLabel(name: L("rankings.filter.device"), value: device.map { value in
            value == noDevice ? L("format.noDeviceRecorded") : Format.device(devices.first { $0.value == value }?.device)
          } ?? L("records.filterMenu.all"))
        }
        .plainMenu()
        SegmentedPills(options: [(RankOrder.accuracy, L("rankings.order.accuracy")), (RankOrder.speed, L("rankings.order.speed"))], selection: $order)
        HStack(spacing: 4) {
          Image(systemName: "info.circle").font(.system(size: 11))
          Text(L(order == .accuracy ? "rankings.orderNotes.accuracy" : "rankings.orderNotes.speed"))
        }
        .font(.system(size: 12)).foregroundStyle(Palette.mutedForeground)
      }
      if let id = app.rankingsList, let list = app.lists.first(where: { $0.id == id }) {
        RankingDetailView(ranking: listRanking(list, device: device, order: order, includeOthers: showAll, mode: app.rankingsMode), order: order, showAll: $showAll)
      } else {
        lists
      }
    }
  }

  // MARK: The lists

  private var lists: some View {
    let rankings = sortRankings(app.lists.map { listRanking($0, device: device, order: order, mode: app.rankingsMode) }, sort: sort, locale: Localization.locale)
      .filter { query.isEmpty || $0.list.name.lowercased().contains(query.trimmingCharacters(in: .whitespaces).lowercased()) }
    let practised = rankings.filter { !$0.records.isEmpty }
    let unpractised = rankings.filter { $0.records.isEmpty }
    return VStack(spacing: 0) {
      HStack(spacing: 12) {
        SearchField(prompt: L("rankings.list.search"), text: $query)
        Menu {
          Picker(L("rankings.list.sortLabel", ""), selection: $sort) {
            ForEach(ListSort.allCases, id: \.self) { sort in Text(L("rankings.list.sorts.\(sort.rawValue)")).tag(sort) }
          }
          .menuPicker()
        } label: {
          HStack(spacing: 4) {
            Text(L("rankings.list.sorts.\(sort.rawValue)"))
            Image(systemName: "chevron.down").font(.system(size: 10, weight: .semibold))
          }
          .font(.system(size: 13)).foregroundStyle(Palette.mutedForeground)
        }
        .plainMenu()
      }
      .padding(12)
      Hairline()
      ForEach(practised.indices, id: \.self) { index in
        if index > 0 { Hairline() }
        RankingListRow(ranking: practised[index])
      }
      if !unpractised.isEmpty {
        Hairline()
        VStack(alignment: .leading, spacing: 0) {
          Text(device == nil ? L("rankings.list.noRecords", unpractised.count) : L("rankings.list.noDeviceRecords", unpractised.count))
            .font(.system(size: 12)).foregroundStyle(Palette.mutedForeground)
            .padding(.horizontal, 16).padding(.top, 14).padding(.bottom, 6)
          ForEach(unpractised) { ranking in
            Button { app.rankingsList = ranking.list.id } label: {
              HStack {
                Text(ranking.list.name).font(.system(size: 14)).foregroundStyle(Palette.mutedForeground)
                Spacer()
                Text(L("rankings.list.words", ranking.list.words.count)).font(.system(size: 12)).foregroundStyle(Palette.mutedForeground)
                Image(systemName: "chevron.right").font(.system(size: 11)).foregroundStyle(Palette.mutedForeground)
              }
              .padding(.horizontal, 16)
              .frame(height: 38)
              .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
          }
        }
        .padding(.bottom, 8)
      }
      if rankings.isEmpty {
        Text(L("rankings.list.noMatch", query)).font(.system(size: 14)).foregroundStyle(Palette.mutedForeground).padding(16)
      }
    }
    .card()
  }
}
