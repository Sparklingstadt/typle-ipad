import Foundation

/// The account's workspace as `/api/graphql` answers and saves it (src/plugins/storage/cloud/client.ts): the
/// document, and the revision a save must name so that it does not overwrite a change made elsewhere since.
public struct AccountWorkspace: Equatable, Sendable {
  public var accountId: String
  public var revision: Int
  public var document: WorkspaceDocument

  public init(accountId: String, revision: Int, document: WorkspaceDocument) {
    self.accountId = accountId
    self.revision = revision
    self.document = document
  }
}

private struct AccountWorkspaceBody: Codable {
  var lists: [WordList]
  /// Left out of a save for an account whose lists were saved before packs: the backend then makes them.
  var packs: [WordPack]?
  var devices: [PracticeDevice]?
  var revision: Int
  var accountId: String
}

/// Reads a workspace as the backend gives it.
public func decodeAccountWorkspace(_ data: Data) throws -> AccountWorkspace {
  let body: AccountWorkspaceBody
  do { body = try JSONDecoder().decode(AccountWorkspaceBody.self, from: data) } catch { throw TypleError("invalidServerData") }
  return try accountWorkspace(from: body)
}

/// The lists of followed official packs come without their words (typle-r v2.1.0), which the catalog puts back. An
/// account that has saved nothing (revision 0) starts following every official pack, and the first save keeps them.
private func accountWorkspace(from body: AccountWorkspaceBody) throws -> AccountWorkspace {
  guard body.revision >= 0, !body.accountId.isEmpty else { throw TypleError("invalidServerData") }
  let library: (packs: [WordPack]?, lists: [WordList])
  if body.revision == 0 {
    let start = startingLibrary()
    library = (start.packs, start.lists)
  } else if let packs = body.packs {
    let followed = followOfficial(packs: packs, lists: body.lists)
    library = (followed.packs, followed.lists)
  } else {
    library = (nil, body.lists)
  }
  try validateLists(library.lists)
  return AccountWorkspace(accountId: body.accountId, revision: body.revision,
                          document: WorkspaceDocument(lists: library.lists, devices: try decodeDevices(body.devices ?? []), packs: library.packs))
}

/// The input of a save (`saveWorkspace`): the whole document, for the revision it was changed from. The packs go
/// with the lists, so that the backend keeps them; without them it would put each list in a pack of its own.
public func encodeAccountWorkspace(_ workspace: AccountWorkspace) throws -> Data {
  try validateLists(workspace.document.lists)
  _ = try decodeDevices(workspace.document.devices)
  var lists = workspace.document.lists
  var packs = workspace.document.packs
  if let saved = packs {
    (packs, lists) = libraryToSave(packs: saved, lists: lists)
  }
  let encoder = JSONEncoder()
  encoder.outputFormatting = [.withoutEscapingSlashes]
  let data = try encoder.encode(AccountWorkspaceBody(lists: lists, packs: packs, devices: workspace.document.devices,
                                                     revision: workspace.revision, accountId: workspace.accountId))
  // The server reads at most 1 MiB.
  if data.count > maxWorkspaceBytes { throw TypleError("workspaceTooLarge") }
  return data
}

/// An error the backend answered a GraphQL field with: its key and the status its REST path would have, which come in
/// the error's `extensions`. An error it did not name, such as a query it does not know, has neither.
public struct GraphQLFailure: Error, Equatable {
  public var key: String?
  public var status: Int

  public init(key: String?, status: Int) {
    self.key = key
    self.status = status
  }
}

private let workspaceFields = "lists packs devices revision accountId"

/// The request that reads the account's workspace.
public func workspaceRequest() throws -> Data {
  try graphQLRequest("query Workspace { workspace { \(workspaceFields) } }", input: nil)
}

/// The request that saves a workspace. Its answer is read with `field` "saveWorkspace".
public func saveWorkspaceRequest(_ workspace: AccountWorkspace) throws -> Data {
  let query = "mutation SaveWorkspace($input: SaveWorkspaceInput!) { saveWorkspace(input: $input) { \(workspaceFields) } }"
  return try graphQLRequest(query, input: try encodeAccountWorkspace(workspace))
}

/// The input is put in as it is, so that what is saved is exactly what `encodeAccountWorkspace` wrote.
private func graphQLRequest(_ query: String, input: Data?) throws -> Data {
  var request = Data(#"{"query":"#.utf8)
  request.append(try JSONEncoder().encode(query))
  if let input {
    request.append(Data(#","variables":{"input":"#.utf8))
    request.append(input)
    request.append(Data("}".utf8))
  }
  request.append(Data("}".utf8))
  return request
}

private struct GraphQLAnswer: Decodable {
  struct Failure: Decodable {
    struct Extensions: Decodable {
      var code: String?
      var status: Int?
    }
    var extensions: Extensions?
  }
  var data: [String: AccountWorkspaceBody?]?
  var errors: [Failure]?
}

/// Reads the answer of a workspace request: the workspace in `field`, or a `GraphQLFailure`.
public func decodeWorkspaceAnswer(_ data: Data, field: String) throws -> AccountWorkspace {
  let answer: GraphQLAnswer
  do { answer = try JSONDecoder().decode(GraphQLAnswer.self, from: data) } catch { throw TypleError("invalidServerData") }
  if let failure = answer.errors?.first {
    throw GraphQLFailure(key: failure.extensions?.code, status: failure.extensions?.status ?? 0)
  }
  guard let body = answer.data?[field] ?? nil else { throw TypleError("invalidServerData") }
  return try accountWorkspace(from: body)
}
