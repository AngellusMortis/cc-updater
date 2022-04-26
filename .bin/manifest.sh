#!/bin/bash

find . \( -iname "*.lua" -o -iwholename "*/help/*.txt" \) | sed 's/.\///' | xargs sha256sum | awk '{ print "{\""$2"\": \""$1"\"}" }' | jq -s add > manifest.json
