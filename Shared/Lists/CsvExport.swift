import SwiftUI
import TypleCore
import UniformTypeIdentifiers

/// A list's words as a CSV file, written only when shared (src/components/WordListExport.tsx).
struct CsvExport: Transferable {
  var list: WordList

  static var transferRepresentation: some TransferRepresentation {
    FileRepresentation(exportedContentType: .commaSeparatedText) { export in SentTransferredFile(try export.write()) }
  }

  /// The file's name, made safe to save as the web app makes it.
  var fileName: String { wordFilename(list.name, format: .csv) }

  var data: Data { Data(encodeWordCsv(list.words).utf8) }

  func write() throws -> URL {
    let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString, isDirectory: true)
    try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
    let url = directory.appendingPathComponent(fileName)
    try data.write(to: url, options: .atomic)
    return url
  }
}
