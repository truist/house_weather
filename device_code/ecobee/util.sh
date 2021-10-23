# use this via e.g. `. ./util.sh`

API_LOG_FILE="./api.log"

SECRETS_FILE="./auth.secrets"
. "$SECRETS_FILE"

die() {
	echo "$1" >&2
	exit 1
}

if [ -z "$API_KEY" ]; then
	die "You must set API_KEY in $SECRETS_FILE"
fi


API_BASE="https://api.ecobee.com"
bootstrapApiRequest() {
	HTTP_VERB="$1"
	API_VERB="$2"
	ARGS="$3"

	URL="$API_BASE/$API_VERB?$ARGS&client_id=$API_KEY"
	request "$HTTP_VERB" "$URL"
}

apiRequest() {
	HTTP_VERB="$1"
	API_VERB="$2"
	ARGS="$3"

	URL="$API_BASE/1/$API_VERB?format=json&$ARGS"
	request "$HTTP_VERB" "$URL" '-H' 'Content-Type: text/json' '-H' "Authorization: Bearer $ACCESS_TOKEN"
}

request() {
	HTTP_VERB="$1"; shift
	URL="$1"; shift

	echo "Request: $@ $HTTP_VERB $URL" >> "$API_LOG_FILE"

	JSON="$(curl -s "$@" -X $HTTP_VERB "$URL")"
	echo "Response: $JSON" >> "$API_LOG_FILE"
	echo "" >> "$API_LOG_FILE"

	echo "$JSON"
}

extractVar() {
	VAL="$(echo "$1" | jq -r ".$2")"
	if [ "null" = "$VAL" ]; then
		die "Error extracting $2 from $1"
	fi
	echo "$VAL"
}

saveVar() {
	JSON="$1"
	JSON_NAME="$2"
	SAVE_NAME="$3"

	VAL="$(extractVar "$JSON" "$JSON_NAME")"

	echo "$SAVE_NAME=$VAL" >> "$SECRETS_FILE"
	echo "" >> "$SECRETS_FILE"

	echo "$VAL"
}

refreshToken() {
	JSON="$(bootstrapApiRequest POST token "grant_type=refresh_token&refresh_token=$REFRESH_TOKEN")"
	extractVar "$JSON" 'access_token'
}

