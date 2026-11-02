import Foundation
import Observation
import TypleCore

/// How Handwriting is written: on the canvas, which Vision reads, or into a field by the system's handwriting input
/// (Scribble, the trackpad's handwriting).
enum WritingMethod: String {
  case canvas, system
}

/// Whether lists marked for Handwriting are practised by typing or by hand, and how (src/lib/writingMode.ts). One
/// choice for the device, remembered in UserDefaults; only `writing` is written, as the web app does.
@MainActor
@Observable
final class WritingChoice {
  private static let modeKey = "writingMode"
  private static let methodKey = "writingMethod"

  var writing: Bool {
    didSet {
      if writing { UserDefaults.standard.set("writing", forKey: Self.modeKey) }
      else { UserDefaults.standard.removeObject(forKey: Self.modeKey) }
    }
  }

  var method: WritingMethod {
    didSet { UserDefaults.standard.set(method.rawValue, forKey: Self.methodKey) }
  }

  init() {
    writing = UserDefaults.standard.string(forKey: Self.modeKey) == "writing"
    method = UserDefaults.standard.string(forKey: Self.methodKey).flatMap(WritingMethod.init) ?? .canvas
  }

  func mode(for list: WordList?) -> PracticeMode {
    practiceMode(list, writing: writing)
  }
}
