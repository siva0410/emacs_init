;;    +---------------------------------------------+
;;    |                Package Install              |
;;    +---------------------------------------------+
(require 'package)
(require 'cl-lib)
;; (add-to-list 'package-archives '("org"   . "https://orgmode.org/elpa/"))
;; (add-to-list 'package-archives '("melpa" . "https://melpa.org/packages/"))
;; (add-to-list 'package-archives '("gnu"   . "https://elpa.gnu.org/packages/"))
;; (package-initialize)

(setq package-archives
      '(("gnu" . "https://elpa.gnu.org/packages/")
        ("melpa" . "https://melpa.org/packages/")
        ("org" . "https://orgmode.org/elpa/")))

(unless package-archive-contents
  ;; 起動時は保存済みのパッケージ一覧を読み、毎回ネットへ接続しない。
  (package-read-all-archive-contents)
  ;; 初回起動など、ローカルに一覧がない場合だけ取得する。
  (unless package-archive-contents
    (package-refresh-contents)))

(unless (package-installed-p 'use-package)
  (package-install 'use-package))
(require 'use-package)
(setq use-package-always-ensure t)

(defun my/delete-overlays (overlays)
  "OVERLAYSをすべて削除し、nilを返す。"
  (mapc #'delete-overlay overlays)
  nil)

(defun my/advice-add-once (symbol where function)
  "SYMBOLへFUNCTIONをWHERE adviceとして重複なく追加する。"
  (unless (advice-member-p function symbol)
    (advice-add symbol where function)))

(defun my/ddskk-current-state ()
  "現在のDDSKK入力モードを表すシンボルを返す。"
  (when (equal current-input-method "japanese-skk")
    (cond
     ((bound-and-true-p skk-j-mode)
      (if (bound-and-true-p skk-katakana) 'katakana 'hiragana))
     ((bound-and-true-p skk-jisx0208-latin-mode) 'jisx0208-latin)
     ((bound-and-true-p skk-abbrev-mode) 'abbrev)
     (t 'latin))))

(defun my/ddskk-restore-state (state)
  "DDSKKをSTATEで表される入力モードへ切り替える。"
  (pcase state
    ('hiragana (skk-j-mode-on nil))
    ('katakana (skk-j-mode-on t))
    ('jisx0208-latin (skk-jisx0208-latin-mode-on))
    ('abbrev (skk-abbrev-mode-on))
    ('latin (skk-latin-mode-on))))

;; Kill Ring
(use-package browse-kill-ring
  :bind ("C-x y" . browse-kill-ring))

;; Ansi-Color
(use-package compile
  :ensure nil
  :preface
  (defun my/colorize-compilation-buffer ()
    "コンパイル出力に含まれるANSIカラーを反映する。"
    (ansi-color-apply-on-region compilation-filter-start (point)))
  :hook
  (compilation-filter . my/colorize-compilation-buffer)
  :config
  (require 'ansi-color))

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
  :preface
  (defvar-local my/consult-line-match-overlays nil
    "`my-consult-line' が元バッファに表示中の一致候補。")

  (defvar-local my/consult-line-source-window nil
    "`my-consult-line' を開始したウィンドウ。")

  (defvar my/consult-line-query-replace-request nil
    "Consult Lineから置換へ引き継ぐ検索文字列。")

  (defvar my/consult-line-source-input-method nil
    "`my-consult-line' を開始したバッファの入力方式。")

  (defvar my/consult-line-source-skk-state nil
    "`my-consult-line' を開始した時点のDDSKK入力モード。")

  (defvar-keymap my/consult-ripgrep-map
    :doc "`consult-ripgrep' 専用のミニバッファキーマップ。"
    "M-n" #'vertico-next-group
    "M-p" #'vertico-previous-group)

  (defun my/consult-line-inherit-input-method ()
    "元バッファの入力方式とDDSKK入力モードを引き継ぐ。"
    (when my/consult-line-source-input-method
      (activate-input-method my/consult-line-source-input-method)
      (when (equal my/consult-line-source-input-method "japanese-skk")
        (my/ddskk-restore-state my/consult-line-source-skk-state))))

  (defun my/consult-line-delete-match-overlays ()
    "`my-consult-line' が作成した一致候補の表示を消す。"
    (setq my/consult-line-match-overlays
          (my/delete-overlays my/consult-line-match-overlays)))

  (defun my/consult-line-highlight-visible-matches ()
    "Consult Lineの表示範囲内にある一致候補を青く表示する。"
    (my/consult-line-delete-match-overlays)
    (when-let* ((input (minibuffer-contents-no-properties))
                ((not (string-blank-p input)))
                (window my/consult-line-source-window)
                ((window-live-p window)))
      (require 'orderless)
      (pcase-let* ((`(,predicate . ,regexps) (orderless-compile input))
                   (case-fold-search (orderless--ignore-case-p input)))
        (when regexps
          (let (overlays)
            (with-current-buffer (window-buffer window)
              (save-excursion
                (goto-char (window-start window))
                (let ((limit (copy-marker (or (window-end window t)
                                               (point-max)))))
                  (while (< (point) limit)
                    (let* ((beg (line-beginning-position))
                           (end (line-end-position))
                           (line (buffer-substring-no-properties beg end)))
                      (when (and (or (not predicate) (funcall predicate line))
                                 (cl-every (lambda (regexp)
                                             (string-match-p regexp line))
                                           regexps))
                        (dolist (regexp regexps)
                          (let ((start 0))
                            (while (and (< start (length line))
                                        (string-match regexp line start))
                              (let ((match-beg (match-beginning 0))
                                    (match-end (match-end 0)))
                                (when (< match-beg match-end)
                                  (let ((overlay
                                         (make-overlay (+ beg match-beg)
                                                       (+ beg match-end))))
                                    (overlay-put overlay 'face 'lazy-highlight)
                                    (overlay-put overlay 'priority 1)
                                    (overlay-put overlay 'window window)
                                    (push overlay overlays)))
                                (setq start (max (1+ match-beg) match-end)))))))
                      (forward-line 1)))
                  (set-marker limit nil))))
            (setq my/consult-line-match-overlays overlays))))))

  (defun my/consult-line-highlight-setup ()
    "Consult Lineのミニバッファに候補強調処理を設定する。"
    (setq-local my/consult-line-source-window (minibuffer-selected-window))
    (my/consult-line-inherit-input-method)
    ;; 共有されているミニバッファマップを変更しないようコピーする。
    (use-local-map (copy-keymap (current-local-map)))
    (keymap-set (current-local-map) "M-%"
                #'my/consult-line-start-query-replace)
    (my/consult-line-hide-source-cursor)
    ;; Consultのプレビューで移動した後に、表示範囲を強調する。
    (add-hook 'post-command-hook
              #'my/consult-line-highlight-visible-matches t t)
    ;; Consultがプレビュー用カーソルを表示した後、再び非表示にする。
    (add-hook 'post-command-hook
              #'my/consult-line-hide-source-cursor t t)
    (add-hook 'minibuffer-exit-hook
              #'my/consult-line-delete-match-overlays nil t))

  (defun my/consult-line-hide-source-cursor ()
    "Consult Lineの実行中だけ元バッファのカーソルを隠す。"
    (when (window-live-p my/consult-line-source-window)
      (with-current-buffer (window-buffer my/consult-line-source-window)
        (setq-local cursor-in-non-selected-windows nil))))

  (defun my/consult-line-start-query-replace ()
    "Consult Lineの入力を引き継いで `query-replace' へ移る。"
    (interactive)
    (let ((query (minibuffer-contents-no-properties)))
      (when (string-blank-p query)
        (user-error "置換する検索文字列を入力してください"))
      (setq my/consult-line-query-replace-request query)
      (abort-recursive-edit)))

  (defun my-query-replace-read-args
      (prompt &optional initial-from parser setup)
    "PROMPTを使って置換元・置換先・除外語を読み取る。
INITIAL-FROMが非nilなら置換元の入力を省略する。
PARSERは置換元を (検索語 除外語) に変換する関数である。
SETUPは置換元を読むミニバッファの初期化関数である。"
    (require 'replace)
    (let* ((setup (or setup #'deactivate-input-method))
           (from-or-pair
            (or initial-from
                (minibuffer-with-setup-hook setup
                  (query-replace-read-from prompt nil))))
           (raw-from (if (consp from-or-pair)
                         (car from-or-pair)
                       from-or-pair))
           (parsed (if parser
                       (funcall parser raw-from)
                     (list raw-from nil)))
           (from (car parsed))
           (exclude (cadr parsed))
           (to (if (consp from-or-pair)
                   (cdr from-or-pair)
                 (minibuffer-with-setup-hook #'deactivate-input-method
                   (query-replace-read-to from prompt nil)))))
      (when (string-empty-p from)
        (user-error "置換する検索文字列を入力してください"))
      (list from to exclude)))

  (defun my/cyclic-query-replace-match-excluded-p (beg end exclude)
    "BEGからENDの一致がEXCLUDEという文字列の一部なら非nilを返す。"
    (when (and exclude (not (string-empty-p exclude)))
      (save-excursion
        (let ((line-end (line-end-position))
              excluded)
          (goto-char (line-beginning-position))
          (while (and (not excluded)
                      (search-forward exclude line-end t))
            (setq excluded
                  (and (<= (match-beginning 0) beg)
                       (>= (match-end 0) end))))
          excluded))))

  (defun my/cyclic-query-replace-collect-matches
      (from &optional buffers exclude)
    "BUFFERS内でFROMに一致する箇所をマーカーのリストとして返す。
BUFFERSがnilなら現在のバッファだけを検索する。
一致箇所がEXCLUDEの一部なら候補から除外する。"
    (let (matches)
      (dolist (buffer (or buffers (list (current-buffer))))
        (when (buffer-live-p buffer)
          (with-current-buffer buffer
            (save-excursion
              (goto-char (point-min))
              (while (search-forward from nil t)
                (let ((beg (match-beginning 0))
                      (end (match-end 0)))
                  (unless (my/cyclic-query-replace-match-excluded-p
                           beg end exclude)
                    (push (cons (copy-marker beg)
                                (copy-marker end t))
                          matches))))))))
      (nreverse matches)))

  (defun my/cyclic-query-replace-delete-match (match)
    "MATCHが持つマーカーを解放する。"
    (set-marker (car match) nil)
    (set-marker (cdr match) nil))

  (defun my/cyclic-query-replace-show-matches (matches current-index)
    "MATCHESを表示し、CURRENT-INDEXだけをピンクで強調する。"
    (let (overlays)
      (cl-loop for match in matches
               for index from 0
               for buffer = (marker-buffer (car match))
               for beg = (marker-position (car match))
               for end = (marker-position (cdr match))
               when (and (buffer-live-p buffer) beg end)
               do (with-current-buffer buffer
                    (let ((overlay (make-overlay beg end buffer)))
                      (overlay-put overlay 'face
                                   (if (= index current-index)
                                       'query-replace
                                     'lazy-highlight))
                      (overlay-put overlay 'priority
                                   (if (= index current-index) 2 1))
                      (push overlay overlays))))
      overlays))

  (defun my/cyclic-query-replace-goto-match (match)
    "MATCHのバッファと位置を現在のウィンドウに表示する。"
    (let ((buffer (marker-buffer (car match)))
          (position (marker-position (car match))))
      (unless (and (buffer-live-p buffer) position)
        (user-error "置換候補のバッファがなくなりました"))
      (unless (eq buffer (current-buffer))
        (switch-to-buffer buffer))
      (goto-char position)
      (recenter)))

  (defun my/cyclic-query-replace-file-index (matches index direction)
    "MATCHESのINDEXからDIRECTION方向の別ファイルの先頭位置を返す。"
    (let* ((buffers
            (delete-dups
             (mapcar (lambda (match)
                       (marker-buffer (car match)))
                     matches)))
           (current-buffer (marker-buffer (car (nth index matches))))
           (current-buffer-index (cl-position current-buffer buffers))
           (target-buffer
            (nth (mod (+ current-buffer-index direction)
                      (length buffers))
                 buffers)))
      (or (cl-position-if
           (lambda (match)
             (eq (marker-buffer (car match)) target-buffer))
           matches)
          index)))

  (defun my/cyclic-query-replace-add-undo-boundary (buffer)
    "BUFFERが生きていればUndo境界を追加する。"
    (when (buffer-live-p buffer)
      (with-current-buffer buffer
        (undo-boundary))))

  (defun my/cyclic-query-replace-location (match project-root)
    "MATCHの位置をPROJECT-ROOTからの相対名で返す。"
    (when project-root
      (let* ((buffer (marker-buffer (car match)))
             (file (and buffer (buffer-file-name buffer))))
        (if file
            (file-relative-name file project-root)
          (buffer-name buffer)))))

  (defun my/cyclic-query-replace-read-key
      (from to exclude index total location project-p)
    "置換操作の案内を表示し、入力されたキーを返す。"
    (read-key
     (format
      "Replace %s → %s%s  [%d/%d%s]  y:置換  C-n/p:候補%s  !:全置換  q:終了 "
      from to
      (if exclude (format "  除外:%s" exclude) "")
      (1+ index) total
      (if location (format " %s" location) "")
      (if project-p "  M-n/p:ファイル" ""))))

  (defun my/cyclic-query-replace-one (match from to)
    "MATCHのFROMをTOへ置換する。"
    (let ((buffer (marker-buffer (car match)))
          (beg (marker-position (car match)))
          (end (marker-position (cdr match))))
      (when (and (buffer-live-p buffer) beg end)
        (with-current-buffer buffer
          (barf-if-buffer-read-only)
          (goto-char beg)
          (when (search-forward from end t)
            (replace-match to (not (and case-replace case-fold-search)) t)
            t)))))

  (defun my/cyclic-query-replace
      (from to &optional buffers project-root exclude)
    "FROMをTOへ、前後に循環できる対話式操作で置換する。
BUFFERSが指定された場合は複数バッファをまたいで置換する。
PROJECT-ROOTはプロンプトに表示する相対ファイル名の基準にする。
一致箇所がEXCLUDEの一部なら置換候補から除外する。"
    (let* ((origin-buffer (current-buffer))
           (origin (point))
           (buffers (or buffers (list origin-buffer)))
           (case-fold-search
            (if (and case-fold-search search-upper-case)
                (isearch-no-upper-case-p from nil)
              case-fold-search))
           (matches
            (my/cyclic-query-replace-collect-matches from buffers exclude))
           (index (or (cl-position-if
                       (lambda (match)
                         (and (eq (marker-buffer (car match)) origin-buffer)
                              (>= (marker-position (car match)) origin)))
                       matches)
                      (cl-position-if
                       (lambda (match)
                         (eq (marker-buffer (car match)) origin-buffer))
                       matches)
                      0))
           overlays
           done)
      (unless matches
        (user-error "「%s」に一致する箇所はありません" from))
      (mapc #'my/cyclic-query-replace-add-undo-boundary buffers)
      (unwind-protect
          (while (and matches (not done))
            (setq overlays (my/delete-overlays overlays))
            (setq overlays
                  (my/cyclic-query-replace-show-matches matches index))
            (let* ((current-match (nth index matches))
                   (location (my/cyclic-query-replace-location
                              current-match project-root)))
              (my/cyclic-query-replace-goto-match current-match)
              (let ((key (my/cyclic-query-replace-read-key
                          from to exclude index (length matches)
                          location project-root)))
                (cond
                 ((memq key '(?\C-n ?n))
                  (setq index (mod (1+ index) (length matches))))
                 ((memq key '(?\C-p ?^))
                  (setq index (mod (1- index) (length matches))))
                 ((and project-root (eq key ?\M-n))
                  (setq index
                        (my/cyclic-query-replace-file-index
                         matches index 1)))
                 ((and project-root (eq key ?\M-p))
                  (setq index
                        (my/cyclic-query-replace-file-index
                         matches index -1)))
                 ((memq key '(?y ?\s))
                  (let* ((match (nth index matches))
                         (buffer (marker-buffer (car match))))
                    (my/cyclic-query-replace-one match from to)
                    (setq matches (delq match matches))
                    (my/cyclic-query-replace-delete-match match)
                    (my/cyclic-query-replace-add-undo-boundary buffer)
                    (when matches
                      (setq index (mod index (length matches))))))
                 ((eq key ?!)
                  (dolist (match (reverse (copy-sequence matches)))
                    (my/cyclic-query-replace-one match from to))
                  (setq done t)
                  (message "%d件を置換しました" (length matches)))
                 ((memq key '(?q ?\C-g))
                  (setq done t))
                 (t
                  (message "y, C-n, C-p, M-n, M-p, !, q のいずれかを押してください")
                  (sit-for 0.7))))))
        (my/delete-overlays overlays)
        (mapc #'my/cyclic-query-replace-delete-match matches))))

  (defun my-query-replace (&optional from)
    "前後に循環できる対話式置換を実行する。
FROMが指定された場合は検索文字列の入力を省略する。"
    (interactive)
    (pcase-let ((`(,from ,to ,_)
                 (my-query-replace-read-args "Query replace" from)))
      (my/cyclic-query-replace from to)))

  (defun my-consult-line (&optional initial start)
    "`consult-line' を実行し、元バッファの一致候補も強調する。
検索中に `M-%' を押すと、入力を引き継いで置換へ移る。"
    (interactive (list nil (not (not current-prefix-arg))))
    (let ((source-buffer (current-buffer))
          (cursor-local-p (local-variable-p
                           'cursor-in-non-selected-windows))
          (cursor-value cursor-in-non-selected-windows)
          (my/consult-line-source-input-method current-input-method)
          (my/consult-line-source-skk-state
           (my/ddskk-current-state))
          (my/consult-line-query-replace-request nil))
      (unwind-protect
          (condition-case nil
              (progn
                (setq-local cursor-in-non-selected-windows nil)
                (minibuffer-with-setup-hook #'my/consult-line-highlight-setup
                  (consult-line initial start)))
            (quit
             (unless my/consult-line-query-replace-request
               (signal 'quit nil))))
        (when (buffer-live-p source-buffer)
          (with-current-buffer source-buffer
            (if cursor-local-p
                (setq-local cursor-in-non-selected-windows cursor-value)
              (kill-local-variable 'cursor-in-non-selected-windows)))))
      (when my/consult-line-query-replace-request
        (with-current-buffer source-buffer
          (my-query-replace my/consult-line-query-replace-request)))))

  :bind (("C-s" . my-consult-line)
         ("C-r" . my-query-replace)
         ("M-%" . my-query-replace)
         ("C-x b" . consult-buffer)
         ("M-g" . consult-goto-line))
  :config
  (consult-customize consult-ripgrep
                     :keymap my/consult-ripgrep-map))

(use-package marginalia
  :bind (:map minibuffer-local-map
         ("M-A" . marginalia-cycle))
  :init
  (marginalia-mode))

(use-package corfu
  :bind (:map corfu-map
              ("RET" . nil))
  :custom
  (corfu-auto t)
  (corfu-auto-delay 0)
  (corfu-auto-prefix 2)
  (corfu-cycle t)
  (corfu-preselect 'first)
  (corfu-on-exact-match nil)
  (tab-always-indent 'complete)
  :init
  (global-corfu-mode))

(use-package cape
  :init
  (add-to-list 'completion-at-point-functions #'cape-dabbrev)
  (add-to-list 'completion-at-point-functions #'cape-file)
  )

;; Projectile
(use-package projectile
  :preface
  (defun my-projectile-switch-project-in-tabspace ()
    "Projectileで選んだプロジェクトのtabspacesへ移動する。"
    (tabspaces-open-or-create-project-and-workspace
     (expand-file-name default-directory)))

  (defun my-project-query-replace-buffers (from project-root)
    "PROJECT-ROOT内でFROMを含むファイルのバッファを返す。
すでに開いているプロジェクトバッファは、未保存の変更も検索できるよう
候補へ含める。"
    (let* ((source-buffer (current-buffer))
           (open-buffers
            (seq-filter #'buffer-file-name
                        (projectile-project-buffers project-root)))
           (matching-files
            (projectile-files-with-string from project-root))
           (matching-buffers
            (mapcar #'find-file-noselect matching-files)))
      (delete-dups
       (append (when (memq source-buffer open-buffers)
                 (list source-buffer))
               open-buffers
               matching-buffers))))

  (defun my-project-query-replace-separator (input)
    "Consult形式のINPUTにある2つ目の区切り位置を返す。"
    (when (and (string-prefix-p "#" input)
               (string-match "#" input 1))
      (match-beginning 0)))

  (defun my-project-query-replace-parse-input (input)
    "INPUTをConsult形式の検索語と除外語に分ける。
`#SEARCH#!EXCLUDE' 形式だけを特別扱いし、それ以外は通常の検索語とする。"
    (if-let ((separator (my-project-query-replace-separator input)))
        (let* ((search (substring input 1 separator))
               (filter (string-trim (substring input (1+ separator)))))
          (cond
           ((string-empty-p filter)
            (list search nil))
           ((string-prefix-p "!" filter)
            (let ((exclude (substring filter 1)))
              (when (string-empty-p exclude)
                (user-error "除外する文字列を入力してください"))
              (list search exclude)))
           (t
            (user-error
             "置換では #検索語#!除外語 の形式を使用してください"))))
      (list input nil)))

  (defvar-local my-project-query-replace-input-overlays nil
    "プロジェクト置換の入力構文を色付けするオーバーレイ。")

  (defun my-project-query-replace-clear-input-highlights ()
    "プロジェクト置換の入力欄から構文の色付けを消す。"
    (setq my-project-query-replace-input-overlays
          (my/delete-overlays my-project-query-replace-input-overlays)))

  (defun my-project-query-replace-highlight-input ()
    "`#検索語#!除外語' の区切り記号をConsultと同じ色で表示する。"
    (my-project-query-replace-clear-input-highlights)
    (let* ((beg (minibuffer-prompt-end))
           (input (buffer-substring-no-properties beg (point-max)))
           (separator (my-project-query-replace-separator input)))
      (when (string-prefix-p "#" input)
        (let ((positions (list 0)))
          (when separator
            (push separator positions)
            (when (and (< (1+ separator) (length input))
                       (eq (aref input (1+ separator)) ?!))
              (push (1+ separator) positions)))
          (dolist (position positions)
            (let ((overlay (make-overlay (+ beg position)
                                         (+ beg position 1))))
              (overlay-put overlay 'face 'consult-async-split)
              (overlay-put overlay 'evaporate t)
              (push overlay my-project-query-replace-input-overlays)))))))

  (defun my-project-query-replace-minibuffer-setup ()
    "プロジェクト置換の検索語入力用にミニバッファを設定する。"
    (deactivate-input-method)
    (my-project-query-replace-highlight-input)
    (add-hook 'post-command-hook
              #'my-project-query-replace-highlight-input nil t)
    (add-hook 'minibuffer-exit-hook
              #'my-project-query-replace-clear-input-highlights nil t))

  (defun my-project-query-replace ()
    "プロジェクト全体を前後に循環できる操作で文字列置換する。
検索語は `#SEARCH#!EXCLUDE' というConsult形式でも入力できる。"
    (interactive)
    (let ((project-root (projectile-acquire-root)))
      (pcase-let ((`(,from ,to ,exclude)
                   (my-query-replace-read-args
                    "Project query replace" nil
                    #'my-project-query-replace-parse-input
                    #'my-project-query-replace-minibuffer-setup)))
        (my/cyclic-query-replace
         from to
         (my-project-query-replace-buffers from project-root)
         project-root
         exclude))))

  :custom
  (projectile-project-root-files '(".project" ".git" "compile_commands.json"))
  ;; .projectileの ! 指定で、Gitにignoreされたファイルを候補へ戻す。
  (projectile-indexing-method 'hybrid)
  ;; C-c p pでプロジェクトごとのタブを作成・再利用する。
  (projectile-switch-project-action
   #'my-projectile-switch-project-in-tabspace)
  :hook (prog-mode . projectile-mode)
  :bind (("C-c p" . projectile-command-map)
         :map projectile-command-map
         ("RET" . my-tabspaces-switch-project-tab)
         ("r" . my-project-query-replace)
         ("s" . consult-ripgrep)
         ;; tabspacesで管理している次のプロジェクトタブへ移動する。
         ("o" . my-tabspaces-next-project-tab))
  )

;; プロジェクトごとにバッファとウィンドウ構成を分ける。
(use-package tabspaces
  :after projectile

  :preface
  (defun my-tabspaces-project-tabs ()
    "現在開いているプロジェクトタブを表示順で返す。"
    (let ((project-tab-names
           (mapcar #'cdr tabspaces-project-tab-map)))
      (seq-filter
       (lambda (tab)
         (member (alist-get 'name tab) project-tab-names))
       (tab-bar-tabs))))

  (defun my-tabspaces-project-tab-names ()
    "現在開いているプロジェクトタブ名を表示順で返す。"
    (mapcar (lambda (tab) (alist-get 'name tab))
            (my-tabspaces-project-tabs)))

  (defun my-tabspaces-switch-project-tab ()
    "現在開いているプロジェクトタブだけを候補にして移動する。"
    (interactive)
    (let ((names (my-tabspaces-project-tab-names)))
      (unless names
        (user-error "開いているプロジェクトタブがありません"))
      (tab-bar-switch-to-tab
       (completing-read "Project tab: " names nil t))))

  (defun my-tabspaces-next-project-tab ()
    "通常タブを飛ばし、次のプロジェクトタブへ循環移動する。"
    (interactive)
    (let* ((tabs (tab-bar-tabs))
           (project-tab-names (my-tabspaces-project-tab-names))
           (current-index
            (cl-position-if
             (lambda (tab) (eq (car tab) 'current-tab)) tabs))
           (tab-count (length tabs))
           (next-name
            (cl-loop for offset from 1 to tab-count
                     for tab = (nth (mod (+ current-index offset) tab-count)
                                    tabs)
                     for name = (alist-get 'name tab)
                     when (member name project-tab-names)
                     return name)))
      (unless next-name
        (user-error "開いているプロジェクトタブがありません"))
      (tab-bar-switch-to-tab next-name)))

  :custom
  (tabspaces-keymap-prefix "C-c TAB")
  (tabspaces-default-tab "Default")
  (tabspaces-remove-to-default t)
  ;; C-x bは現在のconsult-buffer設定をそのまま使う。
  (tabspaces-use-filtered-buffers-as-default nil)
  ;; まずは現在のEmacsセッション内だけで試す。
  (tabspaces-session nil)
  (tabspaces-session-auto-restore nil)
  (tabspaces-fully-resolve-paths t)
  ;; 新しいプロジェクトタブでは、そのプロジェクトのファイルを選ぶ。
  (tabspaces-project-switch-commands #'project-find-file)
  ;; ワークスペース機能は使いつつ、上部のタブバーは表示しない。
  (tab-bar-show nil)
  :config
  ;; Projectileに登録済みのGitプロジェクトを候補に含める。
  (dolist (root (projectile-relevant-known-projects))
    (when-let ((project
                (project-current nil (expand-file-name root))))
      (project-remember-project project)))
  (tab-bar-mode 1)
  (tabspaces-mode 1))

;; magit
(use-package magit
  :bind ("C-x g" . magit-status)
  )

;; vterm
(use-package vterm
  :bind (("M-[" . vterm)
         :map vterm-mode-map
         ("C-t" . other-window-or-split)
         ("C-h" . vterm-send-backspace))
  :custom
  (vterm-keymap-exceptions
   '("<f1>" "M-[" "M-]" "C-c" "C-x" "C-u" "C-g" "C-l"
     "C-t" "M-x" "M-o" "C-v" "M-v" "C-y" "M-y"))
  (vterm-max-scrollback 10000)
  (vterm-buffer-name-string "vterm: %s"))

;; PDF (DocView)
(use-package doc-view
  :ensure nil
  :bind (:map doc-view-mode-map
              ("C-t" . other-window-or-split)))

;;; Theme
(use-package doom-themes
  :custom
  (doom-themes-enable-italic t)
  (doom-themes-enable-bold t)
  :custom-face
  (doom-modeline-bar ((t (:background "#6272a4"))))
  ;; 現在の検索・置換候補はピンク、ほかの候補と通常選択は青にする。
  (query-replace
   ((t (:inherit nil :foreground "#e0f7ff" :background "#8a145c"
         :weight bold :box (:line-width 2 :color "#ff69b4")))))
  (isearch
   ((t (:inherit nil :foreground "#e0f7ff" :background "#8a145c"
         :weight bold :box (:line-width 2 :color "#ff69b4")))))
  (lazy-highlight
   ((t (:inherit nil :foreground "#e0f7ff" :background "#164e63"
         :weight bold :box (:line-width 1 :color "#38bdf8")))))
  (region
   ((t (:inherit nil :foreground unspecified :background "#164e63"
         :box nil :extend t))))
  :config
  (load-theme 'doom-outrun-electric t)
  (doom-themes-neotree-config)
  (doom-themes-org-config))

(use-package all-the-icons
  :if (display-graphic-p))

(use-package doom-modeline
  :custom
  (doom-modeline-buffer-file-name-style 'truncate-with-project)
  (doom-modeline-icon t)
  (doom-modeline-major-mode-icon nil)
  (doom-modeline-minor-modes nil)
  (display-time-24hr-format t)
  :hook
  (after-init . doom-modeline-mode)
  :config
  (line-number-mode t)
  (column-number-mode t)
  (display-time-mode t))

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

;; Pythonの仮想環境のパスを追加
(use-package pyvenv
  :hook (python-mode . pyvenv-track-virtualenv))

(use-package markdown-mode
  :mode ("\\.md\\'" . markdown-mode)

  :preface
  (defun my-markdown-read-image-path (&optional initial)
    "Read an image path with file-name completion.
Complete relative paths from the current Markdown file's directory.
INITIAL is the initial minibuffer contents."
    (if (and initial
             (string-match-p
              "\\`[[:alpha:]][[:alnum:]+.-]*://"
              initial))
        (read-string "Image URL: " initial)
      ;; read-file-nameは入力を絶対パスへ展開せず返すため、
      ;; Markdown内には入力した相対パスをそのまま挿入できる。
      (let ((insert-default-directory nil))
        (minibuffer-with-setup-hook
            (lambda ()
              (goto-char (point-max)))
          (read-file-name "Image path: " nil nil nil initial)))))

  (defun my-markdown-insert-image ()
    "Insert an inline image, allowing an empty alt text.
When the region contains a URL, use it as the initial image URL.
Otherwise, use the region as the initial alt text."
    (interactive)
    (let* ((bounds (when (use-region-p)
                     (cons (region-beginning) (region-end))))
           (region-text
            (when bounds
              (buffer-substring-no-properties
               (car bounds) (cdr bounds))))
           (region-url
            (when (and region-text
                       (string-match markdown-regex-uri region-text))
              (match-string 0 region-text)))
           (url (my-markdown-read-image-path region-url))
           (alt
            (read-string
             "Alt text (optional): "
             (unless region-url region-text)))
           (title
            (unless markdown-disable-tooltip-prompt
              (read-string "Title (optional): "))))
      (when bounds
        (delete-region (car bounds) (cdr bounds)))
      ;; 空文字列をnilへ変換しないことで ![](URL) も挿入できる。
      (markdown-insert-inline-image
       alt url
       (unless (or (null title) (string-empty-p title))
         title))))

  (defun my-markdown-insert-centered-image (url width)
    "Insert a centered inline image with a percentage WIDTH."
    (interactive
     (list
      (my-markdown-read-image-path "../assets/images/")
      (read-number "Width (%): " 60)))
    (insert
     (format
      "![](%s){style=\"display: block; width: %g%%; margin-inline: auto;\"}"
      url width)))

  :bind
  (:map markdown-mode-map
        ;; Orgと同じキーで通常のリンクを挿入する。
        ("C-c C-l" . markdown-insert-link)
        ;; 空のaltを許可する画像挿入コマンドを使用する。
        ;; C-iはTABと同じ制御文字なので、区別できるC-c iを使用する。
        ("C-c i" . my-markdown-insert-image)
        ;; 中央寄せと幅指定を含む定型画像を一度に挿入する。
        ("C-c I" . my-markdown-insert-centered-image))

  :custom
  (markdown-command "pandoc")
  ;; ```cpp など、言語を指定したコードブロックを対応するmajor modeで色付けする。
  (markdown-fontify-code-blocks-natively t)
  :custom-face
  ;; インラインコード (`code`) はテーマの背景色になじませ、黄色で表示する。
  (markdown-inline-code-face
   ((t (:foreground "#ffd400" :background "#0c0a20"))))
  ;; 表はインラインコードと区別できるように、シアンで表示する。
  (markdown-table-face
   ((t (:foreground "#42c6ff" :background "#0c0a20"))))
  ;; コードブロックの明るい背景をなくす。
  (markdown-code-face
   ((t (:background "#0c0a20"))))
  (markdown-pre-face
   ((t (:background "#0c0a20")))))

(use-package ox-gfm
  :config
  (defalias 'org-md-export-to-markdown 'org-gfm-export-to-markdown)
  (defalias 'org-md-export-as-markdown 'org-gfm-export-as-markdown))

;; eww config
(use-package shrface
  :hook (eww-after-render . shrface-mode))

(use-package engine-mode
  :config
  (engine-mode t)
  (defengine google
    "https://www.google.com/search?q=%s"
    :browser 'eww-browse-url)
  (defengine github
    "https://github.com/search?q=%s"
    :browser 'eww-browse-url))

(use-package emacs
  :preface
  (defun my-close-emacsclient-frame ()
    "現在のemacsclientフレームだけを閉じる。"
    (interactive)
    (if (daemonp)
        (delete-frame)
      (user-error "通常起動のEmacsなので終了しません")))

  :init
  (add-to-list 'default-frame-alist '(fullboth . maximized)) ; or fullboth
  ;; (add-to-list 'default-frame-alist
  ;;              '(alpha 1 1)))
  
  (setq inhibit-startup-message t
        frame-title-format "%f"
        custom-file (expand-file-name "custom.el" user-emacs-directory)
        make-backup-files nil
        auto-save-default nil
        ring-bell-function #'ignore
        initial-scratch-message nil)
  ;; (global-display-line-numbers-mode t)
  (tool-bar-mode 0)
  (menu-bar-mode 0)
  (scroll-bar-mode 0)
  ;; C-x { などの後は、C-xを付け直さずにウィンドウサイズを微調整する。
  (repeat-mode 1)
  ;; { は横幅を広げ、} は横幅を縮める。
  (keymap-set resize-window-repeat-map "{" #'enlarge-window-horizontally)
  (keymap-set resize-window-repeat-map "}" #'shrink-window-horizontally)
  
  (when (file-exists-p custom-file)
    (load custom-file))

  (defalias 'yes-or-no-p 'y-or-n-p)
  (add-hook 'asm-mode-hook #'my-asm-mode-setup)
  ;; 通常起動時だけサーバーを開始する。デーモンや既存サーバーとは重複させない。
  (require 'server)
  (unless (or (daemonp) (server-running-p))
    (server-start))
  
  :bind* (("C-t" . other-window-or-split)
          ("C-x C-c" . my-close-emacsclient-frame))
  :bind (
	 ("C-h" . delete-backward-char)
	 ("C-x C-t" . window-swap-states)
         ("C-x {" . enlarge-window-horizontally)
         ("C-x }" . shrink-window-horizontally)
         ("C-;" . comment-dwim)
         ("C-x C-d" . dired-jump)
	 ("C-a" . my-smart-beginning-of-line)
	 ("C-e" . my-smart-end-of-line)
	 ("C-x C-n" . display-line-numbers-mode)
	 ("C-x M-n" . global-display-line-numbers-mode)
	 )
  :custom-face
  ;; コメント関連のfaceを見分けやすい色で統一する。
  (font-lock-comment-face
   ((t (:foreground "#7fbf7f"))))
  (font-lock-comment-delimiter-face
   ((t (:foreground "#7fbf7f"))))
  (font-lock-doc-face
   ((t (:foreground "#7fbf7f"))))
  )
;;; ------------------------------------------------------------------
;;; 自作関数
(defun my-asm-indent-line ()
  "カスタムアセンブリ整形"
  (interactive)
  (beginning-of-line)
  (if (looking-at "^[[:space:]]*[a-zA-Z0-9_]+:") ; ラベル行
      (indent-line-to 0)
    (indent-line-to asm-indent-level)))

(defun my-asm-mode-setup ()
  "アセンブリ用のインデント設定を適用する。"
  (setq-local asm-indent-level 4
              indent-line-function #'my-asm-indent-line))

(defvar my-smart-jump-state nil
  "Stores state for smart beginning/end of line navigation.")

(defun my-smart-line-boundary (command move-line buffer-boundary)
  "COMMANDを連打して行端、BUFFER-BOUNDARY、元の位置へ移動する。
MOVE-LINEは行頭または行末へ移動する関数である。"
  (cond
   ((not (eq last-command command))
    (setq my-smart-jump-state (list :origin (point) :step 1))
    (funcall move-line 1))
   ((= (plist-get my-smart-jump-state :step) 1)
    (plist-put my-smart-jump-state :step 2)
    (goto-char (funcall buffer-boundary)))
   (t
    (goto-char (plist-get my-smart-jump-state :origin))
    (setq this-command nil))))

(defun my-smart-beginning-of-line ()
  "Toggle between beginning of line, beginning of buffer, and original point."
  (interactive)
  (my-smart-line-boundary
   'my-smart-beginning-of-line #'move-beginning-of-line #'point-min))

(defun my-smart-end-of-line ()
  "Toggle between end of line, end of buffer, and original point."
  (interactive)
  (my-smart-line-boundary
   'my-smart-end-of-line #'move-end-of-line #'point-max))

(defun other-window-or-split ()
  "Move to the next window, splitting horizontally when only one exists."
  (interactive)
  (when (one-window-p)
    (split-window-horizontally))
  (other-window 1))


;;    +---------------------------------------------+
;;    |                Language Config              |
;;    +---------------------------------------------+
(set-face-attribute 'default nil
                    :family "DejaVu Sans Mono"
                    :height 140)

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
  :demand t

  :preface
  (defun my-ddskk-setup-color-cursor-for-frame (frame)
    "emacsclientで作成したGUIフレームにDDSKKのカーソル色を設定する。"
    (when (display-graphic-p frame)
      (with-selected-frame frame
        (ccc-setup)
        (when (bound-and-true-p skk-mode)
          (skk-cursor-set)))))

  (defvar-local my-ddskk-default-input-initialized nil
    "このバッファでDDSKKの初期入力モードを設定済みなら非nil。")

  (defconst my-ddskk-rom-kana-rules
    '(("!" nil "!")
      ("?" nil "?")
      (":" nil ":")
      (";" nil ";")
      ("(" nil "(")
      (")" nil ")")
      ("[" nil "「")
      ("]" nil "」")
      ("{" nil "{")
      ("}" nil "}")
      ("'" nil "'")
      ("\"" nil "\""))
    "DDSKKで日本語入力中も半角のまま入力する記号。")

  (defun my-ddskk-start-buffer-in-latin-mode ()
    "通常バッファの入力方式をDDSKK英字モードで初期化する。"
    (when (and (not (minibufferp))
               (not (string-prefix-p " " (buffer-name)))
               (not (derived-mode-p 'special-mode))
               (not my-ddskk-default-input-initialized))
      (setq my-ddskk-default-input-initialized t)
      (cond
       ((null current-input-method)
        (activate-input-method "japanese-skk")
        (skk-latin-mode 1))
       ;; ファイルのメジャーモード設定時に `current-input-method' だけが
       ;; 残り、DDSKKのバッファローカルな状態が消える場合は再初期化する。
       ((and (equal current-input-method "japanese-skk")
             (not (bound-and-true-p skk-mode)))
        (deactivate-input-method)
        (activate-input-method "japanese-skk")
        (skk-latin-mode 1)))))

  :init
  (setq default-input-method "japanese-skk")
  :bind ("C-x j" . toggle-input-method)
  :hook
  ((after-change-major-mode . my-ddskk-start-buffer-in-latin-mode)
   (buffer-list-update . my-ddskk-start-buffer-in-latin-mode))
  :config
  ;; このフックだけは名前が `-hook' で終わらないため明示的に登録する。
  (add-hook 'after-make-frame-functions
            #'my-ddskk-setup-color-cursor-for-frame)
  (setq skk-jisyo "~/.skk-jisyo"
        ;; DDSKK標準のカーソル色変更機能を使う。
        skk-use-color-cursor t
        skk-cursor-latin-color "lightskyblue"
        skk-cursor-hiragana-color "lightpink"
        skk-cursor-katakana-color "lightgreen"
        ;; 変換候補をインライン表示する。
        skk-show-inline t
        skk-kutouten-type 'jp)
  ;; この設定より前に作られた起動直後のバッファにも適用する。
  (my-ddskk-start-buffer-in-latin-mode)
  ;; 設定を再評価した場合は、既存のGUIフレームにも反映する。
  (dolist (frame (frame-list))
    (my-ddskk-setup-color-cursor-for-frame frame))
  ;; 再評価しても同じキーの規則を重複させない。
  (setq skk-rom-kana-rule-list
        (append
         my-ddskk-rom-kana-rules
         (cl-remove-if
          (lambda (rule)
            (assoc (car rule) my-ddskk-rom-kana-rules))
          skk-rom-kana-rule-list))))

(use-package org
  :ensure nil

  :init
  ;; OrgリンクはEmacs内のewwで開く。
  (setq browse-url-browser-function #'eww-browse-url)

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

  (my/advice-add-once
   #'org-babel-execute-src-block :after
   #'my-org-redisplay-inline-images))


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
;;    |                 GPTel Config                |
;;    +---------------------------------------------+
(use-package gptel
  :ensure t
  :demand t

  :preface
  (define-prefix-command 'my-gptel-command-map)

  (defun my-gptel-show-context ()
    "gptelに追加されているコンテキストの一覧を表示する。"
    (interactive)
    (require 'gptel-context)
    (gptel-context--buffer-setup nil nil gptel-context))

  (defun my-gptel-clear-context ()
    "gptelに追加されているコンテキストをすべて削除する。"
    (interactive)
    (require 'gptel-context)
    (gptel-context-remove-all t))

  (defun my-gptel-select-model ()
    "現在のgptelバックエンドで使用するモデルを選択する。"
    (interactive)
    (let* ((models (gptel-backend-models gptel-backend))
           (candidates
            (mapcar (lambda (model)
                      (cons (gptel--model-name model) model))
                    models))
           (selected-name
            (completing-read
             "gptel model: " candidates nil t nil nil
             (gptel--model-name gptel-model)))
           (selected-model (cdr (assoc selected-name candidates))))
      (set-default 'gptel-model selected-model)
      (setq gptel-model selected-model)
      (run-hooks 'gptel-refresh-buffer-hook)
      (message "gptel model: %s" selected-name)))

  :bind
  (("C-c g" . my-gptel-command-map)
   :map my-gptel-command-map
   ("g" . gptel)
   ("a" . gptel-add)
   ("c" . my-gptel-show-context)
   ("s" . gptel-send)
   ("f" . gptel-add-file)
   ("d" . my-gptel-clear-context)
   ("k" . gptel-abort)
   ("r" . gptel-rewrite)
   ("m" . my-gptel-select-model))

  :init
  (setq gptel-model 'gpt-5.4-mini)

  :custom
  ;; ブラウザからlocalhostへ戻れない環境でも使えるデバイスコード認証。
  (gptel-openai-oauth-login-method 'device)

  :config
  ;; ChatGPT Plus/Proの契約をOpenAI OAuth経由で利用する。
  (setq gptel-backend
        (gptel-make-openai-oauth "OpenAI-sub")))

;;    +---------------------------------------------+
;;    |                Agent Config                 |
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

  (defun my-agent-shell-enable-skk-for-coding-agents ()
    "CodexとClaude Codeの入力欄をDDSKKのかなモードで開始する。"
    (when (memq (map-nested-elt
                 agent-shell--state '(:agent-config :identifier))
                '(codex claude-code))
      (skk-mode 1)))

  (defvar-local my-agent-shell-skk-mode-before-permission nil
    "Agent Shellの承認待ち前のDDSKK入力モード。")

  (defvar-local my-agent-shell-skk-permission-subscription nil
    "DDSKKの承認入力切り替え用サブスクリプション。")

  (defun my-agent-shell-handle-skk-permission-event (event)
    "Agent Shellの承認中だけDDSKKをASCIIモードにする。"
    (pcase (map-elt event :event)
      ('permission-request
       (let ((state (my/ddskk-current-state)))
         (when (and (memq state '(hiragana katakana))
                    (null my-agent-shell-skk-mode-before-permission))
           (setq my-agent-shell-skk-mode-before-permission state)
           ;; yや!をSKKで変換せず、承認ボタンに渡す。
           (skk-latin-mode 1))))
      ('permission-response
       ;; 複数の承認がある場合は、最後の回答後に戻す。
       (when (and my-agent-shell-skk-mode-before-permission
                  (not (agent-shell--permission-pending-p)))
         (let ((mode my-agent-shell-skk-mode-before-permission))
           (setq my-agent-shell-skk-mode-before-permission nil)
           (my/ddskk-restore-state mode))))))

  (defun my-agent-shell-setup-skk-permission-handling ()
    "Agent Shellの承認イベントにDDSKK切り替え処理を登録する。"
    (unless my-agent-shell-skk-permission-subscription
      (setq my-agent-shell-skk-permission-subscription
            (agent-shell-subscribe-to
             :shell-buffer (current-buffer)
             :on-event #'my-agent-shell-handle-skk-permission-event))))

  (defun my-agent-shell-refresh-skk-cursor-after-display
      (shell-buffer &rest _)
    "Agent Shell表示直後にDDSKKのカーソル色を反映する。"
    (when (buffer-live-p shell-buffer)
      (with-current-buffer shell-buffer
        (when (and (bound-and-true-p skk-mode)
                   (get-buffer-window shell-buffer t))
          (with-selected-window (get-buffer-window shell-buffer t)
            (skk-cursor-set))))))

  :hook
  ((agent-shell-mode . my-agent-shell-enable-skk-for-coding-agents)
   (agent-shell-mode . my-agent-shell-setup-skk-permission-handling))

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
  (agent-shell-session-restore-verbosity 'last)

  :config
  ;; mode hookはバッファ表示前に走るため、表示後にカーソル色を更新する。
  (my/advice-add-once
   #'agent-shell--display-buffer :after
   #'my-agent-shell-refresh-skk-cursor-after-display)

  ;; 読み込み後に既存履歴を修復し、保存前にも同じ形式へ統一する。
  (my/advice-add-once
   #'shell-maker--read-input-ring-history :after
   #'my-agent-shell-normalize-history)
  (my/advice-add-once
   #'shell-maker--write-input-ring-history :before
   #'my-agent-shell-normalize-history))
