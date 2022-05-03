#!/bin/bash

DEPS="[]"
if [[ -f deps.json ]]; then
    DEPS=$(jq -c < deps.json)
fi

LUA_FILES=$(find . -iname "*.lua" ! -iname '*.min.lua')
echo "All files:"
echo "$LUA_FILES"
echo "Generating manifest.json..."
echo $LUA_FILES \
    | sed 's/.\///' \
    | xargs sha256sum \
    | awk '{ print "{\""$2"\": \""$1"\"}" }' \
    | jq -s add \
    | jq --argjson dependencies $DEPS '{files: ., dependencies: $dependencies}' > manifest.json
echo "Minifying Lua files..."
echo $(pwd)
ls -la
for file in $LUA_FILES; do
    minFile=${file%.lua}.min.lua
    echo "$file -> $minFile"
    luamin -f $file # > $minFile
done
