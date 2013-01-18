(in-package :stumpwm)

(pushnew '(#\n notify-as-string) *screen-mode-line-formatters* :test 'equal)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Email integration
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(defvar *notify-inbox-emails* nil
  "A list of emails id that needs to be read.")

(defcommand notify-email-new-add (id) 
    ((:string "Email id :"))
  (when (not (member id *notify-inbox-emails* :test #'string=))
    (push id *notify-inbox-emails*)))

(defcommand notify-email-read-add (id) 
    ((:string "Email id :"))
    (setf *notify-inbox-emails* 
          (delete id *notify-inbox-emails* :test #'string=)))

(defcommand notify-emails-reset () ()
  "Clear all emails."
  (setf *notify-inbox-emails* nil))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Chat integration
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(defstruct conversation
  (remote-nick)
  (messages-list '()) 
  (unread-flag 'unread))
  
(defvar *notify-conversations* (make-hash-table :test 'equal)
  "A hashmap for active conversations conversation-id -> conversation structure")

(defun notify-make-colored-message (nick message)
  (concatenate 'string
	       "^1*^B"
	       nick
	       ":^b^n "
	       message))

(defun get-unread-conversations ()
  (loop for conv being the hash-values of *notify-conversations*
     counting (eql (conversation-unread-flag conv) 'UNREAD) into unread-conv-counter
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


(defun notify-make-menu-options ()
  (loop for key being the hash-keys of *notify-conversations*
     collect (list
	      (conversation-remote-nick (gethash key *notify-conversations*))
	      key)))

(defun notify-make-quick-answer-menu ()
  (let* ((menu-options (notify-make-menu-options))
	 (selection (stumpwm::select-from-menu
		     (current-screen) menu-options "")))
    (cond
      ((null selection)
       (throw 'stumpwm::error "Abort."))
      (t (second selection)))))

(defun notify-make-conversation-messages-list (conv-id)
  (let ((messages-list (conversation-messages-list (gethash conv-id *notify-conversations*)))
	(messages-list-to-show '("" "")))
	(loop 
	   for message in messages-list
	   for count from 1 to 5
	   do
	     (push message messages-list-to-show))
	messages-list-to-show))


(defun notify-get-conversations-ids-as-list ()
  (loop for key being the hash-keys of *notify-conversations*
       collect key))

	 
(defcommand notify-chat-new-add (conversation-id nick flag &rest message)
    ((:string "Conversation id:")
     (:string "Nick:")
     (:string "Flag:")
     (:rest "Message text:"))
  (let* ((message-sender (cond ((equal flag "1") 'ME)
			      ((equal flag "2") 'REMOTE)))
	 (message-nick (cond ((eql message-sender 'ME) "me")
			     ((eql message-sender 'REMOTE) nick))))
    (when (not (gethash conversation-id *notify-conversations*))
      (setf (gethash conversation-id *notify-conversations*) (make-conversation :remote-nick nick)))
    (push (notify-make-colored-message message-nick (first message))
	  (conversation-messages-list (gethash conversation-id *notify-conversations*)))
    (when (eql message-sender 'REMOTE)
      (setf 
       (conversation-unread-flag (gethash conversation-id *notify-conversations*))
       'UNREAD))))
      

(defcommand notify-chat-unread-flag (conversation-id) 
    ((:string "Conversation id :"))
  (when (gethash conversation-id *notify-conversations*)
    (setf (conversation-unread-flag (gethash conversation-id *notify-conversations*))
	  'READ)))
	  

(defcommand notify-chats-reset () ()
  "Clear all chats."
  (setq *notify-conversations* (make-hash-table :test 'equal)))


(defcommand notify-chat-quick-answer () ()
  (unwind-protect
       (let* ((*suppress-echo-timeout* t)
	      (*message-window-gravity* :bottom-left)
	      (*record-last-msg-override* t)
	      (*input-window-gravity* :bottom-left)
	      (selected-conversation (cond ((= (hash-table-count *notify-conversations*) 1)
					    (first (notify-get-conversations-ids-as-list))) 
					   ((> (hash-table-count *notify-conversations*) 1)
					    (notify-make-quick-answer-menu))
					   (t nil)))
	      (messages-list-to-show (notify-make-conversation-messages-list selected-conversation)))
	 (echo-string-list (current-screen) messages-list-to-show)  
	 (run-shell-command (concatenate 'string
					 "/home/jmonetta/MyProjects/stumpish-notify/send-im.py "
					 selected-conversation
					 " \""
					 (read-one-line (current-screen) ">> ")
					 " \"")))
    (unmap-message-window (current-screen))))
