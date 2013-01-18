#!/usr/bin/env python
import argparse
import dbus, gobject

parser = argparse.ArgumentParser()

parser.add_argument("conversation", help="The message destination pidgin conversation id",
                    type=int)
parser.add_argument("message", help="The message")

args = parser.parse_args()

if args.message.strip()!="":
    bus = dbus.SessionBus()
    obj = bus.get_object("im.pidgin.purple.PurpleService", "/im/pidgin/purple/PurpleObject")
    purple = dbus.Interface(obj, "im.pidgin.purple.PurpleInterface")
    purple.PurpleConvImSend(purple.PurpleConvIm(args.conversation), args.message)




