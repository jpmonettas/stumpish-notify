#!/usr/bin/env python

import dbus, gobject
from dbus.mainloop.glib import DBusGMainLoop
from subprocess import call
dbus.mainloop.glib.DBusGMainLoop(set_as_default=True)

stumpish_cmd="/home/jmonetta/NonRepSoftware/stumpwm/contrib/stumpish"
bus = dbus.SessionBus()

#####################################
# Email (Thunderbird) DBus interface
#####################################

# For thunderbird to be able to send dbus signals for new and read email
# we need : Thunderbird dbus signal emiter add-on. Tested with v0.1

def stumpish_email_new_notification(id, author, subject):
    call([stumpish_cmd, "notify-email-new-add", id])

def stumpish_email_read_notification(id):
    call([stumpish_cmd, "notify-email-read-add", id])

def new_email_notification_callback(id, author, subject):
    print "Thunderbird id=", id, " author=", author, " subject=", subject
    stumpish_email_new_notification(id, author, subject)

def changed_email_notification_callback(id, action):
    print "Thunderbird id=", id, " changed to =", action
    if action=="read":
        stumpish_email_read_notification(id)


# signal sender=:1.36 -> dest=(null destination) serial=3 path=/org/mozilla/thunderbird/DBus; interface=org.mozilla.thunderbird.DBus; member=NewMessageSignal
#    string "CANR0=Nh39tJ09r_GM0Ay5bRBtCsv=+o+rWWOheAiKZW7s1pqVQ@mail.gmail.com"
#    string "Juan Monetta <jpmonettas@gmail.com>"
#    string "other test"

bus.add_signal_receiver(new_email_notification_callback,
                        dbus_interface="org.mozilla.thunderbird.DBus",
                        signal_name="NewMessageSignal")

# signal sender=:1.26 -> dest=(null destination) serial=3 path=/org/mozilla/thunderbird/DBus; interface=org.mozilla.thunderbird.DBus; member=ChangedMessageSignal
#    string "CAC=UUWXbv2zWbbnrpzXYAaZFwsPN_vjn-WDB7Lk+SsuKgVOCSA@mail.gmail.com"
#    string "read"

bus.add_signal_receiver(changed_email_notification_callback,
                        dbus_interface="org.mozilla.thunderbird.DBus",
                        signal_name="ChangedMessageSignal")



#####################################
# Chats (Pidgin) DBus interface
#####################################

def stumpish_chat_notification(sender, message, conversation,flag):
    call([stumpish_cmd, "notify-chat-new-add", str(conversation), sender, str(flag),  message])


def stumpish_conversation_unread_flag_changed(conversation):
    call([stumpish_cmd, "notify-chat-unread-flag", str(conversation)])
    


# Callbacks
def chat_notification_callback(account, sender, message, conversation, flag):
    print "Pidgin conversation ",conversation , "said:", message
    sender_name=sender.split("@")[0]
    stumpish_chat_notification(sender_name, message, conversation,flag)

def chat_conversation_updated_callback(conversation, type):
    print "Pidgin conversation ", conversation, " with type ", type
    if type==4:
        print "Pidgin conversation ", conversation, " was read"
        stumpish_conversation_unread_flag_changed(conversation)
        

# signal sender=:1.40 -> dest=(null destination) serial=11676 path=/im/pidgin/purple/PurpleObject; interface=im.pidgin.purple.PurpleInterface; member=WroteImMsg
#    int32 2266
#    string "ib.qatester@gmail.com/gmail.B1A23B27"
#    string "va"
#    int32 383403
#    uint32 2

bus.add_signal_receiver(chat_notification_callback,
                        dbus_interface="im.pidgin.purple.PurpleInterface",
                        signal_name="WroteImMsg")

# signal sender=:1.1 -> dest=(null destination) serial=1102 path=/im/pidgin/purple/PurpleObject; interface=im.pidgin.purple.PurpleInterface; member=ConversationUpdated
#    int32 16324
#    uint32 11

bus.add_signal_receiver(chat_conversation_updated_callback,
                        dbus_interface="im.pidgin.purple.PurpleInterface",
                        signal_name="ConversationUpdated")



# Here we start listening

loop = gobject.MainLoop()
loop.run()

