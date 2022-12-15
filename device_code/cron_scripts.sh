#!/usr/bin/env bash

set -e

run_script() {
	OUTPUT="$($1)" || echo "$1 failed; exit code: $?; stdout: $OUTPUT"
}

cd "$(realpath "$(dirname "${BASH_SOURCE[0]}")")"

run_script "./awair/awair.sh"
run_script "./flume/flume.sh"

cd ecobee
run_script "./log_sensors.sh"

cd ../sense
run_script "./sense.py"

