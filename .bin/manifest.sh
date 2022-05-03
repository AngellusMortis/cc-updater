#!/bin/bash

DEPS="[]"
if [[ -f deps.json ]]; then
    DEPS=$(jq -c < deps.json)
fi

LUA_FILES=$(find . -iname "*.lua" ! -iname '*.min.lua')
echo "All files:"
echo $LUA_FILES
echo "Generating manifest.json..."
echo $LUA_FILES \
    | sed 's/.\///' \
    | xargs sha256sum \
    | awk '{ print "{\""$2"\": \""$1"\"}" }' \
    | jq -s add \
    | jq --argjson dependencies $DEPS '{files: ., dependencies: $dependencies}' > manifest.json
echo "Minifying Lua files..."
for file in $LUA_FILES; do
    echo "$file -> ${file%.lua}.min.lua"
    luamin -f $file > ${file%.lua}.min.lua
done
