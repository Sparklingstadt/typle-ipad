import SwiftUI
import TypleCore

/// The live elapsed time, speed, accuracy and mistakes. Only this view ticks, five times a second, while a run goes on.
struct LiveStatsView: View {
  var session: TypingSession
  /// Handwriting judges whole words, so it has no keys per minute to show.
  var showsSpeed = true

  var body: some View {
    let running = session.startedAt != nil && session.finishedAt == nil
    TimelineView(.periodic(from: .now, by: running ? 0.2 : 3600)) { context in
      let now = context.date.timeIntervalSince1970 * 1000
      let elapsed = running ? elapsedTime(session, now: now) : 0
      let speed = running ? typingSpeed(session, now: now) : nil
      HStack(spacing: 0) {
        stat("timer", L("practice.stats.elapsed"), clock(elapsed))
        if showsSpeed {
          stat("gauge.with.needle", L("practice.stats.speed"), speed.map { "\($0)" } ?? "—", unit: L("practice.stats.speedUnit"))
        }
        stat("target", L("practice.stats.accuracy"), session.attempts > 0 ? formatAccuracy(sessionResult(session).accuracy) : "—")
        stat("xmark", L("practice.stats.mistakes"), "\(session.mistakes)")
      }
      .padding(.vertical, 12)
      .background(Palette.muted.opacity(0.4), in: RoundedRectangle(cornerRadius: Radius.xl))
      .outlined()
    }
    .accessibilityElement(children: .contain)
    .accessibilityLabel(L("practice.stats.label"))
  }

  private func clock(_ milliseconds: Double) -> String {
    let seconds = milliseconds / 1000
    return String(format: "%d:%04.1f", Int(seconds / 60), seconds.truncatingRemainder(dividingBy: 60))
  }

  private func stat(_ icon: String, _ term: String, _ value: String, unit: String? = nil) -> some View {
    VStack(spacing: 2) {
      HStack(spacing: 4) {
        Image(systemName: icon).font(.system(size: 10))
        Text(term)
      }
      .font(.system(size: 12))
      .foregroundStyle(Palette.mutedForeground)
      HStack(alignment: .firstTextBaseline, spacing: 2) {
        Text(value).font(.system(size: 20, weight: .medium)).monospacedDigit()
        if let unit { Text(unit).font(.system(size: 12)).foregroundStyle(Palette.mutedForeground) }
      }
    }
    .frame(maxWidth: .infinity)
    .accessibilityElement(children: .combine)
  }
}
