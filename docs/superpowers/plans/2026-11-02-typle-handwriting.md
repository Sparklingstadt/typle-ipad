# Typle Handwriting（iPad・Mac）実装計画

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** typle-r v2.10.0 の Typle Handwriting（`display` を手で書き写すモード）を iPad・Mac のアプリに入れる。

**Architecture:** 照合と時計の規則は typle-r の `src/core/writing.ts` を `TypleCore/Sources/TypleCore/Writing.swift` に写し、typle-r の fixture（`tests/fixtures/writing/match.json`）の写しで確かめる。データ（リストの印 `writing`・記録の `mode`）と集計（モードごとのベスト）は TypleCore、画面（キャンバス・Vision・OS の手書き入力の欄・切り替え）は `Shared/`。iPad と Mac で違うのは練習欄（`iPad/`・`Mac/` の `PracticeTextField`）だけ。

**Tech Stack:** Swift 5、SwiftUI（`Canvas`・`DragGesture`・`ImageRenderer`）、Vision（`VNRecognizeTextRequest`）、XCTest、Node.js（`tests/`）。

**Spec:** typle-r `docs/superpowers/specs/2026-11-02-typle-writing-design.md`（節「思い出して打つモードとの統合」が優先）

## Global Constraints

- 記録の `mode` は「ない（通常）」「`recall`」「`writing`」の3つだけ。`"mode": null` とほかの値は読み込みで拒否する（`savedDataCorrupted`）。Handwriting は思い出すモードと組み合わせない（このアプリには思い出すモードの練習画面はない）。
- リストの印は `writing: { language }` だけを持つ。言語は `en`・`ja`・`zh-Hans`・`zh-Hant`・`ko`・`fr`・`de`・`es`・`ru`・`cs`。ほかのキーや言語は拒否する。
- 正確率 =（単語数 − 飛ばした数）÷（単語数 ＋ 一致しなかった回数）。コードは `sessionResult` の（`attempts` − `mistakes`）÷ `attempts`。
- 表示名は「Handwriting」「Typle Handwriting」をどの言語でも英語のまま。識別子は `writing`。
- Vision：`recognitionLevel = .accurate`、`recognitionLanguages = [リストの言語]`、`usesLanguageCorrection = false`、各行の `topCandidates(5)`、`customWords` は使わない。複数行なら各行の最上位を行の順につないだものも候補にする。認識はメインスレッドの外で行い、新しい線を書いたら前の結果は捨てる。
- 黙って認識するのは手を止めて 0.8 秒後。一致しなければ何もしない。ミスは「判定」（Return）と「飛ばす」だけで数える。
- `PKCanvasView` は使わない（Mac で動かない）。
- 文言は `Shared/Resources/ja.lproj`・`en.lproj` の両方に同じキーで入れる。「iPad」「タップ」を含む文言は `Mac/Resources/*/Mac.strings` にも。
- アカウントへの保存は今のとおり `PUT /api/workspace`（全体）。Go の `decodeRecord` は `writing` を受け付ける（typle-r v2.10.0）。
- 版は `project.yml` の `MARKETING_VERSION` を 0.63.0 にする。typle-r 本番が v2.10.0 になってから公開する。

## Review Focus

1. **飛ばした語と認識の食い違い**：0.8 秒の黙った認識が走っている間に「飛ばす」「判定」「消す」を押す → 古い認識結果が次の語に効いてはいけない。Task 5 のテスト `testStaleRecognitionIsDropped` で、語の番号と線の版（`generation`）が変わった結果を捨てることを確かめる。
2. **IME の変換中の照合**：OS の手書き入力の欄で中国語・日本語の変換中に照合・判定しない。Task 6 で `onCommit` は確定した文字だけを渡す今の練習欄を使い、`onReturn` は変換中に呼ばない（手で確かめる項目に入れる）。
3. **印のないリストに Handwriting が残る**：Handwriting を選んだまま印のないリストへ切り替える → タイピングになる。Task 4 のテスト `testUnmarkedListIsTyped`。
4. **空の判定**：何も書かずに Return → ミスにしない。Task 1 のテスト `testEmptyCheckIsNotAMistake`。
5. **`"mode": null` の保存データ**：アカウントや端末内のデータに `null` があっても黙って消して保存し直さない。Task 2 のテスト `testNullModeIsRefused`。

---

### Task 1: 照合と時計の規則（`Writing.swift`）

