# use this via e.g. `. ./util.sh`

SECRETS_FILE="./auth.secrets"
. "$SECRETS_FILE"

die() {
	echo "$1" >&2
	exit 1
}

if [ -z "$API_KEY" ]; then
	die "You must set API_KEY in $SECRETS_FILE"
fi

API_LOG_FILE="./api.log"
log() {
	echo "$1" >> "$API_LOG_FILE"
}


API_BASE="https://api.ecobee.com"
bootstrapApiRequest() {
	HTTP_VERB="$1"
	API_VERB="$2"
	PARAMS="$3"

	URL="$API_BASE/$API_VERB?$PARAMS&client_id=$API_KEY"
	request "$HTTP_VERB" "$URL"
}

apiRequestJson() {
	API_VERB="$1"
	JSON_FILE="$2"

	# hackity hack hack hack
	# it seem possible that `curl -G` could be useful here, but I couldn't get it to work
	JSON_PARAMS="$(cat "$JSON_FILE" | tr -d "\n[:space:]" | sed 's|{|\\{|g' | sed 's|}|\\}|g')"

	URL="$API_BASE/1/$API_VERB?format=json&body=$JSON_PARAMS"
	request 'GET' "$URL" '-H' 'Content-Type: application/json' '-H' "Authorization: Bearer $ACCESS_TOKEN"
}

request() {
	HTTP_VERB="$1"; shift
	URL="$1"; shift

	log "Request: $@ $HTTP_VERB $URL"

	JSON="$(curl -s "$@" -X $HTTP_VERB "$URL")"
	log "Response: $JSON"
	log ""

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

