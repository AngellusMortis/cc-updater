#!/bin/bash

DEPS="[]"
if [[ -f deps.json ]]; then
    DEPS=$(jq -c < deps.json)
fi

LUA_FILES=$(find . -iname "*.lua" ! -iname '*.min.lua' | sed 's/.\///')
MANFIEST_FILES="$(find . -iwholename './help/*.txt' | sed 's/.\///')
$LUA_FILES"
echo "All manfiest files:"
echo "$MANFIEST_FILES"
echo ""
echo "Generating manifest.json..."
echo $MANFIEST_FILES \
    | xargs sha256sum \
    | awk '{ print "{\""$2"\": \""$1"\"}" }' \
    | jq -s add \
    | jq --argjson dependencies $DEPS '{files: ., dependencies: $dependencies}' > manifest.json
echo ""
echo "Minifying Lua files..."
for file in $LUA_FILES; do
    minFile=${file%.lua}.min.lua
    minFile="min/$minFile"
    baseDir=$(dirname $minFile)
    mkdir -p $baseDir
    echo "$file -> $minFile"
    cat "$file" | luamin -c > $minFile
done