**Files:**
- Modify: `TypleCore/Sources/TypleCore/Typing.swift`（`TypingSession` に `pausedAt`・`missed`、`pauseSession`・`resumeSession`・`elapsedTime`、`TypingOptions`・`latinBase`・`cyrillicAlternatives`・`matchesCharacter`）
- Create: `TypleCore/Sources/TypleCore/Writing.swift`
- Create: `TypleCore/Tests/TypleCoreTests/Fixtures/writing/match.json`（typle-r の写し、そのまま）
- Modify: `TypleCore/Package.swift`（testTarget に `resources: [.copy("Fixtures")]`）
- Create: `TypleCore/Tests/TypleCoreTests/WritingTests.swift`
- Modify: `tests/strings.test.cjs`（`TYPLE_R` があるとき、写しが typle-r の `tests/fixtures/writing/match.json` とバイト単位で同じか確かめる。カタログの確認と同じ形）

**Interfaces:**
- Produces:
  - `public enum WritingLanguage: String, Codable, CaseIterable, Sendable { case en, ja, zhHans = "zh-Hans", zhHant = "zh-Hant", ko, fr, de, es, ru, cs }`（Models.swift に置いてもよいが Task 2 と同じ名前）
  - `public struct TypingOptions: Equatable, Sendable { var ignoreAccents = false; var ignoreCase = false }`
  - `TypingSession.pausedAt: Double?`、`TypingSession.missed: Bool`
  - `public func pauseSession(_: TypingSession, now: Double) -> TypingSession`、`resumeSession(_:now:)`、`elapsedTime(_:now:) -> Double`（typing.ts と同じ規則）
  - `public func normalizeWriting(_ text: String, language: WritingLanguage) -> String`
  - `public func matchesWriting(_ candidates: [String], target: String, language: WritingLanguage, options: TypingOptions = .init()) -> Bool`
  - `public func startWriting(_: TypingSession, now: Double) -> TypingSession`
  - `public func judgeWriting(_: TypingSession, words: [Word], candidates: [String], now: Double, language: WritingLanguage, options: TypingOptions, explicit: Bool) -> TypingSession`
  - `public func skipWord(_: TypingSession, words: [Word], now: Double) -> TypingSession`

- [ ] **Step 1: テストを書く。** `WritingTests` は `Bundle.module` から `Fixtures/writing/match.json` を読み、各ケースで `matchesWriting(c.candidates, target: c.target, language: c.language, options: c.options) == c.expected`（失敗時は `description` を出す）。ほかに typle-r の `tests/writing.test.cjs` と同じ値のテスト：`normalizeWriting("  a   b ", .en) == "a b"`、`("あ　い う", .ja) == "あいう"`、`("한 국", .ko) == "한 국"`；正解で `index 1・attempts 1・mistakes 0・startedAt 1000`；最後の語で `finishedAt 2000` になり、終わった後の `judgeWriting`・`skipWord`・`startWriting` は同じ値を返す；明示の不一致で `attempts 1・mistakes 1・missed true`、続く黙った正解の判定で `missed false`；黙った不一致は変えない；`testEmptyCheckIsNotAMistake`（候補 `[]`・`[""]`・`["  "]` で明示でも変えない）；`skipWord` は `mistakes+1`・次へ・最後で終わる；`startWriting` は `pausedAt` から再開すると `startedAt` を止まっていた分だけ進める。
- [ ] **Step 2: 失敗を確かめる。** `cd TypleCore && swift test --filter WritingTests` → コンパイルエラー。
- [ ] **Step 3: 実装する。** typing.ts・writing.ts を1行ずつ写す。文字は `Array.from` と同じくコードポイント（`unicodeScalars`）で数え、比較は `String` の `==` ではなくスカラーの並びで行う（NFC にそろえた後なので結果は同じ）。`toLowerCase` は `lowercased()`。`latinBase` は NFD（`decomposedStringWithCanonicalMapping`）から `generalCategory` が mark のスカラーを除き、残りが1スカラーで Latin の範囲（`A–Z`・`a–z`・`ª`・`º`・`U+00C0–U+024F` から `×`・`÷` を除く・`U+0250–U+02AF`・`U+1D00–U+1D7F`・`U+1E00–U+1EFF`・`U+2C60–U+2C7F`・`U+A720–U+A7FF`・`U+AB30–U+AB6F`・`U+FF21–U+FF3A`・`U+FF41–U+FF5A`）なら返す。`TypingSession` に足す項目はタイピングの `typeInput` では使わない（今の挙動は変えない）。
- [ ] **Step 4: 通ることを確かめる。** `swift test` 全体と `TYPLE_R=../typle-r node --test tests/` が通る。
- [ ] **Step 5: コミット。**

