import SwiftUI
import TypleCore

/// One record as a row of the table (src/components/Records/RecordRow.tsx).
struct RecordRowView: View {
  var row: RecordRow
  var onDelete: () -> Void

  var body: some View {
    let record = row.record
    HStack(spacing: 16) {
      Text(Format.time(record.date)).font(.system(size: 14)).monospacedDigit().foregroundStyle(Palette.mutedForeground).frame(width: 52, alignment: .leading)
      VStack(alignment: .leading, spacing: 2) {
        HStack(spacing: 8) {
          Text(row.list.name).font(.system(size: 16)).lineLimit(1)
          if row.mode != .normal {
            Text(L(row.mode == .writing ? "records.writingBadge" : "records.recallBadge"))
              .font(.system(size: 12, weight: .bold))
              .fixedSize()
              .foregroundStyle(Palette.mutedForeground)
              .padding(.horizontal, 8)
              .frame(height: 22)
              .background(Palette.muted, in: Capsule())
          }
          if row.best {
            Label(L("records.row.best"), systemImage: "trophy")
              .font(.system(size: 12, weight: .bold))
              .labelStyle(TightLabelStyle())
              .foregroundStyle(Palette.amber)
              .padding(.horizontal, 8)
              .frame(height: 22)
              .background(Palette.amberSoft, in: Capsule())
          }
        }
        Text([record.wordCount.map { L("records.row.words", $0) }, Format.device(record.device)].compactMap { $0 }.joined(separator: L("wordLists.row.separator")))
          .font(.system(size: 13)).foregroundStyle(Palette.mutedForeground).lineLimit(1)
      }
      .frame(maxWidth: .infinity, alignment: .leading)
      HStack(alignment: .firstTextBaseline, spacing: 1) {
        ForEach(Array(Format.durationParts(record.time).enumerated()), id: \.offset) { _, part in
          Text(part.0).font(.system(size: 15, weight: .bold)).monospacedDigit()
          Text(part.1).font(.system(size: 11)).foregroundStyle(Palette.mutedForeground)
        }
      }
      .frame(width: 90, alignment: .trailing)
      Text(record.accuracy.map { "\(Format.number($0))%" } ?? "—").font(.system(size: 14)).monospacedDigit()
        .foregroundStyle(record.accuracy.map { $0 < lowAccuracy } ?? false ? Palette.destructive : Palette.foreground)
        .frame(width: 70, alignment: .trailing)
      HStack(alignment: .firstTextBaseline, spacing: 1) {
        if let perWord = secondsPerWord(record) {
          Text(Format.seconds(perWord)).font(.system(size: 14)).monospacedDigit()
          Text(L("records.row.perWordUnit")).font(.system(size: 11)).foregroundStyle(Palette.mutedForeground)
        } else {
          Text("—").font(.system(size: 14))
        }
      }
      .frame(width: 84, alignment: .trailing)
      Text(record.mistakes.map(String.init) ?? "—").font(.system(size: 14)).monospacedDigit().frame(width: 44, alignment: .trailing)
      Button(action: onDelete) { Image(systemName: "trash").font(.system(size: 14)) }
        .buttonStyle(.typle(.ghost, size: .icon))
        .foregroundStyle(Palette.mutedForeground)
        .accessibilityLabel(L("records.row.deleteLabel", row.list.name, Format.date(record.date)))
        .frame(width: 32)
    }
    .padding(.horizontal, 20)
    .frame(minHeight: 68)
    .accessibilityElement(children: .combine)
  }
}
