#!/bin/sh

set -e

CURDIR=$(dirname $0)
. "$CURDIR/secrets.sh"

if [ -z "$API_KEY" ]; then
	echo "You must set API_KEY, DEVICE_TYPE, and DEVICE_ID in secrets.sh" >&2
	exit 1
fi

AWAIR_URL="https://developer-apis.awair.is/v1/users/self/devices/$DEVICE_TYPE/$DEVICE_ID/air-data/latest"

curl -s "$AWAIR_URL" --header "Authorization: Bearer $API_KEY" | jq '.data[0].sensors | map({ key: (.comp), value: (.value)}) | from_entries' | jq -j '"http://weather.rainskit.com/submit?source=awair&temperature=\(.temp)&humidity=\(.humid)&co2=\(.co2)&voc=\(.voc)&pm25=\(.pm25)"' | xargs curl -s -S > /dev/null


