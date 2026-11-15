import SwiftUI
import TypleCore

/// The five best runs of a list (src/components/Practice/PracticeBestRecords.tsx).
struct BestRecordsView: View {
  var records: [StoredRecord]
  var highlightId: String?

  var body: some View {
    let best = bestRecords(records)
    if best.isEmpty {
      Text(L("practice.best.empty"))
        .font(.system(size: 14))
        .foregroundStyle(Palette.mutedForeground)
        .padding(.horizontal, 8)
        .padding(.vertical, 12)
        .fixedSize(horizontal: false, vertical: true)
    } else {
      VStack(spacing: 2) {
        ForEach(best.indices, id: \.self) { index in
          let record = best[index]
          let current = record.id != nil && record.id == highlightId
          HStack(spacing: 10) {
            RankBadge(rank: index + 1)
            Text(L("practice.best.seconds", Format.seconds(record.time))).font(.system(size: 14, weight: .medium)).monospacedDigit()
            Text(record.accuracy.map { "\(Format.number($0, digits: 2))%" } ?? L("practice.best.noAccuracy"))
              .font(.system(size: 14)).monospacedDigit()
            Text(Format.device(record.device)).font(.system(size: 12)).foregroundStyle(Palette.mutedForeground).lineLimit(1)
            Spacer(minLength: 0)
            if current { Text("NEW").font(.system(size: 10, weight: .bold)).foregroundStyle(Palette.success) }
          }
          .padding(.horizontal, 8)
          .frame(height: 36)
          .background(current ? Palette.successSoft : .clear, in: RoundedRectangle(cornerRadius: Radius.md))
          .accessibilityElement(children: .combine)
        }
      }
    }
  }
}
