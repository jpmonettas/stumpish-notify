(in-package :stumpwm)

(pushnew '(#\n notify-as-string) *screen-mode-line-formatters* :test 'equal)

(defvar *notify-inbox-emails* nil
  "A list of emails id that needs to be read.")

(defvar *notify-unread-conversations* nil)

(defcommand notify-chat-new-add (conversation-id)
    ((:string "Conversation id:"))
  (when (not (member conversation-id *notify-unread-conversations* :test #'string=))
    (push conversation-id *notify-unread-conversations*)))

(defcommand notify-chat-read-add (conversation-id) 
    ((:string "Conversation id :"))
    (setf *notify-unread-conversations* 
          (delete conversation-id *notify-unread-conversations* :test #'string=)))

(defcommand notify-email-new-add (id) 
    ((:string "Email id :"))
  (when (not (member id *notify-inbox-emails* :test #'string=))
    (push id *notify-inbox-emails*)))

(defcommand notify-email-read-add (id) 
    ((:string "Email id :"))
    (setf *notify-inbox-emails* 
          (delete id *notify-inbox-emails* :test #'string=)))

(defcommand notify-chats-reset () ()
  "Clear all chats."
  (setq *notify-unread-conversations* nil))

(defcommand notify-emails-reset () ()
  "Clear all emails."
  (setf *notify-inbox-emails* nil))

(defun notify-as-string (&rest r)
  (declare (ignore r))
  (concatenate 'string
               (format nil " INBOX(~a~a^b^n)" (if (> (length *notify-inbox-emails*) 0)
                                           "^1*^B"
                                           "")
                       (length *notify-inbox-emails*))
               (format nil " CHATS(~a~a^b^n) " (if (> (length *notify-unread-conversations*) 0)
                                           "^1*^B"
                                           "")
                       (length *notify-unread-conversations*))))


(defcommand notify-show-emails ()
  ()
  "Messages all emails"
  (message "Email ids: ~a" *notify-inbox-emails*))

(defcommand notify-show-conversations ()
  ()
  "Messages all unread conversations"
  (message "Conversations ids: ~a" *notify-unread-conversations*))

;; (defvar *notify-map*
;;   (let ((m (make-sparse-keymap)))
;;     (define-key m (kbd "a")     "notifications-add")
;;     (define-key m (kbd "r")     "notifications-reset")
;;     (define-key m (kbd "d")     "notifications-delete-first")
;;     (define-key m (kbd "D")     "notifications-delete-last")
;;     (define-key m (kbd "s")     "notifications-show")
;;     m))


