;;; -*- emacs-lisp -*-

;;;
;;; $Id: project.el,v 1.3 1997/04/29 18:53:25 eserte Exp $
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

(defun project-find-new-entry ()
  (save-excursion
    (set-buffer project-buffer)
    (goto-char (point-min))
    (search-forward (concat ">" project-current-project))
    (forward-line)
    (while (looking-at "^/")
      (forward-line))
    (while (looking-at "^|")
      (forward-line))
    (point)))
  
(defun project-get-current-time ()
  (let ((time (current-time)))
    (format "%.0f" (+ (* (float (nth 0 time)) 65536)
		      (nth 1 time)))))

(defun project-stop-project ()
  (interactive)
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
  )

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

(defun project-get-projects ()
  (let (projects)
    (save-excursion
      (set-buffer project-buffer)
      (goto-char (point-min))
      (while (re-search-forward "^>+\\(.*\\)" nil t)
	(setq projects (cons (buffer-substring (match-beginning 1)
					       (match-end 1))
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
	  (message (concat project-current-project
			   ": "
			   (format-time-string "%d.%m.%y %T - "
					       (list hi-from lo-from))
			   (format-time-string "%d.%m.%y %T"
					       (list hi-to lo-to))
			   (format " (%d:%02d)"
				   (floor (/ diff-sec 60))
				   (floor (mod diff-sec 60)))))
	  ))))

;;;###autoload
(defun project-mode ()
  (interactive)
  (save-excursion
    (goto-char (point-min))
    (and (not (looking-at "^#PJ1"))
	 (error "This is not a project file")))
  (setq mode-name "Project")
  (setq major-mode 'project-mode)
  (setq project-buffer (current-buffer))
  (global-set-key [f7] 'project-start-stop-project)
  (if (not (member 'project-running-face (face-list)))
      (progn
	(make-face 'project-running-face)
	(set-face-foreground 'project-running-face "red")
	(set-face-background 'project-running-face "white")))
  (message "Start/stop project: f7")
  (make-local-variable 'kill-buffer-hook)
  (add-hook 'kill-buffer-hook (lambda ()
				(remove-hook 'display-time-hook
					     'project-update-endtime)))
  )