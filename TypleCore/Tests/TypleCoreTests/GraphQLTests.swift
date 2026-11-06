import Foundation
import XCTest
@testable import TypleCore

final class GraphQLTests: XCTestCase {
  private let workspace = #"{"lists":[{"id":"x","name":"X","createdAt":"2026-01-01","words":[{"display":"a","input":"a","annotation":""}],"records":[]}],"packs":null,"devices":[],"revision":4,"accountId":"github:1"}"#

  func testReadsTheWorkspaceInItsField() throws {
    let answer = #"{"data":{"workspace":\#(workspace)}}"#
    let read = try decodeWorkspaceAnswer(Data(answer.utf8), field: "workspace")
    XCTAssertEqual(read.accountId, "github:1")
    XCTAssertEqual(read.revision, 4)
    XCTAssertEqual(read.document.lists.map(\.id), ["x"])
  }

  func testAnErrorIsItsKeyAndStatus() {
    let answer = #"{"errors":[{"message":"conflict","path":["saveWorkspace"],"extensions":{"code":"conflict","status":409}}],"data":null}"#
    XCTAssertThrowsError(try decodeWorkspaceAnswer(Data(answer.utf8), field: "saveWorkspace")) { error in
      XCTAssertEqual(error as? GraphQLFailure, GraphQLFailure(key: "conflict", status: 409))
    }
  }

  func testAnErrorTheBackendDidNotNameHasNoKey() {
    let answer = #"{"errors":[{"message":"Cannot query field"}],"data":null}"#
    XCTAssertThrowsError(try decodeWorkspaceAnswer(Data(answer.utf8), field: "workspace")) { error in
      XCTAssertEqual(error as? GraphQLFailure, GraphQLFailure(key: nil, status: 0))
    }
  }

  func testAnAnswerWithoutTheWorkspaceIsInvalid() {
    for answer in [#"{"data":null}"#, #"{"data":{"workspace":null}}"#, #"{"data":{"other":\#(workspace)}}"#, "[]"] {
      XCTAssertThrowsError(try decodeWorkspaceAnswer(Data(answer.utf8), field: "workspace")) { error in
        XCTAssertEqual((error as? TypleError)?.key, "invalidServerData", answer)
      }
    }
  }

  func testTheReadAsksForEveryField() throws {
    let request = try JSONSerialization.jsonObject(with: try workspaceRequest()) as! [String: Any]
    XCTAssertEqual(request["query"] as? String, "query Workspace { workspace { lists packs devices revision accountId } }")
    XCTAssertNil(request["variables"])
  }

  func testASaveSendsTheBodyAsItsInput() throws {
    let read = try decodeAccountWorkspace(Data(workspace.utf8))
    let body = try encodeAccountWorkspace(read)
    let request = try saveWorkspaceRequest(read)
    let sent = String(decoding: request, as: UTF8.self)
    XCTAssertTrue(sent.hasSuffix(#","variables":{"input":\#(String(decoding: body, as: UTF8.self))}}"#), sent)
    let object = try JSONSerialization.jsonObject(with: request) as! [String: Any]
    XCTAssertTrue((object["query"] as! String).hasPrefix("mutation SaveWorkspace($input: SaveWorkspaceInput!)"))
    let input = (object["variables"] as! [String: Any])["input"] as! [String: Any]
    XCTAssertEqual(input["revision"] as? Int, 4)
    XCTAssertEqual(input["accountId"] as? String, "github:1")
    // Left out, not null: the backend refuses null, and keeps what it has for a field left out.
    XCTAssertNil(input["packs"])
    XCTAssertNil(input["interests"])
  }
}
