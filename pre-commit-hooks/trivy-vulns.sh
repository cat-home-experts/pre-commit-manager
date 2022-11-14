#!/usr/bin/env bash

set -e
ROOTGITFOLDER=$(git rev-parse --show-toplevel)
FIND=$(trivy fs --severity high,CRITICAL -q  --ignore-unfixed --security-checks vuln $ROOTGITFOLDER)
echo "$find"

if [[ ! -z "$FIND" ]]; then
    echo "$FIND"
    exit 1
fi