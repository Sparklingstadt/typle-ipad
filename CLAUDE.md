# typle-ipad

Typle の iPadOS 版（SwiftUI）です。Web 版・サーバーは [typle-r](https://github.com/Sparklingstadt/typle-r) にあります。構成と確認の手順は README.md を読んでください。

- 変更したら `cd TypleCore && swift test`・`node --test tests/` と、iPad シミュレーター向けのビルド（`xcodegen generate` の後に Xcode か `xcodebuild`）を実行します。
- `TypleCore/Sources/TypleCore/Resources` の最初の単語リストは typle-r の `src/plugins/packs` の写しです。直接書き換えず、typle-r から写します（README の「単語リストを Web 版に合わせる」）。
- 文言は `Typle/Resources/ja.lproj/Localizable.strings`・`en.lproj/Localizable.strings` の両方に同じキーで入れます。

## 出力の言語

出力は必ず日本語で行うこと。
