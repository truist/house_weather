#!/usr/bin/env python3
""" query the Sense third-party API """

import configparser
import sys
from sense_energy import Senseable
from sense_energy.sense_exceptions import SenseMFARequiredException
# import urllib.parse
import requests

config = configparser.ConfigParser()
config.read('sense.ini')
cfg = config['sense']

if (not cfg or (not cfg['access_token'] and not cfg['username'])):
    print("You must create a sense.ini file with a [sense] section and define EITHER:")
    print("    access_token, user_id, monitor_id")
    print("  OR")
    print("    username, password")
    sys.exit(1)

sense = Senseable()

if cfg['access_token']:
    sense.load_auth(cfg['access_token'], cfg['user_id'], cfg['monitor_id'])
else:
    try:
        sense.authenticate(cfg['username'], cfg['password'])
    except SenseMFARequiredException:
        mfa = input("Enter current 2FA code: ")
        sense.validate_mfa(mfa)
    print("Now swap out the username/password for these values in your sense.ini:")
    print("access_token =", sense.sense_access_token)
    print("user_id =", sense.sense_user_id)
    print("monitor_id =", sense.sense_monitor_id)

sense.update_realtime()
raw_data = sense.get_realtime()

base_url = 'http://weather.rainskit.com/electricity'

total = f"source=total&watts={raw_data.get('w')}"
requests.get(f"{base_url}?{total}")
# print(total)

channels = raw_data.get('channels')
for channel in range(0, 2):
    channelN = f"source=channel{channel}&watts={channels[channel]}&volts={sense.active_voltage[channel]}"
    requests.get(f"{base_url}?{channelN}")
    # print(channelN)

# don't publish these
# devices = raw_data.get('devices', [])
# for device in devices:
#     deviceN = f"source={urllib.parse.quote_plus(device['name'])}&watts={device['w']}"
#     print(deviceN)

# print("Wattage:", raw_data.get("w", 0))
# print("  per line:", ", ".join(map(str, raw_data.get("channels", []))))
# print("  per device:", ", ".join([f"{d['name']} ({d['w']})" for d in raw_data.get("devices", [])]))
# print("Voltage, per line:", ", ".join(map(str, sense.active_voltage)))

# print("")
# import json
# print(json.dumps(sense.get_realtime()))

# sense.updte_trend_data()
# print("Daily:", sense.daily_usage, "KWh")
