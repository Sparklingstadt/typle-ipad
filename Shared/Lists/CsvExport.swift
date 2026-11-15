import SwiftUI
import TypleCore
import UniformTypeIdentifiers

/// A list's words as a CSV file, written only when shared (src/components/WordListExport.tsx).
struct CsvExport: Transferable {
  var list: WordList

  static var transferRepresentation: some TransferRepresentation {
    FileRepresentation(exportedContentType: .commaSeparatedText) { export in SentTransferredFile(try export.write()) }
  }

  /// The file's name: the list's name without the characters a file name cannot have.
  var fileName: String {
    let unsafe = CharacterSet(charactersIn: "/\\?%*|\"<>:").union(.newlines).union(.controlCharacters)
    let name = list.name.components(separatedBy: unsafe).joined(separator: "_").trimmingCharacters(in: .whitespaces)
    return (name.isEmpty ? "words" : name) + ".csv"
  }

  var data: Data { Data(encodeWordCsv(list.words).utf8) }

  func write() throws -> URL {
    let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString, isDirectory: true)
    try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
    let url = directory.appendingPathComponent(fileName)
    try data.write(to: url, options: .atomic)
    return url
  }
}
