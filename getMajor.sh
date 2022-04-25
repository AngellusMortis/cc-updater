#!/bin/bash
VERSION=$(cat ./version.txt)

echo $VERSION | awk -F. '{ print $1 }'
