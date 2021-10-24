#!/usr/bin/env bash

set -e

. ./util.sh  # this will also load auth.secrets

if [ -z "$REFRESH_TOKEN" ]; then
	die "You must run authorize.sh first"
fi

ACCESS_TOKEN="$(refreshToken)"

apiRequestJson 'thermostat' 'query.json' | jq '.thermostatList[].remoteSensors[] | { id, name, capability } | .capability[] |= { (.type): (.value) } | { id, name } + reduce .capability[] as $item ({}; . + $item)'


