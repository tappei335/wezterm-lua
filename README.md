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
- `lua/wezterm_config/theme.lua`
  - tab bar、status bar、cursor、selection で共有する配色です。
- `lua/wezterm_config/fonts.lua`
  - フォントサイズや行高など、共通の文字表示設定です。
- `lua/wezterm_config/keys.lua`
  - Leader key と pane/tab 操作のショートカットです。
- `lua/wezterm_config/workspaces.lua`
  - workspace や launch menu を増やすための拡張ポイントです。
- `lua/wezterm_config/ssh.lua`
  - `~/.ssh/config` の Host を SSH / SSHMUX domain として登録し、host selector と launch menu に追加します。
- `lua/wezterm_config/status.lua`
  - workspace、pane の現在地、process、domain、時刻などを status bar に表示します。
- `lua/wezterm_config/system_metrics.lua`
  - CPU / memory / disk 使用率の取得と cache をまとめます。remote SSH / SSHMUX pane では `user vars` で受け取った remote metrics を優先し、なければローカルメトリクスを出しません。
- `lua/wezterm_config/system_metrics_windows.ps1`
  - Windows で PowerShell 経由の system metrics をまとめて取得する helper です。
- `scripts/wezterm-remote-metrics.sh`
  - remote host の shell から `OSC 1337 SetUserVar` を送り、SSH / SSHMUX pane 用の remote metrics を status bar に渡します。
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

## Font

英数字は `JetBrains Mono Medium`、日本語は `BIZ UDGothic`、Nerd Font 記号は `Symbols Nerd Font Mono` を優先して表示します。日本語 fallback には `Noto Sans JP` も入れています。

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
| `Ctrl-a Shift-s` | SSH host selector を開き、選んだ host を新しい tab で開く |
| `Ctrl-a Shift-m` | SSHMUX host selector を開き、選んだ host の remote mux に attach |
| `Ctrl-a Shift-d` | 現在の domain から detach |
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

## SSH domain

`~/.ssh/config` に登録されている literal な `Host` を `SSH:*` domain として自動登録します。`Ctrl-a Shift-s` で host を選ぶと、その SSH domain に新しい tab を開きます。

SSH domain の tab に入った後は、既存の split / tab 操作が `CurrentPaneDomain` を使うため、同じ SSH 先に pane や tab を増やせます。

| 操作 | SSH domain 内での動き |
| --- | --- |
| `Ctrl-a c` / `Ctrl-Shift-t` | 同じ SSH 先に新しい tab を作成 |
| `Ctrl-a h` / `Ctrl-t` | 同じ SSH 先に左右 split を作成 |
| `Ctrl-a -` / `Ctrl-g` / `Ctrl-¥` | 同じ SSH 先に上下 split を作成 |

plain SSH domain を使うため、remote 側に WezTerm をインストールしなくても使えます。`assume_shell = 'Posix'` を設定しているため、Linux host では shell integration が有効なら remote の現在ディレクトリを pane / tab 作成時に引き継ぎやすくなります。

より tmux に近い remote session の永続化が必要な場合は、`Ctrl-a Shift-m` で WezTerm が自動生成する `SSHMUX:*` domain に attach します。remote 側にも互換バージョンの WezTerm が必要ですが、detach しても remote の panes/tabs を残せます。

| 操作 | SSHMUX domain 内での動き |
| --- | --- |
| `Ctrl-a Shift-m` | SSHMUX host を選んで remote mux に attach |
| `Ctrl-a Shift-d` | 現在の domain から detach。対応 domain では remote panes/tabs を残したまま切断 |
| `Ctrl-a c` / split 系 | attach した remote mux 側に新しい tab / pane を作成 |

## Status bar

- 左側
  - `WS`: 現在の workspace
  - `MODE`: leader / pane 移動 / pane resize などの一時 mode
- 右側
  - `CPU`: local pane の CPU 使用率
  - `MEM`: local pane の memory 使用率
  - `DSK`: active pane の current directory がある local filesystem の disk 使用率
  - `DIR`: active pane の現在ディレクトリ
  - `PROC`: active pane の foreground process
  - `DOM`: active pane の domain
  - `TIME`: 現在時刻

`SSH:*` / `SSHMUX:*` domain では、`scripts/wezterm-remote-metrics.sh` などから `WEZTERM_REMOTE_CPU` / `WEZTERM_REMOTE_MEM` / `WEZTERM_REMOTE_DSK` / `WEZTERM_REMOTE_TS` が届いていればその数値を表示します。20 秒以上更新が止まった場合は stale とみなして `CPU` / `MEM` / `DSK` を隠します。

### Remote metrics

plain SSH domain でも remote host の `CPU` / `MEM` / `DSK` を出したい場合は、remote 側の shell から `user vars` を送る必要があります。WezTerm の `pane:get_foreground_process_info()` などの local introspection は SSH 先には効かないためです。

このリポジトリには source 用の helper として `scripts/wezterm-remote-metrics.sh` を入れています。remote host に置いて、`.bashrc` または `.zshrc` から source してください。

この helper は prompt ごとに `OSC 1337` を出すので、WezTerm 以外の端末から同じ host をよく使う場合は、自分の shell rc 側で source 条件を分ける方が安全です。

```bash
mkdir -p ~/.config/wezterm
scp /path/to/wezterm-lua/scripts/wezterm-remote-metrics.sh your-host:~/.config/wezterm/
printf '\n. "$HOME/.config/wezterm/wezterm-remote-metrics.sh"\n' >> ~/.bashrc
```

挙動:

- prompt 表示時に remote の `CPU` / `MEM` / `DSK` を収集して `OSC 1337 SetUserVar` で pane に送ります
- `SSH:*` と `SSHMUX:*` のどちらでも使えます
- `tmux` の中から通す場合は remote 側 `tmux.conf` に `set -g allow-passthrough on` が必要です
- 更新頻度は `WEZTERM_REMOTE_METRICS_INTERVAL` で秒単位に変更できます。既定は `8` 秒です

status bar を常に確認できるように、tab が 1 つだけの時も tab bar を表示します。

## 次に足しやすいもの

- project ごとの launch menu
- host ごとの差分設定
