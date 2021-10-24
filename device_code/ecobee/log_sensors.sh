#!/usr/bin/env bash

set -e

. ./util.sh  # this will also load auth.secrets

if [ -z "$REFRESH_TOKEN" ]; then
	die "You must run authorize.sh first"
fi

ACCESS_TOKEN="$(refreshToken)"

RESULT="$(apiRequestJson 'thermostat' 'log_sensors.json')"

DATA="$(echo "$RESULT" | jq '.thermostatList[].remoteSensors[] | { id: ( "\(.name)-\(.id)" | gsub(" |:"; "_") ) } + reduce .capability[] as $item ({}; . + if $item.type == "temperature" or $item.type == "humidity" then { ($item.type): ($item.value) } else {} end )')"
CELSIUS="$(echo "$DATA" | jq '.temperature |= (((. | tonumber) / 10 - 32) * 5/9 * 100 + 0.5 | floor / 100.0)')"
URLS="$(echo "$CELSIUS" | jq -j '"http://weather.rainskit.com/submit?source=\(.id)&temperature=\(.temperature)" + if .humidity then "&humidity=\(.humidity)\n" else "\n" end')"

echo "$URLS" | while IFS= read -r URL ; do
	if [ -n "$URL" ]; then
		echo "$URL"
		curl -s "$URL"
		echo
	fi
done