### Task 2: リストの印と記録の `mode` を読み書きする

**Files:**
- Modify: `TypleCore/Sources/TypleCore/Models.swift`、`WordLists.swift`
- Test: `TypleCore/Tests/TypleCoreTests/TypleCoreTests.swift`

**Interfaces:**
- Consumes: `WritingLanguage`（Task 1）
- Produces:
  - `public struct WritingMark: Codable, Hashable, Sendable { public var language: WritingLanguage }`。`init(from:)` はキーが `language` ちょうど1つで、知っている言語のときだけ通る（ほかは `DecodingError`）。
  - `WordList.writing: WritingMark?`（ないときは保存で省く。`init` に `writing: WritingMark? = nil`）
  - `StoredRecord` の `init(from:)` を手で書き、`mode` のキーがあって `null` なら `DecodingError`。`mode` は `String?` のまま。
  - `validateLists` は `mode` が `nil`・`"recall"`・`"writing"` 以外なら `savedDataCorrupted`。
  - `duplicateList` は `writing` を写す（listOverview.ts の複製と同じ）。`saveList` は編集画面の `writing` をそのまま保存する。

- [ ] **Step 1: テストを書く。** `testWritingMarkRoundTrips`（`{"writing":{"language":"zh-Hans"}}` を読んで書くと同じ。印のないリストを書くと `writing` のキーが出ない）；`testWritingMarkRefusesExtraKeysAndUnknownLanguages`（`{"language":"xx"}`・`{"language":"en","x":1}`・`{}` は `decodeWorkspaceFile` が `savedDataUnreadable`）；`testWritingModeRoundTrips`（`mode: "writing"` が残る）；`testNullModeIsRefused`（`"mode": null` は `savedDataUnreadable`）；`testUnknownModeIsRefused`（`"mode":"x"` は `savedDataCorrupted`）；`testDuplicateKeepsWritingMark`；`testSaveListKeepsWritingMark`。
- [ ] **Step 2: 失敗を確かめる。** `swift test --filter TypleCoreTests`
- [ ] **Step 3: 実装する。**
- [ ] **Step 4: 通ることを確かめる。** `swift test`
- [ ] **Step 5: コミット。**

### Task 3: モードごとの記録とベスト・集計

**Files:**
- Modify: `TypleCore/Sources/TypleCore/Records.swift`、`Rankings.swift`、`WordLists.swift`（`currentRecordCount`）、`Dashboard.swift`（今の `normalRecords` を `recordsOfMode(_, .normal)` に）
- Test: `TypleCore/Tests/TypleCoreTests/TypleCoreTests.swift`、`DashboardTests.swift`

**Interfaces:**
- Produces:
  - `public enum PracticeMode: String, CaseIterable, Sendable { case normal, recall, writing }`
  - `public func recordMode(_: StoredRecord) -> PracticeMode`、`recordsOfMode(_: [StoredRecord], _: PracticeMode) -> [StoredRecord]`（`normalRecords` は消して置き換える）
  - `makeRecord(_:wordCount:id:device:mode: PracticeMode = .normal)`（`.normal` なら `mode` は nil）
  - `comparableRecords(_ list:, _ records: = nil, mode: PracticeMode = .normal)`、`listBest(_:mode: = .normal)`
  - `RecordRow.mode: PracticeMode`。`best` は自分のモードの中で1位のとき
  - `listRanking(_:device:order:includeOthers:now:mode: PracticeMode = .normal)`
  - `currentRecordCount` は通常の記録だけ（records.ts と同じ）

- [ ] **Step 1: テストを書く。** `testBestsAreKeptPerMode`（通常・recall・writing を1件ずつ持つリストで `listBest(list, mode:)` がそれぞれ自分のモードの記録、`recordRows` で3件とも `best == true`）；`testRankingOfWriting`（`listRanking(list, mode: .writing).ranked` が writing だけ）；`testMakeRecordWritesWritingMode`（`.writing` で `mode == "writing"`、`.normal` で nil）；`testCurrentRecordCountIsNormalOnly`；ダッシュボード：writing の記録は `weekCount`・`streak`・`weekSeconds` に入り、`accuracy`・`nextLists`・`listTrends` には入らない（今の recall のテストと同じ形）。
- [ ] **Step 2: 失敗を確かめる。**
- [ ] **Step 3: 実装する。** 呼び出し側（`Shared/`）は既定の `.normal` のままコンパイルが通る。`normalRecords` を使う画面は `recordsOfMode(_, .normal)` に直す。
- [ ] **Step 4: 通ることを確かめる。** `swift test` と両スキームのビルド。
- [ ] **Step 5: コミット。**

