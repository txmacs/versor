;;; versor-dimensions.el -- versatile cursor
;;; Time-stamp: <2006-03-28 17:17:59 jcgs>
;;
;; emacs-versor -- versatile cursors for GNUemacs
;;
;; Copyright (C) 2004, 2006  John C. G. Sturdy
;;
;; This file is part of emacs-versor.
;; 
;; emacs-versor is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation; either version 2 of the License, or
;; (at your option) any later version.
;; 
;; emacs-versor is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.
;; 
;; You should have received a copy of the GNU General Public License
;; along with emacs-versor; if not, write to the Free Software
;; Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA

(provide 'versor-dimensions)

(mapcar 'makunbound '(versor-current-level-name moves-moves versor-meta-level versor-level))

(mapcar (lambda (nb-command) (autoload nb-command "nested-blocks" nil t))
	'(nested-blocks-backward nested-blocks-forward
	  nested-blocks-leave-backwards nested-blocks-enter))

(defvar versor-meta-level 1
  "The current versor meta-level, as an index into moves-moves")

(defvar versor-level 1
  "The current versor level, as an index into (aref moves-moves versor-meta-level)")

(defvar versor-meta-level-shadow nil
  "If non-nil, the value to use instead of versor-meta-level.
Bound in versor-do-dynamic-menu because otherwise we end up with the
wrong meta-level, as we have just come out of some menuing code.
Other uses for this might be found.")

(defvar versor-level-shadow nil
  "If non-nil, the value to use instead of versor-level.
Bound in versor-do-dynamic-menu because otherwise we end up with the
wrong level, as we have just come out of some menuing code.
Other uses for this might be found.")

(defmacro versor-level-name (level)
  "Return the name of LEVEL."
  `(first (aref (versor-current-meta-level) ,level)))

(defmacro versor-meta-level-name (meta-level)
  "Return the name of META-LEVEL."
  `(aref (aref moves-moves ,meta-level) 0))

(defun versor-make-movemap-set (name &rest movemaps)
  "Make a set of movemaps called NAME from the remaining arguments.
The lowest-level (finest-grain) movemap should come first.
A movemap-set represents a metalevel of movements.
Also, all the movemap-sets are grouped together using another movemap-set,
called moves-moves, which is the root variable of the versor system."
  (apply 'vector name movemaps))

(defun versor-make-movemap (name)
  "Make a movemap called NAME.
A move map is a list whose head is the name of the map,
and whose tale is an alist of moves and the commands which execute them.
Moves are named by the following symbols, and possibly others added since
this documentation was written:
  previous
  next
  first
  last
  mark
  delete
  end-of-item
  color
The pseudo-move \"color\" gives the cursor colour to use when this move map
is current.
you can fill in the contents of a move map by using versor-define-move and
versor-define-moves.
Move maps are grouped together by versor-make-movemap-set."
  (list name))

(defun versor-define-move (movemap move command)
  "In MOVEMAP define MOVE to do COMMAND. Analogous to define-key.
See the definition of versor-make-movemap for details of move maps."
  (let ((pair (assoc move movemap)))
    (if pair
	(rplacd pair command)
      (rplacd movemap
	      (cons (cons move
			  command)
		    (cdr movemap))))))

(defun versor-define-moves (movemap move-command-specs)
  "In MOVEMAP define each of MOVE-COMMAND-SPECS.
We can't just splice MOVE-COMMAND-SPECS into the map because that would
not interact properly with any existing definitions in the map.
See the definition of versor-make-movemap for details of move maps."
  (mapcar 
   (function
    (lambda (k-c)
      (versor-define-move movemap (first k-c) (second k-c))))
   move-command-specs))

(mapcar (function 
	 (lambda (name)
	   (set (intern (concat "movemap-" name))
		(versor-make-movemap name))))
	'("chars"
	  "lines"
	  "pages"
	  "exprs"
	  "depth"
	  "statement-parts"
	  "statements"
	  "defuns"
	  "words"
	  "phrases"
	  "sentences"
	  "paragraphs"
	  "blocks"
	  "block-depth"
	  "cells"
	  "rows"))

(versor-define-moves movemap-chars
		      '((color "purple")
			(first versor-start-of-line)
			(previous backward-char)
			(next forward-char)
			(last end-of-line)
			;; (delete delete-char)
			(transpose transpose-chars)
			))

(versor-define-moves movemap-lines
		     '((color "black")
		       (other-color "gray")
		       (:background "black")
		       (:foreground "white")
		       (first beginning-of-buffer)
		       (previous versor-previous-line)
		       (next versor-next-line)
		       (last end-of-buffer)
		       (end-of-item end-of-line)
		       ;; (delete kill-line)
			(transpose transpose-lines)
		       ))

(versor-define-moves movemap-pages
		     '((color "white")
		       (other-color "gray")
		       (first beginning-of-buffer)
		       (previous
			;; scroll-down
			forward-page
			)
		       (next
			;; scroll-up
			forward-page
			)
		       (last end-of-buffer)))

