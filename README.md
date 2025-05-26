# 初回にやること
## レポジトリのクローン
* `rm -rf ~/.emacs.d`
* `git clone git@github.com/siva0410/emacs_init.git ~/.emacs.d`

## vtermのインストール
* `sudo apt install cmake libvterm-dev`

## pandocのインストール
* `sudo apt install pandoc`

## フォントのインストール
* `mkdir ~/.local/share/fonts/monaspace`
* `cd ~/.local/share/fonts/monaspace`
* `wget https://github.com/githubnext/monaspace/releases/download/v1.200/monaspace-v1.200.zip`
* `unzip monaspace-v1.200.zip`
* `fc-cache -fv`
* `fc-list | grep monaspace` (確認)

## 特殊フォントのインストール
* `M-x all-the-icons-install-fonts`
* `M-x nerd-icons-install-fonts`
