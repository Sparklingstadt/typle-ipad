import SwiftUI
import TypleCore

/// Every record, newest first and grouped by day, filtered by list and device (src/app/(workspace)/records/page.tsx).
struct RecordsView: View {
  @Environment(AppModel.self) private var app
  @State private var listFilter: String?
  @State private var deviceFilter: String?
  @State private var deleting: RecordRow?
  @State private var status: StatusMessage?

  var body: some View {
    let all = recordRows(app.lists)
    let rows = filterRows(all, list: listFilter, device: deviceFilter)
    let options = deviceOptions(all.filter { listFilter == nil || $0.list.id == listFilter }.map(\.record))
    PageScroll {
      PageHeader(title: L("records.title"), description: L("records.intro"))
      if let status { StatusLabel(status: status) }
      if all.isEmpty {
        empty(title: L("records.empty.title"), description: L("records.empty.description"))
      } else {
        HStack(spacing: 8) {
          Menu {
            Picker(L("records.filter.list"), selection: $listFilter) {
              Text(L("records.filter.allLists")).tag(String?.none)
              ForEach(app.lists.filter { !$0.records.isEmpty }) { list in
                Text(L("records.filterMenu.option", list.name, list.records.count)).tag(String?.some(list.id))
              }
            }
            .menuPicker()
          } label: {
            FilterLabel(name: L("records.filter.list"), value: listFilter.flatMap { id in app.lists.first { $0.id == id }?.name } ?? L("records.filterMenu.all"))
          }
          .plainMenu()
          Menu {
            Picker(L("records.filter.device"), selection: $deviceFilter) {
              Text(L("records.filter.allDevices")).tag(String?.none)
              ForEach(options, id: \.value) { option in
                Text(L("records.filterMenu.option", option.value == noDevice ? L("format.noDeviceRecorded") : Format.device(option.device), option.count))
                  .tag(String?.some(option.value))
              }
            }
            .menuPicker()
          } label: {
            FilterLabel(name: L("records.filter.device"), value: deviceFilter.map { value in
              value == noDevice ? L("format.noDeviceRecorded") : Format.device(options.first { $0.value == value }?.device)
            } ?? L("records.filterMenu.all"))
          }
          .plainMenu()
          if listFilter != nil || deviceFilter != nil {
            Button(L("records.filter.clear")) { listFilter = nil; deviceFilter = nil }.buttonStyle(.typle(.ghost))
          }
          Spacer()
          Text(rows.count == all.count ? L("records.filter.count", all.count) : L("records.filter.filteredCount", rows.count, all.count))
            .font(.system(size: 14)).foregroundStyle(Palette.mutedForeground)
        }
        if rows.isEmpty {
          empty(title: L("records.filteredEmpty.title"), description: L("records.filteredEmpty.description"))
        } else {
          VStack(alignment: .leading, spacing: 12) {
            columns
            ForEach(groupByDay(rows), id: \.day) { group in
              VStack(alignment: .leading, spacing: 10) {
                HStack {
                  Text(dayHeading(group.day)).font(.system(size: 14, weight: .bold))
                  Spacer()
                  Text(L("records.day.summary", group.rows.count, Format.total(group.seconds))).font(.system(size: 12)).foregroundStyle(Palette.mutedForeground)
                }
                .padding(.horizontal, 4)
                .padding(.top, 8)
                VStack(spacing: 0) {
                  ForEach(group.rows.indices, id: \.self) { index in
                    if index > 0 { Hairline() }
                    RecordRowView(row: group.rows[index]) { deleting = group.rows[index] }
                  }
                }
                .card()
              }
            }
          }
          Text(L("records.note")).font(.system(size: 12)).foregroundStyle(Palette.mutedForeground)
        }
      }
    }
    .confirmationDialog(L("records.delete.title"), isPresented: Binding(get: { deleting != nil }, set: { if !$0 { deleting = nil } }),
                        titleVisibility: .visible, presenting: deleting) { row in
      Button(L("common.delete.confirm"), role: .destructive) { delete(row) }
    } message: { row in
      Text(L("records.delete.description", row.list.name) + "\n" + Format.date(row.record.date) + " · " + Format.duration(row.record.time))
    }
  }

  /// 「今日・10月20日（火）」 for today and yesterday, the date alone for other days.
  private func dayHeading(_ day: Date) -> String {
    switch dayKind(day) {
    case .today, .yesterday: return L("records.day.heading", Format.day(day), Format.dateWithWeekday(day))
    case .thisYear, .otherYear: return Format.dateWithWeekday(day)
    }
  }

  private var columns: some View {
    HStack(spacing: 16) {
      Text(L("records.columns.time")).frame(width: 52, alignment: .leading)
      Text(L("records.columns.listDevice")).frame(maxWidth: .infinity, alignment: .leading)
      Text(L("records.columns.duration")).frame(width: 90, alignment: .trailing)
      Text(L("records.columns.accuracy")).frame(width: 70, alignment: .trailing)
      Text(L("records.columns.perWord")).frame(width: 84, alignment: .trailing)
      Text(L("records.columns.mistakes")).frame(width: 44, alignment: .trailing)
      Color.clear.frame(width: 32, height: 1)
    }
    .font(.system(size: 12))
    .foregroundStyle(Palette.mutedForeground)
    .padding(.horizontal, 20)
  }

  private func empty(title: String, description: String) -> some View {
    VStack(spacing: 12) {
      IconTile(systemName: "clock.arrow.circlepath")
      Text(title).font(.system(size: 16, weight: .semibold))
      Text(description).font(.system(size: 14)).foregroundStyle(Palette.mutedForeground).multilineTextAlignment(.center)
      Button { app.navigate(.practice) } label: { Label(L("records.empty.practice"), systemImage: "keyboard") }.buttonStyle(.typle())
    }
    .frame(maxWidth: .infinity)
    .padding(40)
    .overlay(RoundedRectangle(cornerRadius: Radius.xl).strokeBorder(Palette.border, style: StrokeStyle(lineWidth: 1, dash: [4, 3])))
  }

  private func delete(_ row: RecordRow) {
    Task {
      do {
        try await app.deleteRecord(row.record, listId: row.list.id)
        status = .done(L("records.delete.done", row.list.name, Format.date(row.record.date)))
      } catch {
        status = .failure(error)
      }
    }
  }
}