### Task 4: 練習のモードの選択と Handwriting の練習の状態

**Files:**
- Create: `Shared/Practice/WritingChoice.swift`
- Modify: `Shared/Practice/PracticeModel.swift`

**Interfaces:**
- Consumes: Task 1 の `judgeWriting`・`skipWord`・`pauseSession`・`resumeSession`、Task 3 の `makeRecord(mode:)`
- Produces:
  - `enum WritingMethod: String { case canvas, system }`（「画面に書く」「OS の手書き入力」）
  - `@Observable final class WritingChoice`：`var writing: Bool`（UserDefaults `writingMode`。`writing` のときだけ書き、タイピングで消す。Web の `typle-r:writing-mode` と同じ）、`var method: WritingMethod`（UserDefaults `writingMethod`、既定 `.canvas`）、`func mode(for list: WordList?) -> PracticeMode`（印がなければ `.normal`）
  - `PracticeModel.mode: PracticeMode`（`restart(listId:mode:)` で決まり、その回の間は変わらない）
  - `PracticeModel.judge(_ candidates: [String], list: WordList, explicit: Bool, device:, app:)`、`skip(list:device:app:)`、`pause()`、`resume()`、`lastRead: String?`（不一致で出す「〇〇と読めました」の文字。`nil` は読み取れなかった）
  - 終わると `makeRecord(..., mode: mode)` で保存（今の `save` を使う）。練習中に印が外されても、その回は `mode` のまま最後まで続け保存する。

- [ ] **Step 1: テストを書く。** アプリにはユニットテストのターゲットがないため、規則は TypleCore のテスト（Task 1）で守り、ここでは `WritingChoice.mode(for:)` を純粋な関数 `practiceMode(_ list: WordList?, writing: Bool) -> PracticeMode` として TypleCore の `Writing.swift` に置き、`testUnmarkedListIsTyped`（印なし＋writing → `.normal`、印あり＋writing → `.writing`、印あり＋タイピング → `.normal`）を書く。
- [ ] **Step 2: 失敗を確かめる。**
- [ ] **Step 3: 実装する。**
- [ ] **Step 4: 通ることを確かめる。** `swift test` と両スキームのビルド。
- [ ] **Step 5: コミット。**

### Task 5: 手書きのキャンバスと Vision の認識

**Files:**
- Create: `Shared/Practice/WritingCanvas.swift`（線を集めて描く SwiftUI のビュー）
- Create: `Shared/Practice/WritingRecognizer.swift`（Vision）
- Modify: `TypleCore/Sources/TypleCore/Writing.swift`（候補の組み立て）
- Create: `scripts/recognize-samples.swift`（手で回す見本の確認）

**Interfaces:**
- Produces:
  - `struct WritingStroke: Equatable { var points: [CGPoint] }`、`WritingCanvas(strokes: Binding<[WritingStroke]>, onStrokeEnd: () -> Void)`：`Canvas` で描き、`DragGesture(minimumDistance: 0)` で線を足す。横長の1行（高さ 200pt）、書く高さの目安の破線を1本。筆圧は `DragGesture` から取れないので一定の太さ（4pt）。
  - `func renderStrokes(_: [WritingStroke], size: CGSize) -> CGImage?`（`ImageRenderer`、白地に黒、`scale` 2）
  - TypleCore：`public func writingCandidates(_ lines: [[String]]) -> [String]`（各行の候補を順に並べ、行が2つ以上なら各行の最上位を行の順につないだもの（言語に関係なく区切りなしと空白区切りの2つ）も足す。重複は除く）
  - `actor WritingRecognizer`：`static func supports(_ language: WritingLanguage) -> Bool`（`VNRecognizeTextRequest().supportedRecognitionLanguages()` に入るか。`.accurate`）、`func recognize(_ image: CGImage, language: WritingLanguage) async -> [String]`（Global Constraints の設定、エラーは `[]`）
  - 古い結果を捨てる：`PracticeModel` が線の版 `strokeGeneration: Int` と語の番号を持ち、認識を始めたときの2つが結果の時点で変わっていれば捨てる。

