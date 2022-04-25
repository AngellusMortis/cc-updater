#!/bin/bash
VERSION=$(cat ./version.txt)

echo $VERSION | awk -F. '{$NF = $NF + 1;} 1' | sed 's/ /./g' > version.txt
