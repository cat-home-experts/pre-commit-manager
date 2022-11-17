#!/usr/bin/env bash

set -e
ROOTGITFOLDER=$(git rev-parse --show-toplevel)
FIND=$(trivy -q fs --severity HIGH,CRITICAL --ignore-unfixed --security-checks vuln "$ROOTGITFOLDER")
echo "Running in $ROOTGITFOLDER"
if [[ -n "$FIND" ]]; then
    echo "$FIND"
    exit 1
fi