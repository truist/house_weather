#!/bin/sh

set -e

CURDIR="$(dirname "$0")"
. "$CURDIR/secrets.sh"

if [ -z "$BEARER_TOKEN" ]; then
       echo "You must set BEARER_TOKEN, USER_ID, and DEVICE_ID in secrets.sh" >&2
       exit 1
fi

QUERY_DATA_PREFIX='{ "queries": [ {"request_id": "request_1", "bucket": "MIN", "since_datetime": "'
SINCE="$(date -d '-3 minutes' '+%Y-%m-%d %H:%M:%S')"
QUERY_DATA_SUFFIX='", "operation": "SUM", "units": "GALLONS"}]}'

QUERY_DATA="${QUERY_DATA_PREFIX}${SINCE}${QUERY_DATA_SUFFIX}"

DATA="$(curl -s \
  --request POST \
  --url "https://api.flumetech.com/users/$USER_ID/devices/$DEVICE_ID/query" \
  --header 'content-type: application/json' \
  --header "Authorization: Bearer $BEARER_TOKEN" \
  --data "$QUERY_DATA")"

echo "$DATA"

VOLUME="$(echo "$DATA" | jq -e '.data[0].request_1[0].value')"

REQ_URL="http://weather.rainskit.com/water?source=flume&volume=$VOLUME"
#echo "$REQ_URL"

curl -s -S "$REQ_URL" > /dev/null

exit 0

