# typle-ipad

Typle の iPadOS 版と macOS 版（SwiftUI）です。2つのアプリは同じコード（`Shared/`・`TypleCore/`）を1つのプロジェクトでビルドします。Web 版・サーバーは [typle-r](https://github.com/Sparklingstadt/typle-r) にあります。構成と確認の手順は README.md を読んでください。

- 変更したら `cd TypleCore && swift test`・`node --test tests/` と、iPad シミュレーター向け（スキーム `TypleiPad`）と Mac 向け（スキーム `TypleMac`）の両方のビルド（`xcodegen generate` の後に Xcode か `xcodebuild`）を実行します。
- iPad と Mac で違うところは `#if os(macOS)`（`Shared/`）か、`iPad/`・`Mac/` に置きます。片方だけを直して、もう片方を壊さないようにします。
- `TypleCore/Sources/TypleCore/Resources/catalog.json`（公式パック）は typle-r の `src/plugins/packs` から `node scripts/catalog.cjs ../typle-r` で作ります。直接書き換えません（README の「公式パックを Web 版に合わせる」）。
- 文言は `Shared/Resources/ja.lproj/Localizable.strings`・`en.lproj/Localizable.strings` の両方に同じキーで入れます。「iPad」「タップ」を含む文言には、`Mac/Resources/*/Mac.strings` に Mac 版も入れます。

## 出力の言語

出力は必ず日本語で行うこと。