(versor-define-moves movemap-exprs
		     '((color "green")
		       (:underline "dark green")
		       (:background "pale green")
		       (first first-sexp)
		       (previous previous-sexp)
		       (next next-sexp)
		       (end-of-item forward-sexp)
		       (last last-sexp)
		       (mark mark-sexp)
		       ;; (delete kill-sexp)
		       (transpose transpose-sexps)
		       (dwim versor-dwim-lispishly)
		       ))

(versor-define-moves movemap-depth
		     '((color "orange")
		       (:background "orange")
		       (:foreground "green")
		       (first beginning-of-defun)
		       (previous versor-backward-up-list)
		       (next versor-down-list)
		       (last innermost-list)
		       (dwim versor-dwim-lispishly)))

(versor-define-moves movemap-statement-parts
		     '((color "cyan")
		       (:background "cyan")
		       (:foreground "red")
		       (first navigate-this-head)
		       (previous statement-navigate-parts-previous)
		       (next statement-navigate-parts-next)
		       (last navigate-this-body)
		       (end-of-item latest-statement-navigation-end)
		       (dwim versor-dwim-lispishly)))

(versor-define-moves movemap-statements
		     '((color "cyan")
		       (:background "cyan")
		       (:foreground "green")
		       (first beginning-of-defun)
		       (previous previous-statement)
		       (next next-statement)
		       (last end-of-defun) ;;;;;;;;;;;;;;;; make this go back one statement from the end of the defun
		       (end-of-item latest-statement-navigation-end)
		       (dwim versor-dwim-lispishly)))

(versor-define-moves movemap-defuns
		     '((color "yellow")
		       (:background "yellow")
		       (:foreground "black")
		       (first versor-first-defun)
		       (previous versor-previous-defun)
		       (next versor-next-defun)
		       (end-of-item end-of-defun)
		       (last versor-last-defun)
		       ;; (transpose transpose-sexps); would only work for lisp?
		       (dwim versor-dwim-lispishly)
		       ))

(versor-define-moves movemap-words
		     '((color "grey")
		       (other-color "green")
		       (:background "light gray")
		       (:foreground "black")
		       (:underline "dark slate gray")
		       ;; things like this (notionally the wrong
		       ;; dimension) still work OK, because of how
		       ;; versor-indicate-current-item works when the
		       ;; things it calls don't explicitly set the item
		       ;; boundaries for it:
		       (first backward-phrase) 
		       (previous backward-word)
		       (next versor-next-word)
		       (end-of-item versor-end-of-word)
		       (last forward-phrase)
		       (delete versor-delete-word)
		       (transpose transpose-words)
		       (dwim versor-dwim-textually)))

(versor-define-moves movemap-phrases
		     '((color "blue")
		       (:background "cornflower blue")
		       (:foreground "black")
		       (first backward-sentence)
		       (previous backward-phrase)
		       (next forward-phrase)
		       (last forward-sentence)
		       (dwim versor-dwim-textually)))

(versor-define-moves movemap-sentences
		     '((color "cyan")
		       (:background "light sky blue")
		       (:foreground "black")
		       (first versor-backward-paragraph)
		       (previous backward-sentence)
		       (next forward-sentence)
		       (last versor-forward-paragraph)
		       (transpose transpose-sentences)
		       (dwim versor-dwim-textually)))

(versor-define-moves movemap-paragraphs
		     '((color "yellow")
		       (:background "yellow")
		       (:foreground "red")
		       (first beginning-of-buffer)
		       (previous versor-backward-paragraph)
		       (next versor-forward-paragraph)
		       (end-of-item versor-end-of-paragraph)
		       (last end-of-buffer)
		       (transpose transpose-paragraphs)
		       (dwim versor-dwim-textually)))

(versor-define-moves movemap-blocks
		     '((color "green")
		       (:underline "dark green")
		       (:foreground "white")
		       (:background "pale green")
		       (previous nested-blocks-backward)
		       (next nested-blocks-forward)))

(versor-define-moves movemap-block-depth
		     '((color "orange")
		       (:foreground "black")
		       (:background "orange")
		       (previous nested-blocks-leave-backwards)
		       (next nested-blocks-enter)))

(versor-define-moves movemap-cells
		     '((color "blue")
		       (:background "cyan")
		       (first versor-first-cell)
		       (previous versor-previous-cell)
		       (next versor-next-cell)
		       (last versor-last-cell)))

(versor-define-moves movemap-rows
		     '((color "cyan")
		       (:background "light sky blue")
		       (:foreground "black")
		       (first versor-first-row)
		       (previous versor-previous-row)
		       (next versor-next-row)
		       (last versor-last-row)))


;; See versor-make-movemap-set for details of movemap-sets
		       
