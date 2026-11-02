# Typle for iPad and Mac（SwiftUI）

Typle の iPadOS 版と macOS 版です。Web 版（[typle-r](https://github.com/Sparklingstadt/typle-r)）と同じ判定・記録・ベストの規則で、iPad は Magic Keyboard などのハードウェアキーボードでもソフトウェアキーボードでも、Mac は Mac のキーボードで練習できます。設計は `docs/specs/2026-10-20-ipad-app-design.md`・`docs/specs/2026-10-20-ipad-web-look-design.md` にあります。

2つのアプリは同じ SwiftUI のコード（`Shared/`）と共通の規則（`TypleCore/`）を1つのプロジェクトでビルドします。iPad と Mac で違うところは `#if os(macOS)` と、それぞれのフォルダー（`iPad/`・`Mac/`）にあります。

- typle-r v0.90.0 で、typle-r の `ios/` からこのリポジトリに移しました（`ios/` の履歴も引き継いでいます）。コミットの `(Sparklingstadt/typle-r#N)` は typle-r の PR で、それまでのリリースノートは typle-r の README にあります。
- Mac 版は typle-r v0.88.0 から別のリポジトリ（typle-macos、旧 typle-m）で iPad 版の写しを持っていましたが、v0.61.0 でこのリポジトリにまとめ、typle-macos はアーカイブしました。両方の版は同じ番号（`project.yml` の `MARKETING_VERSION`）です。

## 必要なもの

- Xcode 16 以上を入れた Mac
- [XcodeGen](https://github.com/yonaskolb/XcodeGen)（`brew install xcodegen`）
- iPad 版：iPadOS 17 以上の iPad、またはシミュレーター
- Mac 版：macOS 14（Sonoma）以上

## 起動

```sh
xcodegen generate      # project.yml から Typle.xcodeproj を作る（コミットしない）
open Typle.xcodeproj
```

| スキーム | 実行先 | 署名 |
|---|---|---|
| `TypleiPad` | iPad かシミュレーター | 「Signing & Capabilities」の Team を自分のものにします。バンドルIDは `project.yml` の `PRODUCT_BUNDLE_IDENTIFIER` です。ほかのアカウントと重なるときは変えてください |
| `TypleMac` | My Mac（⌘R） | 「Sign to Run Locally」（アドホック署名）なので、Team を選ばなくても起動できます。自分の証明書で署名したいときは Team を選びます |

コマンドでビルドするときは次のとおりです。

```sh
xcodebuild -project Typle.xcodeproj -scheme TypleiPad -destination 'generic/platform=iOS Simulator' build
xcodebuild -project Typle.xcodeproj -scheme TypleMac build
```

Mac 版を配った `Typle-macOS.zip` は Apple の公証（notarization）を受けていません。初回は Finder で `Typle.app` を Control キーを押しながらクリックして「開く」を選びます（macOS 15 以降は、一度開こうとした後で「システム設定」→「プライバシーとセキュリティ」の「このまま開く」）。ターミナルで `xattr -dr com.apple.quarantine /Applications/Typle.app` を実行しても開けます。

## 見た目と操作

Web 版と同じ画面構成・色・部品です。上部バー（ブランド・保存先・ライト／ダーク・アカウント）、幅が 1280pt 以上ならサイドバー、それより狭ければメニューボタンで開くドロワー。色と角丸は typle-r の `src/app/globals.css` の値を `Shared/Design/Theme.swift` に写しています。表示言語（日本語・English）は「一般」でその場で切り替えられます（既定は端末の言語）。

| 画面 | 内容 |
|---|---|
| ホーム | 今週のまとめ（練習回数・連続練習・平均正確率・練習時間）、次に練習するリスト、リスト別の推移 |
| 練習 | リストの切り替え、端末の選択、ライブ指標、やり直し（ボタンと Esc）、表示と入力の色分け、次の単語・すべての単語、結果とベストとの比較、ベスト記録5件 |
| 単語リスト | 検索・並び替え、作成・編集のページ（単語の追加・削除・ドラッグや「…」での並べ替え、入力する文字が空欄なら表示と同じ）、CSV・TSV の取り込み、CSV の書き出し、複製、削除 |
| 練習記録 | 日ごとの一覧、リストと端末での絞り込み、削除 |
| ベスト記録 | リストごとの順位（正確率順・速さ順）、直近5回の平均 |
| 端末 | 練習する端末の選択と使用回数、追加・変更・削除 |
| 一般 | 表示言語、保存先、GitHub のログイン・ログアウト |

- 変換中（日本語・中国語の入力など）の文字は判定せず、確定した文字だけを判定します。自動修正・自動大文字・予測・貼り付け・ドロップは使えません。
- 練習欄は、iPad が UIKit の `UITextField`（`iPad/Practice/PracticeTextField.swift`）、Mac が AppKit の `NSTextField`（`Mac/Practice/PracticeTextField.swift`）です。
- CSV の書き出しは、iPad は共有シート、Mac は保存先を選ぶ画面です。
- ガイド・Typleについては Web 版を開きます。

Mac だけの操作です（`Mac/MacCommands.swift`）。

| 操作 | 内容 |
|---|---|
| ⌘1〜⌘6 | メニューの「移動」から、ホーム・練習する・練習記録・ベスト記録・単語リスト・端末へ |
| ⌘N | リストを作成 |
| ⌘, | 一般（表示言語・保存先・ログイン） |
| 任意のキー | 練習欄の外をクリックした後、練習欄に戻る（Web 版と同じく、そのキーは入力しません） |

Esc（練習のやり直し）・Return（結果画面でもう一度）・⌘Return（単語リストの編集で保存）は両方で使えます。

## 保存先

| 保存先 | 内容 |
|---|---|
| この iPad／この Mac（既定） | アプリの Application Support の `workspace.json`。形は Web 版のブラウザー保存と同じです。読めないファイルは上書きしません |
| アカウント（GitHub） | Web 版の Typle（既定は本番の `https://typle-r-six.vercel.app`）に GitHub でログインし、Web 版と同じアカウントの単語リスト・記録・端末を、Go のバックエンドの `/api/workspace` で読み書きします（iPad は v0.56.0、Mac は v0.60.0 から） |

- 2つのデータは別々で、切り替えてもコピーしません。
- アカウントでも、端末内と同じくすべての操作ができます。変更のたびに、読み込んだときの `revision` を付けてデータ全体を保存します。別の画面で先に保存されていたとき（`409 conflict`）は、最新を読み直して同じ変更をやり直します（3回まで）。
- アカウントの単語パック（typle-r v0.91.0 から）は画面に出しませんが、読み込んだまま保存し、パックごとに単語リストを並べ替えたりしません。フォロー中の公式パックのリストは、サーバーが単語を空で返すため（typle-r v2.1.0 から）、同梱の公式パックのカタログ（`catalog.json`）から単語を戻して練習できるようにし、保存では単語を送りません。公式パックのリストは Web 版と同じく編集・削除できず（一覧に「公式」と出ます）、複製すると自分のリストとして編集できます。アプリで作ったリストは、保存のときにそのリストの名前のパックに入ります。一度も保存していないアカウントは、公式パックをすべてフォローした状態で始まります（Web 版の関心の既定がすべてを選ぶのと同じ）。
- ログインは「一般」の「GitHub でログイン」で、システムのログイン画面（`ASWebAuthenticationSession`。Safari の GitHub のログインを使えます）が開きます。サーバーには `client=ipad`・`client=macos` で始めます。流れは [typle-r の README の「iPad と Mac と Android と Windows のログイン」](https://github.com/Sparklingstadt/typle-r#ipad-と-mac-と-android-と-windows-のログイン) にあります。受け取ったトークンは端末のキーチェーンにだけ保存し、ログインから30日で切れます（延長しません）。切れたら、もう一度ログインしてください。
- ログアウトするとトークンを消して端末内の保存に戻ります。ログインしたまま端末内に切り替え、あとで「アカウントに切り替える」で戻ることもできます。
- サーバーの URL は https だけです。http は `localhost`・`127.0.0.1`・`*.local` に限ります。手元や同じネットワークの Mac で Web 版（typle-r の `npm run dev`）を動かして試すときに使います。GitHub の OAuth App の callback URL がサーバー（`AUTH_URL`）のものである必要があり、開発用ログインはアプリでは使えません。
- Mac 版は App Sandbox の中で動き、使う権限はネットワークへの接続と、自分で選んだファイルの読み書きだけです（`Mac/Typle.entitlements`）。
- v0.55.0 までの「アカウント（API）」（自分で立てる `/api/v1` に GitHub のトークンでつなぐ）はなくなりました。更新後の初回起動で、その設定とトークンを消して端末内の保存に戻ります。

## 構成

| 場所 | 内容 |
|---|---|
| `TypleCore/` | Foundation だけに依存する Swift Package。typle-r の `src/core` の入力判定・記録・ベスト・ランキング・単語リスト・端末・CSV と、公式パックのカタログ（`src/plugins/packs` から作る `catalog.json`）。`swift test` で確認します |
| `Shared/` | 両方のアプリの SwiftUI のコード。`Storage/`（端末内とアカウント、ログイン）、`Practice/`、`Lists/`、`Records/`、`Devices/`、`Resources/`（文言）。Mac で違うところは `#if os(macOS)` と `Support/Platform.swift`（ログインの `client`、保存データの名前など）、`Design/Theme.swift` の「The iPad and the Mac」（入力欄・メニュー・シートの見た目） |
| `iPad/` | iPad 版だけのもの：練習欄（UIKit）とアイコン |
| `Mac/` | Mac 版だけのもの：練習欄（AppKit）、メニューバー・CSV の保存・スクリーンショット（`MacCommands.swift`）、アイコン、entitlements、`Shared/` の文言のうち「iPad」「タップ」を含むものの Mac 版（`Resources/*/Mac.strings`） |
| `TypleUITests/` | iPad のシミュレーターを回してスクリーンショットを撮るだけの UI テスト |
| `project.yml` | XcodeGen の設定（`TypleiPad`・`TypleMac`・`TypleUITests` の3つのターゲット） |
| `tests/` | 文言とプロジェクトの構成の確認（Node.js） |

文字は JavaScript の `Array.from` と同じくコードポイントで数えるため、Web 版と同じ入力が同じミス数・正確率になります。コードのコメントにある `src/…` は typle-r の Web 版のファイルです。

## 確認

```sh
cd TypleCore && swift test        # 共通の規則
node --test tests/                # 文言とプロジェクトの構成
TYPLE_R=../typle-r node --test tests/   # 公式パックのカタログも
```

- CI のワークフローはありません（typle-r v0.70.0 で削除）。`swift test` と、iPad シミュレーター向け・Mac 向けの両方のビルドは Mac の手元で行います。
- `tests/strings.test.cjs` が、使っている文言が日本語・英語の両方にあり、プレースホルダーがそろっているか、「iPad」「タップ」を含む文言すべてに Mac 版があるか、2つのターゲットが `Shared/` とそれぞれの練習欄をビルドするかを確かめます。`TYPLE_R` に typle-r の手元のフォルダーを指定すると、公式パックのカタログ（`catalog.json`）が typle-r の `src/plugins/packs` から作ったものと同じかも確かめます。指定しなければ、このテストは飛ばします。
- サンプルデータ（`-TypleDemo YES`、`Shared/Support/DemoData.swift`）で起動すると、各ページを実データに触れずに表示できます。Mac は Debug ビルドを `-TypleDemo YES -TypleSnapshot <ファイル>` で起動すると、ウインドウを PNG で保存して終わります。アプリは App Sandbox の中で動くため、保存先は `~/Library/Containers/io.github.sparklingstadt.typle/Data/tmp/` の下にします。

## 公式パックを Web 版に合わせる

`TypleCore/Sources/TypleCore/Resources/catalog.json` は、typle-r の `src/plugins/packs`（`commands/manifest.json` の順の各リスト）から作る公式パックのカタログです。Web 版の `officialPacks`・Go の `OfficialPacks` と同じパック・リスト・ID になります。直接書き換えず、typle-r で公式のリストが変わったら作り直し、`TYPLE_R` を指定したテストで同じになったことを確かめます。この端末で使う最初の単語リストも、このカタログのリストです。

```sh
node scripts/catalog.cjs ../typle-r
TYPLE_R=../typle-r node --test tests/
```

## 範囲外

ガイド・Typleについて（Web 版を開きます）、日本語・英語以外の言語、App Store・TestFlight への公開、Mac の公証・自動更新・複数のウインドウ、保存先の間のコピー。
