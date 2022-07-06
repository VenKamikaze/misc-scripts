#!/usr/bin/env python
#
# Bluetooth + Wifi sharing same card causes audio jitter.
# so kill Wifi when we have a BT connection.
#
# Re-enable WiFi when nothing is connected anymore.
#

import sys
import signal
import logging
import dbus
import dbus.service
import dbus.mainloop.glib
from gi.repository import GLib
import subprocess
import time

LOG_LEVEL = logging.INFO
#LOG_LEVEL = logging.DEBUG
LOG_FILE = "/dev/stdout"
#LOG_FILE = "/var/log/syslog"
LOG_FORMAT = "%(asctime)s %(levelname)s %(message)s"

WIFI_PROFILE = "wlan0-kamikaze-5"

def signal_handler(*args, **kwargs):
    gotDevice = (args[0] == "org.bluez.Device1")
    if gotDevice:
        for key in args[1]:
            if key == "Connected":
                if args[1][key]:
                    print("BT CONNECTED. Deactivating WiFi")
                    subprocess.call(['/usr/bin/netctl', 'stop-all'])
                else:
                    print("BT DISCONNECTED. Reactivating WiFi for %s" % WIFI_PROFILE)
                    subprocess.call(['/usr/bin/netctl', 'start', WIFI_PROFILE])

#
#    for i, arg in enumerate(args):
#        print("arg:%d        %s" % (i, str(arg)))
    #print('kwargs:')
    #print(kwargs)
#    print('---end----')

def device_property_changed_cb(property_name, value, path, interface):
    device = dbus.Interface(bus.get_object("org.bluez", path), "org.bluez.Device1")
    properties = device.GetProperties()
    print("Called ")

    if (property_name == "Connected"):
        action = "connected" if value else "disconnected"
        print("The device %s [%s] is %s " % (properties["Alias"],
              properties["Address"], action))
        if action == "connected":
            print("sleeping")
            time.sleep(3)
#            subprocess.call(['xinput', 'set-prop',
#                             'ThinkPad Compact Bluetooth Keyboard with TrackPoint',
#                             'Device Accel Constant Deceleration', '0.5'])
#            subprocess.call(['xinput', 'set-button-map',
#                             'ThinkPad Compact Bluetooth Keyboard with TrackPoint',
#                             '1 18 3 4 5 6 7'])
#            print("command executed")


def shutdown(signum, frame):
    KEEPRUNNING = False

if __name__ == "__main__":
    # shut down on a TERM signal
    signal.signal(signal.SIGTERM, shutdown)

    # start logging
    logging.basicConfig(filename=LOG_FILE, format=LOG_FORMAT, level=LOG_LEVEL)
    logging.info("Starting to monitor Bluetooth connections")

    # get the system bus
    try:
        dbus.mainloop.glib.DBusGMainLoop(set_as_default=True)
        bus = dbus.SystemBus()
    except Exception as ex:
        logging.error("Unable to get the system dbus: '{0}'. Exiting."
                      " Is dbus running?".format(ex.message))
        sys.exit(1)

    # listen for signals on the Bluez bus
    bus.add_signal_receiver(signal_handler, bus_name="org.bluez",
                            signal_name="PropertiesChanged",
                            dbus_interface="org.freedesktop.DBus.Properties",
                            path_keyword="path", interface_keyword="interface",
                            message_keyword="msg")
    try:
        loop = GLib.MainLoop()
        loop.run()
    except Exception as ex:
        logging.error("Unable to run mainloop: '{0}'. Exiting."
                      " Is dbus running?".format(ex.message))

    logging.info("Shutting down bluetooth-runner")
    sys.exit(0)

