;;; -*- emacs-lisp -*-

;;;
;;; $Id: project.el,v 1.5 2000/09/12 05:34:35 eserte Exp $
;;; Author: Slaven Rezic
;;;
;;; Copyright © 1997 Slaven Rezic. All rights reserved.
;;;
;;; Mail: <URL:mailto:eserte@cs.tu-berlin.de>
;;; WWW:  <URL:http://www.cs.tu-berlin.de>
;;;

(defvar project-buffer nil)
(defvar project-last-project nil)
(defvar project-current-project nil)
(defvar project-input-history nil)
(defvar project-autosave t)

(defvar project-mode-map nil
   "Keymap for project buffer.")

(defun project-start-stop-project (&optional project-name)
  (interactive)
  (if (not project-current-project)
      (project-start-project project-name)
    (project-stop-project)))

(defun project-start-project (&optional project-name)
  (interactive)
  (if (null project-name)
      (setq project-name
	    (completing-read "Project name: "
			     (mapcar (lambda (elem)
				       (list elem))
				     (project-get-projects))
			     nil
			     t
			     project-last-project
			     project-input-history)))
  (setq project-current-project project-name)
  (let ((new-entry (project-find-new-entry)))
    (save-excursion
      (set-buffer project-buffer)
      (setq mode-name (concat "Project: " project-current-project))
      (goto-char new-entry)
      (insert "|" (project-get-current-time) "-")
      (put-text-property new-entry
			 (point)
			 'face 'project-running-face)
      (insert "\n")))
  (if (not (member 'project-update-endtime display-time-hook))
      (add-hook 'display-time-hook 'project-update-endtime))
  )

(if (not (fboundp 'split-string)) ; erst ab Emacs 20
    (defun split-string (string &optional separators)
      "Splits STRING into substrings where there are matches for SEPARATORS.
Each match for SEPARATORS is a splitting point.
The substrings between the splitting points are made into a list
which is returned.
If SEPARATORS is absent, it defaults to \"[ \\f\\t\\n\\r\\v]+\"."
      (let ((rexp (or separators "[ \f\t\n\r\v]+"))
	    (start 0)
	    (list nil))
	(while (string-match rexp string start)
	  (or (eq (match-beginning 0) 0)
	      (setq list
		    (cons (substring string start (match-beginning 0))
			  list)))
	  (setq start (match-end 0)))
	(or (eq start (length string))
	    (setq list
		  (cons (substring string start)
			list)))
	(nreverse list))))

(defun project-find-project-from-point (current-project)
  (let ((hier (split-string current-project "/"))
	(i 1))
    (while hier
      (search-forward (concat (make-string i ?>) (car hier)))
      (forward-line)
      (setq hier (cdr hier))
      ))
  )

(defun project-find-new-entry ()
  (save-excursion
    (set-buffer project-buffer)
    (goto-char (point-min))
    (project-find-project-from-point project-current-project)
    (while (looking-at "^/")
      (forward-line))
    (while (looking-at "^|")
      (forward-line))
    (point)))

(defun project-goto-current ()
  (interactive)
  (let ((p (project-find-new-entry)))
    (goto-char p)))

(defun project-get-current-time ()
  (let ((time (current-time)))
    (format "%.0f" (+ (* (float (nth 0 time)) 65536)
		      (nth 1 time)))))

(defun project-stop-project ()
  (interactive)
  (if project-current-project
      (progn
	(project-update-endtime)
	(remove-hook 'display-time-hook 'project-update-endtime)
	(let ((new-entry (project-find-new-entry)))
	  (save-excursion
	    (set-buffer project-buffer)
	    (setq mode-name "Project STOPPED")
	    (goto-char new-entry)
	    (forward-line -1)
	    (remove-text-properties (point)
				    (save-excursion (end-of-line)
						    (point))
				    '(face))))
	(setq project-last-project project-current-project)
	(setq project-current-project nil)
	(if project-autosave
	    (save-excursion
	      (set-buffer project-buffer)
	      (save-buffer)))
	)
    ))

(defun project-update-endtime ()
  (if (and project-current-project
	   (buffer-live-p project-buffer))
      (let ((new-entry (project-find-new-entry)))
	(save-excursion
	  (set-buffer project-buffer)
	  (goto-char new-entry)
	  (forward-line -1)
	  (search-forward "-")
	  (delete-region (point) (save-excursion (end-of-line)
						 (point)))
	  (insert (project-get-current-time))))
    )
  )

;;; obsolete, löschen
(defun project-old-get-projects ()
  (let (projects)
    (save-excursion
      (set-buffer project-buffer)
      (goto-char (point-min))
      (while (re-search-forward "^>+\\(.*\\)" nil t)
	(setq projects (cons (buffer-substring (match-beginning 1)
					       (match-end 1))
			     projects))))
    projects))

(defun project-get-projects ()
  (let (projects leafname pathname level
	(hier []))
    (save-excursion
      (set-buffer project-buffer)
      (goto-char (point-min))
      (while (re-search-forward "^\\(>+\\)\\(.*\\)" nil t)
	(setq leafname (buffer-substring (match-beginning 2)
					 (match-end 2)))
	(setq level (1- (- (match-end 1) (match-beginning 1))))
	(if (<= (length hier) level)
	    (setq hier (vconcat hier (vector leafname)))
	  (aset hier level leafname))
	(setq pathname "")
	(let ((i 0))
	  (while (<= i level)
	    (setq pathname (concat pathname 
				   (if (string= pathname "") "" "/")
				   (aref hier i)))
	    (setq i (1+ i))
	    ))
	(setq projects (cons pathname
			     projects))))
    projects))

(defun project-show-time ()
  (interactive)
  (save-excursion
    (set-buffer project-buffer)
    (beginning-of-line)
    (if (looking-at "^|\\([0-9]+\\)-\\([0-9]+\\)")
	(let* ((from-time (string-to-number
			   (concat
			    (buffer-substring (match-beginning 1)
					      (match-end 1))
			    ".0")))
	       (to-time (string-to-number
			 (concat
			  (buffer-substring (match-beginning 2)
					    (match-end 2))
			  ".0")))
	       (diff-sec (- to-time from-time))
	       (hi-from (floor (/ from-time 65536)))
	       (lo-from (floor (mod from-time 65536)))
	       (hi-to (floor (/ to-time 65536)))
	       (lo-to (floor (mod to-time 65536))))
	  (message (concat ;;; XXX stimmt nicht: project-current-project
		           ;;; XXX": "
			   (format-time-string "%d.%m.%y %T - "
					       (list hi-from lo-from))
			   (format-time-string "%d.%m.%y %T"
					       (list hi-to lo-to))
			   (format " (%d:%02d)"
				   (floor (/ diff-sec 60))
				   (floor (mod diff-sec 60)))))
	  ))))

(defun project-kill-buffer ()
  (project-stop-project)
  (remove-hook 'display-time-hook
	       'project-update-endtime)
  )

;;;###autoload
(defun project-mode ()
  (interactive)
  (save-excursion
    (goto-char (point-min))
    (and (not (looking-at "^#PJ[1T]"))
	 (error "This is not a project file")))
  (setq mode-name "Project")
  (setq major-mode 'project-mode)
  (setq project-buffer (current-buffer))

  (global-set-key [f7] 'project-start-stop-project)
  (setq project-mode-map (make-keymap))
  (define-key project-mode-map [menu-bar project]
    (cons "Project" (make-sparse-keymap "Project")))
  (define-key project-mode-map [menu-bar project menu-project-showtime]
    '("Show time" . project-show-time))
  (define-key project-mode-map [menu-bar project menu-project-current]
    '("Current" . project-goto-current))
  (define-key project-mode-map [menu-bar project menu-project-startstop]
    '("Start/Stop project" . project-start-stop-project))
  (use-local-map project-mode-map)

  (if (not (member 'project-running-face (face-list)))
      (progn
	(make-face 'project-running-face)
	(set-face-foreground 'project-running-face "red")
	(set-face-background 'project-running-face "white")))
  (message "Start/stop project: f7")
  (make-local-variable 'kill-buffer-hook)
  (add-hook 'kill-buffer-hook 'project-kill-buffer)
  )
