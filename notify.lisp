(in-package :stumpwm)

(pushnew '(#\n notify-as-string) *screen-mode-line-formatters* :test 'equal)

(defvar *notify-inbox-emails* nil
  "A list of emails id that needs to be read.")

(defvar *notify-unread-conversations* (make-hash-table :test 'equal)
  "A hashmap for active conversations conversation-id -> unread-flag")

(defcommand notify-chat-new-add (conversation-id)
    ((:string "Conversation id:"))
    (setf (gethash conversation-id *notify-unread-conversations*) 'unread))


(defcommand notify-chat-unread-flag-add (conversation-id) 
    ((:string "Conversation id :"))
  (let ((conversation-flag (gethash conversation-id *notify-unread-conversations*)))
    (when conversation-flag
	  (setf (gethash conversation-id *notify-unread-conversations*) 'read))))
	  
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
  (setq *notify-unread-conversations* (make-hash-table :test 'equal)))

(defcommand notify-emails-reset () ()
  "Clear all emails."
  (setf *notify-inbox-emails* nil))

(defun get-unread-conversations ()
  (loop for conv-flag being the hash-values of *notify-unread-conversations*
     counting (eql conv-flag 'unread) into unread-conv-counter
     finally (return unread-conv-counter)))
       

(defun notify-as-string (&rest r)
  (declare (ignore r))
  (concatenate 'string
               (format nil " INBOX(~a~a^b^n)" (if (> (length *notify-inbox-emails*) 0)
                                           "^1*^B"
                                           "")
                       (length *notify-inbox-emails*))
               (format nil " CHATS(~a~a^b^n) " (if (> (get-unread-conversations) 0)
                                           "^1*^B"
                                           "")
                       (get-unread-conversations))))


(defcommand notify-show-emails ()
  ()
  "Messages all emails"
  (message "Email ids: ~a" *notify-inbox-emails*))



