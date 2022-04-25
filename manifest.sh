#!/bin/bash

find . -iname "*.lua" -exec sha256sum {} \; | awk '{ print "{\""$2"\": \""$1"\"}" }' | jq -s add > manifest.json