- [ ] **Step 1: テストを書く。** TypleCore に `testWritingCandidatesJoinsLines`（`[["I am", "l am"], ["a student."]]` → `["I am", "l am", "a student.", "I ama student.", "I am a student."]`）と `testStaleRecognitionIsDropped` 相当の純粋な関数 `public func isCurrentRecognition(startedAt: (index: Int, generation: Int), now: (index: Int, generation: Int)) -> Bool` のテスト。
- [ ] **Step 2: 失敗を確かめる。**
- [ ] **Step 3: 実装する。** `scripts/recognize-samples.swift` は macOS で `swift scripts/recognize-samples.swift` と回し、言語ごとに数語（`en`: apple・I am a student.、`ja`: 練習、`zh-Hans`: 爱护、`ko`: 한국、`ru`: привет、`de`: Straße）を手書き風のフォント（`Bradley Hand`、なければシステム）で画像にして Vision に通し、候補に正解が入るかを表で出す。合否で失敗にしない（仕様のとおり精度は自動の合格条件にしない）。
- [ ] **Step 4: 通ることを確かめる。** `swift test`、両スキームのビルド、`swift scripts/recognize-samples.swift` の表を PR に貼る。
- [ ] **Step 5: コミット。**

### Task 6: 練習画面の Handwriting

**Files:**
- Create: `Shared/Practice/WritingPracticeView.swift`（1語の見本・キャンバスか入力欄・ボタン・読めた文字）
- Modify: `Shared/Practice/PracticeView.swift`（切り替え、確認、モードで見本の画面を変える、一時停止）
- Modify: `iPad/Practice/PracticeTextField.swift`・`Mac/Practice/PracticeTextField.swift`（`onReturn: (() -> Void)? = nil`、`language: String? = nil` を足す。iPad は `onReturn` があれば `textFieldShouldReturn` から変換中でないときに呼び、`textInputMode` を `UITextInputMode.activeInputModes` のうち `primaryLanguage` が言語で始まるものにする。Mac は `insertNewline:` を `control(_:textView:doCommandBy:)` で受けて変換中でないときに呼ぶ）
- Modify: `Shared/Resources/*/Localizable.strings`

**Interfaces:**
- Consumes: Task 4 の `WritingChoice`・`PracticeModel` の Handwriting の操作、Task 5 の `WritingCanvas`・`WritingRecognizer`
- Produces: 画面だけ

- [ ] **Step 1: 画面を作る。**
  - 見出しの下に、印のあるリストのときだけ `SegmentedPills`「タイピング／Handwriting」（`practice.mode.typing`・`practice.mode.writing`）。Handwriting では「画面に書く／OS の手書き入力」（`practice.writing.canvas`・`practice.writing.system`）。リストの言語を `WritingRecognizer.supports` が受け付けなければ「画面に書く」を押せなくし、`practice.writing.unsupported`（「この端末はこの言語の手書きを読み取れません。OS の手書き入力を使ってください」）を出して `.system` にする。
  - 練習中にモードを切り替えるときは、リストの切り替えと同じ確認（`practice.switch.*` と同じ見た目、文言は `practice.modeSwitch.description`）。
  - 語の見本：`display` を大きく、下に `annotation`（タイピングと同じ大きさの規則 `wordSize`）。
  - キャンバス：下に「1画戻す」「消す」「判定」（Return、⌘ なし）「飛ばす」。線を書き終えて 0.8 秒たつと黙って認識し `judge(explicit: false)`。「判定」は認識を待ってから `judge(explicit: true)`。正解で線を消す。
  - OS の手書き入力：`PracticeTextField(text:placeholder: "practice.writing.input", ..., onReturn:, language:)`。`onCommit` のたびに `judge([value], explicit: false)`、正解で欄を空に。`onReturn` で `judge([value], explicit: true)`（文字は残す）。
  - 不一致の後は `practice.writing.read`（「「%@」と読めました」）、候補が空なら `practice.writing.unreadable`（「読み取れませんでした」）。
  - 一時停止：`scenePhase` が `.active` でなくなったら `pause()`、戻ったら次の線・入力で `startWriting` が再開する。OS の手書き入力では欄のフォーカスが外れたら `pause()`。
  - ライブ指標・次の単語・すべての単語はタイピングと同じ部品を使う。
  - DEBUG の `-TypleWriting <文字>` で、OS の手書き入力に打ったのと同じ判定をする（シミュレーターのスクリーンショット用。今の `-TypleTyping` と同じ形）。
