#!/usr/bin/env python

stumpish_cmd="/home/jmonetta/NonRepSoftware/stumpwm/contrib/stumpish"

# Calls to stumpish
def send_chat_notification(sender, message, conversation):
    sender_name=sender.split("@")[0]
    call([stumpish_cmd, "notify-chat-new-add", str(conversation)])

def send_conversation_readed_callback(conversation):
    call([stumpish_cmd, "notify-chat-read-add", str(conversation)])
    

def send_email_new_notification(id, author, subject):
    call([stumpish_cmd, "notify-email-new-add", id])

def send_email_read_notification(id):
    call([stumpish_cmd, "notify-email-read-add", id])

# Callbacks
def chat_notification_callback(account, sender, message, conversation, flags):
    print "Pidgin conversation ",conversation , "said:", message
    send_chat_notification(sender, message, conversation)

def chat_conversation_updated_callback(conversation, type):
    print "Pidgin conversation ", conversation, " with type ", type
    if type==11:
        print "Pidgin conversation ", conversation, " was read"
        send_conversation_readed_callback(conversation)

def new_email_notification_callback(id, author, subject):
    print "Thunderbird id=", id, " author=", author, " subject=", subject
    send_email_new_notification(id, author, subject)

def changed_email_notification_callback(id, action):
    print "Thunderbird id=", id, " changed to =", action
    if action=="read":
        send_email_read_notification(id)

import dbus, gobject
from dbus.mainloop.glib import DBusGMainLoop
from subprocess import call
dbus.mainloop.glib.DBusGMainLoop(set_as_default=True)

bus = dbus.SessionBus()

# signal sender=:1.27 -> dest=(null destination) serial=2279 path=/im/pidgin/purple/PurpleObject; interface=im.pidgin.purple.PurpleInterface; member=ReceivedImMsg
#    int32 1883
#    string "quevedo_gustavo"
#    string "maraca"
#    int32 46658
#    uint32 2

bus.add_signal_receiver(chat_notification_callback,
                        dbus_interface="im.pidgin.purple.PurpleInterface",
                        signal_name="ReceivedImMsg")

# signal sender=:1.1 -> dest=(null destination) serial=1102 path=/im/pidgin/purple/PurpleObject; interface=im.pidgin.purple.PurpleInterface; member=ConversationUpdated
#    int32 16324
#    uint32 11

bus.add_signal_receiver(chat_conversation_updated_callback,
                        dbus_interface="im.pidgin.purple.PurpleInterface",
                        signal_name="ConversationUpdated")


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

loop = gobject.MainLoop()
loop.run()

