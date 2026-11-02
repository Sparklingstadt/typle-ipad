import CoreGraphics
import TypleCore
import Vision

/// Reads handwriting on the device with Vision, so the drawing never leaves it. The settings are the spec's: the
/// accurate recognizer in the list's language only, no language correction (it would turn a word into another one) and
/// no custom words (they could make a wrong character count as right).
enum WritingRecognizer {
  /// Vision's name for the language, such as ja-JP for ja, or nil when this device's Vision does not read it; the
  /// canvas is offered only then.
  static func visionLanguage(_ language: WritingLanguage) -> String? {
    let request = VNRecognizeTextRequest()
    request.recognitionLevel = .accurate
    let supported = (try? request.supportedRecognitionLanguages()) ?? []
    return supported.first { $0 == language.rawValue } ?? supported.first { $0.hasPrefix(language.rawValue + "-") }
  }

  @MainActor private static var supported: [WritingLanguage: Bool] = [:]

  @MainActor
  static func supports(_ language: WritingLanguage) -> Bool {
    if let known = supported[language] { return known }
    let known = visionLanguage(language) != nil
    supported[language] = known
    return known
  }

  /// The candidates for an image of the writing, best first; none when nothing was read or Vision failed.
  static func recognize(_ image: CGImage, language: WritingLanguage) async -> [String] {
    await Task.detached(priority: .userInitiated) {
      let request = VNRecognizeTextRequest()
      request.recognitionLevel = .accurate
      request.recognitionLanguages = [visionLanguage(language) ?? language.rawValue]
      request.usesLanguageCorrection = false
      do {
        try VNImageRequestHandler(cgImage: image).perform([request])
      } catch {
        return []
      }
      // Lines top to bottom, then left to right, so lines that are joined read in writing order.
      let lines = (request.results ?? []).sorted { a, b in
        abs(a.boundingBox.midY - b.boundingBox.midY) > 0.1 ? a.boundingBox.midY > b.boundingBox.midY : a.boundingBox.minX < b.boundingBox.minX
      }
      return writingCandidates(lines.map { $0.topCandidates(5).map(\.string) })
    }.value
  }
}
