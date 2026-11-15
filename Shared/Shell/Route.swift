import Foundation

/// The web app's pages, in the order of its sidebar.
enum Route: Hashable {
  case home, practice, records, rankings, lists, createList, editList(String), general, devices

  /// The sidebar item a page belongs to; the list editor belongs to 単語リスト as /edit/<id> does.
  var navigationItem: Route {
    if case .editList = self { return .lists }
    return self
  }

  /// For launch arguments (`-TypleRoute records`) when taking screenshots.
  init?(name: String) {
    let routes: [String: Route] = ["home": .home, "practice": .practice, "records": .records, "rankings": .rankings,
                                   "lists": .lists, "createList": .createList, "general": .general, "devices": .devices]
    guard let route = routes[name] else { return nil }
    self = route
  }
}
