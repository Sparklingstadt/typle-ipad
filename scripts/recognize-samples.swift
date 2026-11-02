// Draws a few words per language in a handwriting-like font and reads them with Vision as the app does, printing
// whether each word is among the candidates. It is a look at the recognizer, not a test: accuracy is not a pass
// condition. Run on a Mac: swift scripts/recognize-samples.swift
import AppKit
import Vision

let samples: [(String, [String])] = [
  ("en", ["apple", "I am a student."]), ("ja", ["練習", "ありがとう"]), ("zh-Hans", ["爱护", "学习"]), ("zh-Hant", ["學習"]),
  ("ko", ["한국"]), ("fr", ["café"]), ("de", ["Straße"]), ("es", ["mañana"]), ("ru", ["привет"]), ("cs", ["děkuji"]),
]

func image(_ text: String) -> CGImage? {
  let font = NSFont(name: "Bradley Hand", size: 64) ?? NSFont(name: "Klee", size: 64) ?? .systemFont(ofSize: 64)
  let string = NSAttributedString(string: text, attributes: [.font: font, .foregroundColor: NSColor.black])
  let size = NSSize(width: string.size().width + 80, height: 160)
  let bitmap = NSImage(size: size, flipped: false) { rect in
    NSColor.white.setFill()
    rect.fill()
    string.draw(at: NSPoint(x: 40, y: 40))
    return true
  }
  return bitmap.cgImage(forProposedRect: nil, context: nil, hints: nil)
}

let probe = VNRecognizeTextRequest()
probe.recognitionLevel = .accurate
let supported = (try? probe.supportedRecognitionLanguages()) ?? []
print("| language | Vision | word | read | in candidates |")
print("|---|---|---|---|---|")
for (language, words) in samples {
  let vision = supported.first { $0 == language } ?? supported.first { $0.hasPrefix(language + "-") }
  for word in words {
    guard let vision, let cg = image(word) else {
      print("| \(language) | — | \(word) | not supported | — |")
      continue
    }
    let request = VNRecognizeTextRequest()
    request.recognitionLevel = .accurate
    request.recognitionLanguages = [vision]
    request.usesLanguageCorrection = false
    try? VNImageRequestHandler(cgImage: cg).perform([request])
    let candidates = (request.results ?? []).flatMap { $0.topCandidates(5).map(\.string) }
    let found = candidates.contains { $0.precomposedStringWithCanonicalMapping.split(whereSeparator: \.isWhitespace).joined(separator: " ") == word }
    print("| \(language) | \(vision) | \(word) | \(candidates.first ?? "") | \(found ? "yes" : "no") |")
  }
}
