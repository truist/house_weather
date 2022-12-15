#!/usr/bin/env bash

set -eu

CURDIR="$(dirname "$0")"
. "$CURDIR/secrets.sh"

if [ -z "$PASSWORD" ]; then
       echo "You must set CLIENT_ID, CLIENT_SECRET, USERNAME, PASSWORD, USER_ID, and DEVICE_ID in secrets.sh" >&2
       exit 1
fi

# just use the password to get a wholly new access token every time,
# because that's waaay easier than trying to track an ever-moving
# refresh token, with forcibly-expiring access tokens
read -rd '' QUERY_DATA <<EOF || true
{
    "grant_type": "password",
    "client_id": "$CLIENT_ID",
    "client_secret": "$CLIENT_SECRET",
    "username": "$USERNAME",
    "password": "$PASSWORD"
}
EOF
# echo "$QUERY_DATA" | jq .

RESPONSE="$(curl -s \
	--request POST \
	--url https://api.flumewater.com/oauth/token \
	--header 'accept: application/json' \
	--header 'content-type: application/json' \
	--data "$QUERY_DATA")"
# echo "$RESPONSE" | jq .
BEARER_TOKEN="$(echo "$RESPONSE" | jq -e -r .data[0].access_token)"
# echo "BEARER_TOKEN: $BEARER_TOKEN"


read -rd '' QUERY_DATA <<EOF || true
{
	"queries": [
		{
			"request_id": "request_1",
			"bucket": "MIN",
			"since_datetime": "$(date -d '-3 minutes' '+%Y-%m-%d %H:%M:%S')",
			"operation": "SUM",
			"units": "GALLONS"
		}
	]
}
EOF
# echo "$QUERY_DATA" | jq .

RESPONSE="$(curl -s \
	--request POST \
	--url "https://api.flumetech.com/users/$USER_ID/devices/$DEVICE_ID/query" \
	--header 'content-type: application/json' \
	--header "Authorization: Bearer $BEARER_TOKEN" \
	--data "$QUERY_DATA")"
echo "$RESPONSE"


VOLUME="$(echo "$RESPONSE" | jq -e -r '.data[0].request_1[0].value')"
REQ_URL="http://weather.rainskit.com/water?source=flume&volume=$VOLUME"
# echo "REQ_URL: $REQ_URL"
curl -s -S "$REQ_URL" > /dev/null


