#!/usr/bin/env bash

set -e

. ./util.sh  # this will also load auth.secrets

if [ -z "$REFRESH_TOKEN" ]; then
	die "You must run authorize.sh first"
fi

ACCESS_TOKEN="$(refreshToken)"

apiRequest GET thermostat 'body=\{"selection":\{"selectionType":"registered","selectionMatch":"","includeRuntime":true\}\}'


