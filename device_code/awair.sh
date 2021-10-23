#!/bin/sh

set -e

AWAIR_URL=http://awair.rainskit.com/air-data/latest

curl -s $AWAIR_URL | jq -j '"http://weather.rainskit.com/submit?source=awair&temperature=\(.temp)&humidity=\(.humid)&co2=\(.co2)&voc=\(.voc)&pm25=\(.pm25)"' | xargs curl -s -S > /dev/null

