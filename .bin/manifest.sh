#!/bin/bash

DEPS="[]"
if [[ -f deps.json ]]; then
    DEPS=$(jq -c < deps.json)
fi

find . -iname "*.lua" \
    | sed 's/.\///' \
    | xargs sha256sum \
    | awk '{ print "{\""$2"\": \""$1"\"}" }' \
    | jq -s add \
    | jq --argjson dependencies $DEPS '{files: ., dependencies: $dependencies}' > manifest.json
