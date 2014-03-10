;;; emms-librefm-client.el --- Last.FM Music API

;; Copyright (C) 2014  Free Software Foundation, Inc.

;; Author: Yoni Rabkin <yrk@gnu.org>

;; Keywords: emms, libre.fm

;; EMMS is free software; you can redistribute it and/or modify it
;; under the terms of the GNU General Public License as published by
;; the Free Software Foundation; either version 3, or (at your option)
;; any later version.
;;
;; EMMS is distributed in the hope that it will be useful, but WITHOUT
;; ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
;; or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public
;; License for more details.
;;
;; You should have received a copy of the GNU General Public License
;; along with EMMS; see the file COPYING.  If not, write to the Free
;; Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston,
;; MA 02110-1301, USA.


;;; Code:

(defvar emms-librefm-client-handshake-url
  "turtle.libre.fm"
  "Endpoint for client handshake.")

(defvar emms-librefm-client-method
  "http"
  "Transfer method.")

(defvar emms-librefm-client-username
  ""
  "Libre.fm username.")

(defvar emms-librefm-client-password
  ""
  "Libre.fm user password.")

(defvar emms-librefm-client-debug
  ""
  "Debugging variable to store communication.")

(defvar emms-librefm-client-session-id
  ""
  "Session ID for Libre.fm.")

(defvar emms-librefm-client-now-playing-url
  ""
  "URL for getting the track playing.")

(defvar emms-librefm-client-submission-url
  ""
  "URL for submissions.")


(defun emms-librefm-client-handshake-string (url username password)
  "Return the client handshake string."
  (when (= 0 (length url))
    (error "bad url"))
  (when (= 0 (length username))
    (error "bad username"))
  (when (= 0 (length password))
    (error "bad password"))
  (let ((timestamp (format-time-string "%s")))
    (concat emms-librefm-client-method
	    "://"
	    url "/?"
	    "hs=true" "&"
	    "p=1.2"   "&"
	    "c=emm"   "&"
	    "v=1.0"   "&"
	    "u=" (url-encode-url username) "&"
	    "t=" timestamp "&"
	    "a=" (md5 (concat (md5 password) timestamp)))))

(defun emms-librefm-client-handshake-call (url username password)
  "Perform client handshake and return a response in a buffer."
  (let ((url-request-method "POST"))
    (let ((response
	   (url-retrieve-synchronously
	    (emms-librefm-client-handshake-string
	     url username password))))
      (setq emms-librefm-client-debug
	    (with-current-buffer response
	      (buffer-substring-no-properties (point-min)
					      (point-max))))
      response)))

(defun emms-librefm-client-handle-handshake-response (resbuf)
  "Handle the client handshake server response."
  (when (not (bufferp resbuf))
    (error "response not a buffer"))
  (with-current-buffer resbuf
    (goto-char (point-min))
    (when (not (re-search-forward "^.*200 OK$" (point-at-eol) t))
      (error "bad HTTP server response"))
    ;; go to the start of the FM response
    (when (not (re-search-forward "\n\n" (point-max) t))
      (error "bad FM server response"))
    (let ((status (buffer-substring (point-at-bol)
				    (point-at-eol))))
      (when (not (string= status "OK"))
	(error "FM server returned: %s" status))
      (let (session-id
	    now-playing-url
	    submission-url)
	(forward-line 1)
	(setq session-id (buffer-substring (point-at-bol)
					   (point-at-eol)))
	(forward-line 1)
	(setq now-playing-url (buffer-substring (point-at-bol)
						(point-at-eol)))
	(forward-line 1)
	(setq submission-url (buffer-substring (point-at-bol)
					       (point-at-eol)))
	(when (or (= 0 (length session-id))
		  (= 0 (length now-playing-url))
		  (= 0 (length submission-url)))
	  (error "couldn't parse FM server response"))
	(setq emms-librefm-client-session-id      session-id
	      emms-librefm-client-now-playing-url now-playing-url
	      emms-librefm-client-submission-url  submission-url)
	(message "handshake successful")))))

(defun emms-librefm-client-handshake ()
  "Perform handshake call and handle response."
  (emms-librefm-client-handle-handshake-response
   (emms-librefm-client-handshake-call
    emms-librefm-client-handshake-url
    emms-librefm-client-username
    emms-librefm-client-password)))


(provide 'emms-librefm-client)


;;; emms-librefm-client.el ends here