- [ ] **Step 2: 両スキームをビルドする。**
- [ ] **Step 3: シミュレーター（iPad）と Mac で動かす。** 印を付けたリストで、OS の手書き入力に正解を入れて進む・違う文字で Return してミス・飛ばすでミス・最後に結果画面と記録、キャンバスに指（マウス）で書いて認識されること。
- [ ] **Step 4: コミット。**

### Task 7: 結果・ベスト・練習記録をモードで分ける

**Files:**
- Modify: `Shared/Practice/PracticeResultView.swift`（比べるのは同じモードの記録。Handwriting なら見出しに「Handwriting」の印）
- Modify: `Shared/Practice/PracticeView.swift`（横のベストを今のモードで）、`Shared/Practice/PracticeParts.swift`（選択肢のベストは `listBest(list, mode: choice.mode(for: list))`）
- Modify: `Shared/Records/RankingsView.swift`（`SegmentedPills`「通常／思い出す／Handwriting」をいつも出し、`listRanking(..., mode:)` に渡す）、`Shared/AppModel.swift`（`rankingsMode: PracticeMode`。結果画面の「すべてのベスト」からはその回のモードで開く）
- Modify: `Shared/Records/RecordsView.swift`（`row.mode == .writing` で「Handwriting」の印。recall の印と同じ見た目）
- Modify: `Shared/Resources/*/Localizable.strings`（`rankings.mode.label`・`.normal`・`.recall`・`.writing`、`records.writingBadge`）

**Interfaces:**
- Consumes: Task 3 の `PracticeMode`・`listBest(_:mode:)`・`listRanking(...mode:)`・`RecordRow.mode`

- [ ] **Step 1: 画面を直す。**
- [ ] **Step 2: 両スキームをビルドし、デモデータ（`-TypleDemo YES`）に writing の記録を1件足して（`Shared/Support/DemoData.swift`）ベスト記録・練習記録を見る。**
- [ ] **Step 3: コミット。**

### Task 8: リストの編集の印

**Files:**
- Modify: `Shared/Lists/ListEditorView.swift`、`Shared/Resources/*/Localizable.strings`

- [ ] **Step 1: 画面を作る。** 名前のカードの下に `Toggle`「手書き練習（Typle Handwriting）に使う」（`wordLists.editor.writingToggle`）と説明（`writingToggleHelp`）、オンのとき `Picker`「認識する言語」（`writingLanguage`）。言語の名前は Web と同じ（English・日本語・中文（简体）・中文（繁體）・한국어・Français・Deutsch・Español・Русский・Čeština、どちらの表示言語でも同じ）。オンにしたときの初期値は表示言語に対応する言語（`ja` → `ja`、ほかは `en`）。保存で `WordList.writing` に入れ、変更の判定（`changed`）にも含める。公式パックのリストは今と同じく編集できない。
- [ ] **Step 2: 両スキームをビルドし、印を付けて保存・開き直して残ることを確かめる。**
- [ ] **Step 3: コミット。**

### Task 9: 文書・版・確認・PR

**Files:**
- Modify: `README.md`（画面の表に Handwriting、練習の節に2つの手段と Vision、範囲外にスマホ・筆圧）、`project.yml`（`MARKETING_VERSION: "0.63.0"`）

- [ ] **Step 1: 文書と版を直す。**
- [ ] **Step 2: すべての確認を回す。** `cd TypleCore && swift test`、`TYPLE_R=../typle-r node --test tests/`、`xcodegen generate`、`xcodebuild ... -scheme TypleiPad -destination 'generic/platform=iOS Simulator' build`、`xcodebuild ... -scheme TypleMac build`。
- [ ] **Step 3: シミュレーターで Task 6 の流れをもう一度通し、スクリーンショットを残す。**
- [ ] **Step 4: typle-r の本番（`https://typle-r-six.vercel.app`）が v2.10.0 であることを確かめる。**
- [ ] **Step 5: PR を出す。** タイトルは日本語の1文に `(v0.63.0)`。説明に確認の結果、`recognize-samples` の表、実機（Apple Pencil・指・トラックパッド）で確かめていないことを書く。
