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
- `lua/wezterm_config/status.lua`
  - workspace、pane の現在地、process、domain、時刻などを status bar に表示します。
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

## ショートカット

Leader key は `Ctrl-a` です。以下は `lua/wezterm_config/keys.lua` で現在有効になっているショートカットです。

### 通常キー

| ショートカット | 操作 |
| --- | --- |
| `Ctrl-c` | 選択範囲がある時は clipboard に copy、ない時は `Ctrl-z` を送信 |
| `Ctrl-v` | clipboard から paste |
| `Ctrl-Left` / `Ctrl-Down` / `Ctrl-Up` / `Ctrl-Right` | 左 / 下 / 上 / 右の pane へ移動 |
| `Ctrl-Shift-Left` / `Ctrl-Shift-Right` | 前 / 次の tab へ移動 |
| `Ctrl-'` / `Ctrl-t` | pane を左右に分割 |
| `Ctrl-¥` / `Ctrl-g` | pane を上下に分割 |
| `Ctrl-/` / `Ctrl-q` | 現在の pane を確認なしで閉じる |
| `Ctrl-Shift-t` | 新しい tab を作成 |
| `Ctrl-Shift-q` | 現在の tab を確認なしで閉じる |

### Leader キー

| ショートカット | 操作 |
| --- | --- |
| `Ctrl-a Ctrl-a` | shell / アプリケーションへ `Ctrl-a` を送信 |
| `Ctrl-a c` | 新しい tab を作成 |
| `Ctrl-a 1` ... `Ctrl-a 9` | 指定した番号の tab へ移動 |
| `Ctrl-a ;` | 直前の tab へ移動 |
| `Ctrl-a n` / `Ctrl-a p` | 次 / 前の workspace へ移動 |
| `Ctrl-a s` | workspace 一覧を fuzzy 選択 |
| `Ctrl-a w` | workspace 名を入力して作成または移動 |
| `Ctrl-a [` | copy mode を起動 |
| `Ctrl-a Space` | quick select を起動 |
| `Ctrl-a P` | pane selector を表示 |
| `Ctrl-a a` | pane 移動 mode に入る |
| `Ctrl-a r` | pane resize mode に入る |
| `Ctrl-a :` | command palette を開く |
| `Ctrl-a x` | 現在の pane を確認付きで閉じる |
| `Ctrl-a Shift-q` | 現在の tab を確認付きで閉じる |
| `Ctrl-a Shift-r` | 設定を再読み込み |
| `Ctrl-a -` | pane を上下に分割 |
| `Ctrl-a h` | pane を左右に分割。均等な列レイアウトなら列幅を保って追加 |
| `Ctrl-a z` | 現在の pane を zoom / unzoom |
| `Ctrl-a =` / `Ctrl-a Shift-=` | 現在のレイアウトで主となる列群を見つけて、pane の幅を均等化 |

### Pane 移動 Mode

`Ctrl-a a` で入ります。1 回移動すると通常入力に戻ります。

| キー | 操作 |
| --- | --- |
| `h` / `Left` | 左の pane へ移動 |
| `j` / `Down` | 下の pane へ移動 |
| `k` / `Up` | 上の pane へ移動 |
| `l` / `Right` | 右の pane へ移動 |

### Pane Resize Mode

`Ctrl-a r` で入ります。終了キーを押すまで resize mode に留まります。

| キー | 操作 |
| --- | --- |
| `h` / `Left` | pane 境界を左へ 3 cells 調整 |
| `j` / `Down` | pane 境界を下へ 3 cells 調整 |
| `k` / `Up` | pane 境界を上へ 3 cells 調整 |
| `l` / `Right` | pane 境界を右へ 3 cells 調整 |
| `Esc` / `Enter` / `q` / `Ctrl-c` | resize mode を終了 |

## Status bar

- 左側
  - `ws`: 現在の workspace
  - `mode`: leader / pane 移動 / pane resize などの一時 mode
- 右側
  - `dir`: active pane の現在ディレクトリ
  - `proc`: active pane の foreground process
  - `dom`: active pane の domain
  - `time`: 現在時刻

status bar を常に確認できるように、tab が 1 つだけの時も tab bar を表示します。

## 次に足しやすいもの

- project ごとの launch menu
- domain / SSH 接続
- host ごとの差分設定