(setq moves-cartesian (versor-make-movemap-set "cartesian"
					       movemap-chars
					       movemap-lines
					       movemap-pages)

      moves-structural (versor-make-movemap-set "structural"
						movemap-chars
						movemap-exprs
						movemap-depth
						movemap-defuns)

      moves-text (versor-make-movemap-set "text"
					  movemap-chars
					  movemap-words
					  movemap-phrases
					  movemap-sentences
					  movemap-paragraphs)

      moves-structured-text (versor-make-movemap-set "structured text"
						     movemap-chars
						     movemap-words
						     ;; movemap-paragraphs
						     movemap-blocks
						     movemap-block-depth)

      moves-tables (versor-make-movemap-set "tables"
					    movemap-chars
					    movemap-cells
					    movemap-rows)

      moves-program (versor-make-movemap-set "program"
					     movemap-chars
					     movemap-exprs
					     movemap-statement-parts
					     movemap-statements
					     movemap-defuns))

(defvar moves-moves
  (versor-make-movemap-set "metamoves"
			   moves-cartesian
			   moves-structural
			   moves-text
			   moves-structured-text
			   moves-tables
			   moves-program)
  "The map of meta-moves.
See versor-make-movemap-set for the description of move map sets.
Note that this is a reuse of that data type at a different level. ")

(defmacro versor-current-meta-level ()
  "The current meta-level, as an array."
  '(aref moves-moves (or versor-meta-level-shadow versor-meta-level)))

(defun versor-current-level (&optional level-offset)
  "Return the current level, as an array.
With optional LEVEL-OFFSET, add that to the level first."
  (if (integerp level-offset)
      (let ((meta (versor-current-meta-level)))
	(aref meta (min (+ (or versor-level-shadow versor-level) level-offset)
			(1- (length meta)))))
    (aref (versor-current-meta-level) (or versor-level-shadow versor-level))))

(defun versor-action (level action)
  "From LEVEL get ACTION, which will be a move such as next or previous."
  (cdr (assoc action level)))

(defvar versor-current-level-name (first (versor-current-level))
  "The name of the current versor level, for display in the global-mode-string")

(defvar versor-current-meta-level-name (aref (versor-current-meta-level) 0)
  "The name of the current versor meta-level, for display in the global-mode-string")

(defun versor-:trim-level ()
  "Ensure that versor-level is in range."
  (let ((max (1- (length (versor-current-meta-level)))))
    (when (> versor-level max)
      (setq versor-level
	    (if versor-level-wrap 1 max)))
    (when (< versor-level 1)
      (setq versor-level
	    (if versor-level-wrap max 1)))))

(defun versor-:trim-meta-level ()
  "Ensure that versor-meta-level is in range."
  (let ((max (1- (length moves-moves))))
    (when (> versor-meta-level max)
      (setq versor-meta-level
	    (if versor-meta-level-wrap 1 max)))
    (when (< versor-meta-level 1)
      (setq versor-meta-level
	    (if versor-meta-level-wrap max 1)))))

(defvar versor-meta-dimensions-valid-for-modes
  '(((emacs-lisp-mode lisp-mode scheme-mode lisp-interaction-mode)
     t "cartesian" "structural" "text")
    ((texinfo-mode tex-mode latex-mode html-mode html-helper-mode)
     t "cartesian" "text" "structured text" "tables")
    ((c-mode perl-mode java-mode)
     t "cartesian" "structural" "program" "text")
    (t nil))				; allow any
  "*Controls which meta-dimensions are valid for which major modes.
If t, all meta-dimensions are allowed in all major modes.
Otherwise, it is an alist mapping modes to sublists describing the
meta-dimensions allowed in that mode.
Each sublist (beyond the mode) should begin with t, to indicate that
only the meta-dimensions listed are to be allowed, or nil, to indicate
that all meta-dimensions except those listed are allowed.
The rest of the sublist is the meta-dimensions allowed or blocked for that mode.
The head of the node may also be a list of major modes for which this
rule applies.
A sublist for a major mode t gives the defaults.")

(defun assoc-multi-key (key list)
  "Look for KEY in the cars of LIST.
Like assoc, return the element of list for which it matches."
  (catch 'found
    (while list
      (if (if (consp (caar list))
	      (member key (caar list))
	    (equal key (caar list)))
	  (throw 'found (car list))
	(setq list (cdr list))))
    nil))

(defun versor-meta-dimension-valid-for-mode (meta-name mode)
  "Return whether the meta-dimension called META-NAME is allowed in MODE."
  ;; smug -- worked first time
  (cond
   ((eq versor-meta-dimensions-valid-for-modes t)
    t)
   ((consp versor-meta-dimensions-valid-for-modes)
    (let* ((descr (cdr (or (assoc major-mode versor-meta-dimensions-valid-for-modes)
			   (assoc-multi-key major-mode versor-meta-dimensions-valid-for-modes)
			   (assoc t versor-meta-dimensions-valid-for-modes))))
	   (allowing (car descr))
	   (mentioned (member meta-name (cdr descr))))
      (or (and allowing mentioned)
	  (and (not allowing) (not mentioned)))))
   (t t)))

(defvar versor-mode-current-levels nil
  "Alist of mode name symbols to the current meta-level and level for that mode.
Used by versor-local, but defined in versor-dimensions."
  ;; I tried getting versor-local's versor-mode-change-function to remember the
  ;; levels for the mode, but couldn't get it to work -- something about the
  ;; mode being set strangely in the minibuffer, I think
)

;;;; end of versor-dimensions.el
