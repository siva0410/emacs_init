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
  :config
  (unless (package-installed-p 'browse-kill-ring)
  (package-install 'browse-kill-ring))
  (define-key global-map (kbd "C-x y") 'browse-kill-ring)
  )

(use-package vertico
  :custom
  (vertico-scroll-margin 0) ;; Different scroll margin
  (vertico-count 20) ;; Show more candidates
  (vertico-resize t) ;; Grow and shrink the Vertico minibuffer
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

;; ;; ivy
;; (unless (package-installed-p 'counsel)
;;   (package-install 'counsel))
;; (ivy-mode t)
;; (counsel-mode t)
;; (define-key global-map (kbd "C-s") 'swiper)
;; (define-key global-map (kbd "C-S-s") 'counsel-imenu)
;; (setq ivy-height 15)

;; vterm
(use-package vterm
  :bind (
	 ("M-[" . vterm)
	 )
  :config
  (setq vterm-keymap-exceptions '("<f1>" "M-[" "M-]" "C-c" "C-x" "C-u" "C-g" "C-l" "C-t" "M-x" "M-o" "C-v" "M-v" "C-y" "M-y"))
  (setq vterm-max-scrollback 10000)
  (setq vterm-buffer-name-string "vterm: %s")
  )

;; magit
(use-package magit
  :bind ("C-x g" . magit-status)
  )

;; ;;    +---------------------------------------------+
;; ;;    |                  Key Config                 |
;; ;;    +---------------------------------------------+
(defun other-window-or-split ()
  (interactive)
  (when (one-window-p)
    (split-window-horizontally))
  (other-window 1))

;; (define-key global-map (kbd "C-h") 'delete-backward-char)
;; (define-key global-map (kbd "C-t") 'other-window-or-split)
;; (define-key global-map (kbd "C-;") 'comment-dwim)
;; (define-key global-map (kbd "C-x C-d") 'dired-jump)

;; (define-key dired-mode-map (kbd "C-t") 'other-window-or-split)
;; ;;(define-key dired-mode-map (kbd "f8") 'toggle-frame-fullscreen)

;;; Theme
;; (use-package color-theme-sanityinc-tomorrow
;;   :init
;;   (load-theme 'color-theme-sanityinc-tomorrow-night t))

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
  )

(use-package rainbow-delimiters
  :hook (prog-mode . rainbow-delimiters-mode))

;;    +---------------------------------------------+
;;    |                System Config                |
;;    +---------------------------------------------+
(use-package emacs
  :init
  (add-to-list 'default-frame-alist '(fullscreen . maximized)) ; or fullboth
  ;;; Font
  (add-to-list 'default-frame-alist' (font . "DejaVu Sans Mono-14"))  
  ;; (add-to-list 'default-frame-alist
  ;;              '(alpha 1 1)))
  
  (setq inhibit-startup-message t)
  (setq frame-title-format "%f")
  (global-display-line-numbers-mode t)
  (tool-bar-mode 0)
  (menu-bar-mode 0)
  
  ;;; Mode Line
  ;; (column-number-mode t)
  ;; (display-battery-mode t)
  ;; (setq display-time-24hr-format t)
  ;; (display-time-mode t)
  
  ;;; Indent
  ;; (setq-default tab-width 4)
  ;; (setq-default indent-tabs-mode nil)

  ;;; Parentheses
  ;; (setq show-paren-delay 0)
  ;; (setq show-paren-style 'expression)
  ;; (set-face-background 'show-paren-match "pink")
  
  (setq custom-file (expand-file-name "custom.el" user-emacs-directory))
  (when (file-exists-p custom-file)
    (load custom-file))

  (setq make-backup-files nil)
  (setq auto-save-default nil)
  (setq ring-bell-function 'ignore)
  (defalias 'yes-or-no-p 'y-or-n-p)
  
  ;; scratch buffer
  (setq initial-scratch-message nil)

  :bind (("C-h" . delete-backward-char)
         ("C-t" . other-window-or-split)
         ("C-;" . comment-dwim)
         ("C-x C-d" . dired-jump))
  :config
  (load-theme 'doom-dracula t)
  )

;; (defvar my-smart-jump-state nil
;;   "Stores state for smart beginning/end of line navigation.")

;; (defun my-smart-beginning-of-line ()
;;   "Toggle between beginning of line, beginning of buffer, and original point."
;;   (interactive)
;;   (cond
;;    ;; 1回目: 行頭へ移動し、元の位置を保存
;;    ((not (eq last-command 'my-smart-beginning-of-line))
;;     (setq my-smart-jump-state (list :origin (point) :step 1))
;;     (move-beginning-of-line 1))
;;    ;; 2回目: バッファ先頭へ
;;    ((= (plist-get my-smart-jump-state :step) 1)
;;     (plist-put my-smart-jump-state :step 2)
;;     (goto-char (point-min)))
;;    ;; 3回目: 元の位置へ戻る
;;    (t
;;     (goto-char (plist-get my-smart-jump-state :origin))
;;     (setq this-command nil)))) ; 状態リセット

;; (defun my-smart-end-of-line ()
;;   "Toggle between end of line, end of buffer, and original point."
;;   (interactive)
;;   (cond
;;    ((not (eq last-command 'my-smart-end-of-line))
;;     (setq my-smart-jump-state (list :origin (point) :step 1))
;;     (move-end-of-line 1))
;;    ((= (plist-get my-smart-jump-state :step) 1)
;;     (plist-put my-smart-jump-state :step 2)
;;     (goto-char (point-max)))
;;    (t
;;     (goto-char (plist-get my-smart-jump-state :origin))
;;     (setq this-command nil))))

;; (global-set-key (kbd "C-a") #'my-smart-beginning-of-line)
;; (global-set-key (kbd "C-e") #'my-smart-end-of-line)
