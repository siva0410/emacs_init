;;    +---------------------------------------------+
;;    |                Package Install              |
;;    +---------------------------------------------+
(require 'package)
;; (add-to-list 'package-archives '("org"   . "https://orgmode.org/elpa/"))
;; (add-to-list 'package-archives '("melpa" . "https://melpa.org/packages/"))
;; (add-to-list 'package-archives '("gnu"   . "https://elpa.gnu.org/packages/"))
;; (package-initialize)

(setq package-archives
      '(("gnu" . "http://elpa.gnu.org/packages/")
    ("melpa" . "http://melpa.org/packages/")
    ("org" . "http://orgmode.org/elpa/")))

(unless package-archive-contents
  (package-refresh-contents))

(when (not (package-installed-p 'use-package))
  (package-install 'use-package))
(require 'use-package)
(setq use-package-always-ensure t)

;; Kill Ring
(use-package browse-kill-ring
  :bind (
         ("C-x y" . browse-kill-ring)
         )
  )

;; Ansi-Color
(use-package compile
  :ensure nil
  :hook
  (compilation-filter . my/colorize-compilation-buffer)
  :config
  (require 'ansi-color)

  (defun my/colorize-compilation-buffer ()
    (ansi-color-apply-on-region compilation-filter-start (point))))

(use-package vertico
  :custom
  (vertico-scroll-margin 0) ;; Different scroll margin
  (vertico-count 15) ;; Show more candidates
  (vertico-resize nil) ;; Grow and shrink the Vertico minibuffer
  (vertico-cycle t) ;; Enable cycling for `vertico-next/previous'
  :init
  (vertico-mode))

(use-package savehist
  :init
  (savehist-mode))

(use-package orderless
  :custom
  ;; Configure a custom style dispatcher (see the Consult wiki)
  ;; (orderless-style-dispatchers '(+orderless-consult-dispatch orderless-affix-dispatch))
  ;; (orderless-component-separator #'orderless-escapable-split-on-space)
  (completion-styles '(orderless basic))
  (completion-category-defaults nil)
  (completion-category-overrides '((file (styles partial-completion)))))

(use-package consult
  :bind (
         ("C-s" . consult-line)
         ("C-x b" . consult-buffer)
	 ("M-g" . consult-goto-line)
         )
  )

(use-package marginalia
  ;; Bind `marginalia-cycle' locally in the minibuffer.  To make the binding
  ;; available in the *Completions* buffer, add it to the
  ;; `completion-list-mode-map'.
  :bind (:map minibuffer-local-map
         ("M-A" . marginalia-cycle))

  ;; The :init section is always executed.
  :init

  ;; Marginalia must be activated in the :init section of use-package such that
  ;; the mode gets enabled right away. Note that this forces loading the
  ;; package.
  (marginalia-mode))

(use-package corfu
  :bind (
         :map corfu-map
         ;; ("TAB" . corfu-insert)
         ;; ("<tab>" . corfu-insert)
         ("RET" . nil)
         ;; ("<return>" . nil)
	 )
  
  ;; Optional customizations
  :custom
  (corfu-auto t)
  (corfu-auto-delay 0)
  (corfu-auto-prefix 2)
  (corfu-cycle t)                ;; Enable cycling for `corfu-next/previous'
  ;; (corfu-quit-at-boundary nil)   ;; Never quit at completion boundary
  ;; (corfu-quit-no-match nil)      ;; Never quit, even if there is no match
  ;; (corfu-preview-current nil)    ;; Disable current candidate preview
  ;; (corfu-preselect 'prompt)      ;; Preselect the prompt
  (corfu-preselect 'first)      ;; Preselect the prompt
  (corfu-on-exact-match nil)     ;; Configure handling of exact matches
  (tab-always-indent 'complete)
  
  ;; Enable Corfu only for certain modes. See also `global-corfu-modes'.
  ;; :hook ((prog-mode . corfu-mode)
  ;;        (shell-mode . corfu-mode)
  ;;        (eshell-mode . corfu-mode))
  
  :init
  ;; Recommended: Enable Corfu globally.  Recommended since many modes provide
  ;; Capfs and Dabbrev can be used globally (M-/).  See also the customization
  ;; variable `global-corfu-modes' to exclude certain modes.
  (global-corfu-mode)
  ;; Enable auto completion and configure quitting
  ;; Enable optional extension modes:
  ;; (corfu-history-mode)
  ;; (corfu-popupinfo-mode)
  )

(use-package cape
  :init
  (add-to-list 'completion-at-point-functions #'cape-dabbrev)
  (add-to-list 'completion-at-point-functions #'cape-file)
  )

;; Projctile
(use-package projectile
  :custom (projectile-project-root-files '(".project" ".git" "compile_commands.json"))
  :hook (prog-mode . projectile-mode)
  :bind ("C-c p" . projectile-command-map)
  )

;; magit
(use-package magit
  :bind ("C-x g" . magit-status)
  )

;; vterm
(use-package vterm
  :bind (
	 ("M-[" . vterm)
	 )
  :config
  (setq vterm-keymap-exceptions '("<f1>" "M-[" "M-]" "C-c" "C-x" "C-u" "C-g" "C-l" "C-t" "M-x" "M-o" "C-v" "M-v" "C-y" "M-y"))
  (setq vterm-max-scrollback 10000)
  (setq vterm-buffer-name-string "vterm: %s")
  (define-key vterm-mode-map (kbd "C-t") 'other-window-or-split)
  )

;;    +---------------------------------------------+
;;    |                  Key Config                 |
;;    +---------------------------------------------+
;; (define-key vterm-mode-map (kbd "C-t") 'other-window-or-split)
;; ;;(define-key dired-mode-map (kbd "f8") 'toggle-frame-fullscreen)

;;; Theme
(use-package doom-themes
  :custom
  (doom-themes-enable-italic t)
  (doom-themes-enable-bold t)
  :custom-face
  (doom-modeline-bar ((t (:background "#6272a4"))))
  :config
  (doom-themes-neotree-config)
  (doom-themes-org-config))

(use-package all-the-icons
  :if (display-graphic-p)
  ;; :init (all-the-icons-install-fonts t)
  )

(use-package doom-modeline
  :custom
  (doom-modeline-buffer-file-name-style 'truncate-with-project)
  (doom-modeline-icon t)
  (doom-modeline-major-mode-icon nil)
  (doom-modeline-minor-modes nil)
  :hook
  (after-init . doom-modeline-mode)
  :config
  (line-number-mode t)
  (column-number-mode t)
  ;; (display-battery-mode t)
  (setq display-time-24hr-format t)
  (display-time-mode t)
  )

(use-package rainbow-delimiters
  :hook (prog-mode . rainbow-delimiters-mode))

;;    +---------------------------------------------+
;;    |                System Config                |
;;    +---------------------------------------------+

(use-package arduino-mode
  :mode ("\\.ino\\'" . arduino-mode))

;;; LSP
(use-package eglot
  :ensure nil
  :hook ((python-mode . eglot-ensure)
         (c-mode . eglot-ensure)
         (c++-mode . eglot-ensure)
	 (arduino-mode . eglot-ensure)
         ;; (go-mode . eglot-ensure)
         ;; (rust-mode . eglot-ensure)
         )
  :config
  (add-to-list 'eglot-server-programs
               '(python-mode . ("pyright-langserver" "--stdio")))
  (add-to-list 'eglot-server-programs
               '((c-mode c++-mode arduino-mode) . ("clangd")))
  )

;; (with-eval-after-load 'eglot
;;   (add-to-list 'eglot-server-programs
;;                '(python-mode . ("pyright-langserver" "--stdio"))))

;; (use-package treesit-auto
;; :hook (
;; 	 (c++-mode-hook . tree-sitter-hl-mode)
;; 	 )
;;   :config
;;   (setq treesit-auto-install t)
;;   (global-treesit-auto-mode)
;;   (setq treesit-font-lock-level 4))

;; (use-package org-modern
;;   :hook (org-mode . org-modern-mode))

(use-package markdown-mode
  :mode ("\\.md\\'" . markdown-mode)
  :custom
  (markdown-command "pandoc"))

(use-package ox-gfm
  :config
  (defalias 'org-md-export-to-markdown 'org-gfm-export-to-markdown)
  (defalias 'org-md-export-as-markdown 'org-gfm-export-as-markdown))

(use-package emacs
  :init
  (add-to-list 'default-frame-alist '(fullboth . maximized)) ; or fullboth
  ;; (add-to-list 'default-frame-alist
  ;;              '(alpha 1 1)))
  
  (setq inhibit-startup-message t)
  (setq frame-title-format "%f")
  (global-display-line-numbers-mode t)
  (tool-bar-mode 0)
  (menu-bar-mode 0)  
  
  (setq custom-file (expand-file-name "custom.el" user-emacs-directory))
  (when (file-exists-p custom-file)
    (load custom-file))

  (setq make-backup-files nil)
  (setq auto-save-default nil)
  (setq ring-bell-function 'ignore)
  (defalias 'yes-or-no-p 'y-or-n-p)
  
  ;; scratch buffer
  (setq initial-scratch-message nil)
  
  :bind (
	 ("C-h" . delete-backward-char)
         ("C-t" . other-window-or-split)
         ("C-;" . comment-dwim)
         ("C-x C-d" . dired-jump)
	 ("C-a" . my-smart-beginning-of-line)
	 ("C-e" . my-smart-end-of-line)
	 )
  :config
  (load-theme 'doom-dracula t)
  )

(defvar my-smart-jump-state nil
  "Stores state for smart beginning/end of line navigation.")

(defun my-smart-beginning-of-line ()
  "Toggle between beginning of line, beginning of buffer, and original point."
  (interactive)
  (cond
   ;; 1回目: 行頭へ移動し、元の位置を保存
   ((not (eq last-command 'my-smart-beginning-of-line))
    (setq my-smart-jump-state (list :origin (point) :step 1))
    (move-beginning-of-line 1))
   ;; 2回目: バッファ先頭へ
   ((= (plist-get my-smart-jump-state :step) 1)
    (plist-put my-smart-jump-state :step 2)
    (goto-char (point-min)))
   ;; 3回目: 元の位置へ戻る
   (t
    (goto-char (plist-get my-smart-jump-state :origin))
    (setq this-command nil)))) ; 状態リセット

(defun my-smart-end-of-line ()
  "Toggle between end of line, end of buffer, and original point."
  (interactive)
  (cond
   ((not (eq last-command 'my-smart-end-of-line))
    (setq my-smart-jump-state (list :origin (point) :step 1))
    (move-end-of-line 1))
   ((= (plist-get my-smart-jump-state :step) 1)
    (plist-put my-smart-jump-state :step 2)
    (goto-char (point-max)))
   (t
    (goto-char (plist-get my-smart-jump-state :origin))
    (setq this-command nil))))

(defun other-window-or-split ()
  (interactive)
  (when (one-window-p)
    (split-window-horizontally))
  (other-window 1))


;;    +---------------------------------------------+
;;    |                Language Config              |
;;    +---------------------------------------------+
(set-face-attribute 'default nil
                    :family "DejaVu Sans Mono"
                    :height 160)

;; カラー絵文字。
(set-fontset-font t 'emoji
                  (font-spec :family "Noto Color Emoji") nil 'prepend)

;; Nerd Fontが使う私用領域のアイコン。
(dolist (range '((#xe000 . #xf8ff)
                 (#xf0000 . #xffffd)
                 (#x100000 . #x10fffd)))
  (set-fontset-font t range
                    (font-spec :family "Symbols Nerd Font Mono")
                    nil 'prepend))

(use-package ddskk
  :ensure t
  :init
  (setq default-input-method "japanese-skk")
  :config
  ;; 個人辞書
  (global-set-key (kbd "C-x j") 'toggle-input-method)
  (setq skk-jisyo "~/.skk-jisyo")
  ;; DDSKK標準のカーソル色変更機能を使う
  (setq skk-use-color-cursor t)
  (setq skk-cursor-latin-color "lightskyblue")
  (setq skk-cursor-hiragana-color "lightpink")
  (setq skk-cursor-katakana-color "lightgreen")
  ;; 変換候補をインライン表示
  (setq skk-show-inline t)
  ;; 句読点
  (setq skk-kutouten-type 'jp)
  (setq skk-rom-kana-rule-list
        (append
         '(("!" nil "!")
           ("?" nil "?")
           (":" nil ":")
           (";" nil ";")
           ("(" nil "(")
           (")" nil ")")
           ("[" nil "[")
           ("]" nil "]")
           ("{" nil "{")
           ("}" nil "}")
           ("'" nil "'")
           ("\"" nil "\""))
         skk-rom-kana-rule-list)))

(use-package org
  :ensure nil

  :preface
  ;; PlantUMLだけBabel実行時の確認を省略する。
  ;; ShellやPythonなど、ほかの言語では確認を残す。
  (defun my-org-confirm-babel-evaluate (lang _body)
    (not (string= lang "plantuml")))

  ;; Babel実行後、Org内の画像を再表示する。
  (defun my-org-redisplay-inline-images (&rest _)
    (when (derived-mode-p 'org-mode)
      (org-redisplay-inline-images)))

  :custom
  (org-plantuml-jar-path "/usr/share/plantuml/plantuml.jar")
  (org-plantuml-exec-mode 'jar)
  (org-confirm-babel-evaluate
   #'my-org-confirm-babel-evaluate)
  (org-startup-with-inline-images t)
  ;; C-c ' ではOrgと同じウィンドウにソース編集バッファを開く。
  (org-src-window-setup 'current-window)

  :config
  ;; Org BabelでPlantUMLを有効化する。
  (org-babel-do-load-languages
   'org-babel-load-languages
   '((plantuml . t)))

  ;; 設定を再評価してもadviceを重複登録しない。
  (unless
      (advice-member-p
       #'my-org-redisplay-inline-images
       #'org-babel-execute-src-block)
    (advice-add
     #'org-babel-execute-src-block
     :after
     #'my-org-redisplay-inline-images)))


(use-package plantuml-mode
  :ensure t
  :after org

  :preface
  ;; plantuml-mode 1.7.0 は、新しいCAPFを定義している一方で、
  ;; major mode初期化時に古い対話コマンドを誤登録している。
  ;; Corfuの自動補完から古いコマンドが繰り返し呼ばれると、
  ;; *Completions* が開き、削除した文字まで再挿入されるため修正する。
  (defun my-plantuml-fix-completion-at-point-function ()
    (setq-local completion-at-point-functions
                '(plantuml-completion-at-point-function)))

  :hook
  (plantuml-mode . my-plantuml-fix-completion-at-point-function)

  :mode
  (("\\.puml\\'"     . plantuml-mode)
   ("\\.plantuml\\'" . plantuml-mode))

  :custom
  (plantuml-jar-path "/usr/share/plantuml/plantuml.jar")
  (plantuml-default-exec-mode 'jar)
  (plantuml-output-type "svg")

  :config
  ;; C-c C-c のPlantUMLプレビューだけを右側に表示する。
  (add-to-list
   'display-buffer-alist
   '("\\`\\*PLANTUML Preview\\*\\'"
     (display-buffer-reuse-window display-buffer-in-direction)
     (direction . right)
     (window-width . 0.5)))

  ;; OrgのPlantUMLブロックを C-c ' で開いたとき、
  ;; plantuml-modeを使用する。
  (add-to-list
   'org-src-lang-modes
   '("plantuml" . plantuml)))

;;    +---------------------------------------------+
;;    |                Agetn Config                 |
;;    +---------------------------------------------+
(use-package agent-shell
  :ensure t

  :preface
  (define-prefix-command 'my-agent-shell-command-map)

  ;; shell-makerの履歴にUTF-8の日本語がunibyte文字列として保存された場合、
  ;; M-pや履歴検索で正しく表示できるmultibyte文字列へ戻す。
  (defun my-agent-shell-normalize-history (&rest _)
    (when (and (boundp 'comint-input-ring)
               (ring-p comint-input-ring))
      (let ((normalized-ring (make-ring (ring-size comint-input-ring))))
        (dolist (item (reverse (ring-elements comint-input-ring)))
          (let ((plain-item (substring-no-properties item)))
            (ring-insert
             normalized-ring
             (if (multibyte-string-p plain-item)
                 plain-item
               (decode-coding-string plain-item 'utf-8)))))
        (setq comint-input-ring normalized-ring))))

  (defun my-agent-shell-enable-skk-for-codex ()
    "Codexの入力欄をDDSKKのかなモードで開始する。"
    (when (eq (map-nested-elt
               agent-shell--state '(:agent-config :identifier))
              'codex)
      (skk-mode 1)))

  :hook
  (agent-shell-mode . my-agent-shell-enable-skk-for-codex)

  :bind
  (("C-c a" . my-agent-shell-command-map)
   :map my-agent-shell-command-map
   ("x" . agent-shell-openai-start-codex)
   ("c" . agent-shell-anthropic-start-claude-code))

  :custom
  ;; 大きな画像付きヘッダーを表示しない。
  ;; Codex名やモデル名は通常のモードライン側に表示される。
  (agent-shell-header-style nil)
  ;; 起動時のASCIIアートとウェルカムメッセージを表示しない。
  (agent-shell-show-welcome-message nil)
  ;; 使用フォントにないUnicode文字を使う処理中アニメーションを隠す。
  (agent-shell-show-busy-indicator nil)
  ;; 起動時に選択範囲やカーソル行などをプロンプトへ自動挿入しない。
  (agent-shell-context-sources nil)
  ;; 起動時に全ての履歴を表示する。
  :custom
  (agent-shell-session-restore-verbosity 'full)

  :config
  ;; 読み込み後に既存履歴を修復し、保存前にも同じ形式へ統一する。
  (unless (advice-member-p
           #'my-agent-shell-normalize-history
           #'shell-maker--read-input-ring-history)
    (advice-add #'shell-maker--read-input-ring-history
                :after #'my-agent-shell-normalize-history))
  (unless (advice-member-p
           #'my-agent-shell-normalize-history
           #'shell-maker--write-input-ring-history)
    (advice-add #'shell-maker--write-input-ring-history
                :before #'my-agent-shell-normalize-history)))
