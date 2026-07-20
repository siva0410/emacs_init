# Emacs configuration

Ubuntu on WSL2 用の個人 Emacs 設定です。補完、Git 操作、組み込みターミナル、
日本語入力、PlantUML、LSP、AI コーディングエージェントを一つの設定にまとめています。

## 動作確認環境

- Ubuntu 22.04.5 LTS on WSL2
- GNU Emacs 29.3

Emacs 29 以上を前提とします。`eglot` は Emacs 同梱版を利用します。
Ubuntu 22.04 の標準リポジトリにある Emacs 27 では、この構成を再現できません。
先に Emacs 29 以上を用意し、`emacs --version` で確認してください。

## セットアップ

### 1. OS パッケージをインストールする

```sh
sudo apt update
sudo apt install -y \
  git \
  build-essential cmake libtool-bin libvterm-dev \
  pandoc plantuml graphviz default-jre \
  fonts-dejavu-core fonts-noto-color-emoji
```

各パッケージの用途は次のとおりです。

| パッケージ | 用途 |
| --- | --- |
| `build-essential`, `cmake`, `libtool-bin`, `libvterm-dev` | Emacs の `vterm` モジュールをビルド |
| `pandoc` | Markdown の変換・プレビュー |
| `plantuml`, `default-jre`, `graphviz` | PlantUML と Org Babel の図を生成 |
| `fonts-dejavu-core` | 既定の等幅フォント |
| `fonts-noto-color-emoji` | カラー絵文字 |

### 2. 既存の設定を退避してクローンする

次の操作は既存の `~/.emacs.d` を上書きしません。ディレクトリがある場合は、
先に名前を変えて退避します。

```sh
mv ~/.emacs.d ~/.emacs.d.backup
git clone --branch wsl --single-branch \
  https://github.com/siva0410/emacs_init.git ~/.emacs.d
```

`~/.emacs.d` が存在しない場合、`mv` は省略してください。SSH 鍵を設定済みなら、
clone URL を `git@github.com:siva0410/emacs_init.git` に置き換えられます。

### 3. Emacs を初回起動する

```sh
emacs
```

初回起動時に `use-package` が GNU ELPA/MELPA から Emacs パッケージを取得します。
取得後に Emacs を再起動します。初めて `M-x vterm` を実行したときにネイティブ
モジュールのビルド確認が表示された場合は、`y` で許可してください。

### 4. アイコンフォントをインストールする

GUI 版 Emacs で次をそれぞれ実行し、Emacs を再起動します。

```text
M-x all-the-icons-install-fonts
M-x nerd-icons-install-fonts
```

`nerd-icons-install-fonts` で導入される `Symbols Nerd Font Mono` は、
本文中の Nerd Font アイコンにも使用します。

## 機能別の追加セットアップ

### LSP

C/C++/Arduino では `clangd`、Python では `pyright-langserver` を使用します。
利用する言語のサーバーだけを導入してください。

```sh
# C/C++/Arduino
sudo apt install -y clangd

# Python（Node.js と npm の導入後）
npm install --global pyright
```

対象ファイルを開くと Eglot が自動起動します。サーバーを入れていない言語では、
起動エラーが表示されますが、ほかの機能には影響しません。

### AI エージェント

`agent-shell` から利用する CLI をインストールし、各 CLI で認証を済ませます。

- Codex CLI: `codex`
- Claude Code: `claude`

どちらも任意です。未導入の CLI に対応する agent-shell コマンドだけが利用できません。

## 主な機能

| 分類 | パッケージ・機能 |
| --- | --- |
| ミニバッファ補完 | Vertico, Orderless, Consult, Marginalia |
| 入力補完 | Corfu, Cape |
| プロジェクト/Git | Projectile, Magit |
| ターミナル | vterm |
| 表示 | Doom Themes, Doom Modeline, Rainbow Delimiters |
| 日本語入力 | DDSKK |
| 文書・図 | Markdown mode, ox-gfm, Org Babel, PlantUML |
| LSP | Eglot (`clangd`, `pyright-langserver`) |
| AI | agent-shell (Codex CLI, Claude Code) |

## 主なキーバインド

| キー | 動作 |
| --- | --- |
| `C-s` | バッファ内検索 (`consult-line`) |
| `C-x b` | バッファ選択 (`consult-buffer`) |
| `M-g` | 指定行へ移動 (`consult-goto-line`) |
| `C-x g` | Magit status |
| `C-c p` | Projectile コマンド |
| `M-[` | vterm を開く |
| `C-x j` | DDSKK の切り替え |
| `C-c a x` | Codex を agent-shell で開く |
| `C-c a c` | Claude Code を agent-shell で開く |
| `C-t` | 次のウィンドウへ移動（1画面なら左右分割） |
| `C-a` / `C-e` | 行頭・バッファ先頭 / 行末・バッファ末尾を巡回 |

## PlantUML

`.puml` と `.plantuml` は `plantuml-mode` で開き、既定で SVG を生成します。
Org の `plantuml` ソースブロックも有効です。

```org
#+begin_src plantuml :file example.svg
@startuml
Alice -> Bob: Hello
@enduml
#+end_src
```

ブロック内で `C-c C-c` を実行すると `/usr/share/plantuml/plantuml.jar` を使って
画像を生成し、Org バッファ内に再表示します。

## 構成と更新

Git で管理するファイルは次の3つだけです。

- `init.el`: すべての Emacs 設定
- `README.md`: セットアップと利用方法
- `.gitignore`: 実行時に生成されるファイルを管理対象から除外

`elpa/`, `custom.el`, 履歴、キャッシュなどは初回起動後に生成され、`.gitignore` により
管理対象外になります。更新は次のコマンドで取り込みます。

```sh
git -C ~/.emacs.d pull --ff-only
```

## セットアップ確認

外部依存を確認します。

```sh
emacs --version | head -n 1
pandoc --version | head -n 1
java -version
plantuml -headless -version
dot -V
fc-match "DejaVu Sans Mono"
fc-match "Noto Color Emoji"
fc-match "Symbols Nerd Font Mono"
```

Emacs の再起動後、`M-x list-packages` が開けること、`M-x vterm` が起動すること、
および `M-x plantuml-preview` でプレビューできることを確認してください。

問題を切り分けるときは、`emacs --debug-init` で起動すると初期化エラーの
バックトレースを確認できます。
