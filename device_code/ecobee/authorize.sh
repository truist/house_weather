#!/usr/bin/env bash

set -e

. ./util.sh  # this will also load auth.secrets

JSON="$(bootstrapApiRequest GET authorize "response_type=ecobeePin&scope=smartRead")"
PIN="$(extractVar "$JSON" 'ecobeePin')"

AUTH_CODE="$(saveVar "$JSON" 'code' 'AUTH_CODE')"

echo "Please authorize this app on the ecobee website by:"
echo "    Logging into your account"
echo "    Clicking on your profile icon"
echo "    Choosing 'My Apps'"
echo "    Choosing 'Add Application'"
echo
echo "...using this code: $PIN"
echo
read -n 1 -p "Return here and press a key when ready..."

JSON="$(bootstrapApiRequest POST token "grant_type=ecobeePin&code=$AUTH_CODE")"
saveVar "$JSON" 'refresh_token' 'REFRESH_TOKEN' >/dev/null

echo
echo "Done!"

