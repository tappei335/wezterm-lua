# wezterm-lua

WezTerm を快適に使うための Lua 設定を育てていくための土台です。

## 構成

- `.wezterm.lua`
  - エントリポイント。`lua/` を module path に追加して設定を読み込みます。
- `lua/wezterm_config/init.lua`
  - 設定モジュールを束ねて `config` を組み立てます。
- `lua/wezterm_config/options.lua`
  - 基本動作やタブ、スクロールバックなどの共通設定です。
- `lua/wezterm_config/appearance.lua`
  - 余白やカーソルなど、共通の見た目です。
- `lua/wezterm_config/fonts.lua`
  - フォントサイズや行高など、共通の文字表示設定です。
- `lua/wezterm_config/keys.lua`
  - Leader key と pane/tab 操作のショートカットです。
- `lua/wezterm_config/workspaces.lua`
  - workspace や launch menu を増やすための拡張ポイントです。
- `lua/wezterm_config/platform.lua`
  - 実行環境を判定して、OS ごとの設定モジュールを選びます。
- `lua/wezterm_config/platforms/*.lua`
  - `windows` / `macos` / `linux` ごとの差分設定です。

## 使い始め

1. このリポジトリを WezTerm の config directory として配置する
2. `lua/wezterm_config/fonts.lua` のフォント設定を自分の環境に合わせる
3. `lua/wezterm_config/keys.lua` に普段使うショートカットを足す

## HOME に配置するスクリプト

- Linux
  - `bash scripts/install-linux.sh`
- macOS
  - `bash scripts/install-macos.sh`
- Windows
  - `powershell -ExecutionPolicy Bypass -File .\scripts\install-windows.ps1`

各スクリプトは `HOME` に `.wezterm.lua` を配置し、`lua/` を `HOME/lua` に丸ごとコピーします。既存の `HOME/lua` は置き換えられるため、WezTerm 用以外の Lua を同じ場所で管理している場合は分離を検討してください。

## 環境ごとの差分

- 共通設定は `lua/wezterm_config/*.lua` に置きます
- OS ごとの差分は `lua/wezterm_config/platforms/` に置きます
- 現在は `wezterm.target_triple` を元に `windows` / `macos` / `linux` を自動判定します
- Windows では `pwsh.exe -NoLogo`、IME 有効、`Kanagawa (Gogh)`、`Shift+Enter` 系の送信設定を適用しています

## 追加済みショートカット

- `Ctrl-a =`
  - pane の幅を均等化します。きれいな列レイアウトならタブ全体、複雑な分割ではアクティブ pane と同じ行だけを対象にします。

## 次に足しやすいもの

- workspace / domain / SSH 接続
- status bar や tab title のイベント
- project ごとの launch menu
- host ごとの差分設定
