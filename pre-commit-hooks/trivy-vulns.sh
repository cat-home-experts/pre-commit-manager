#!/usr/bin/env bash

set -e

FIND=$(trivy fs --severity high,CRITICAL -q  --ignore-unfixed --security-checks vuln .)
echo "$find"

if [[ ! -z "$FIND" ]]; then
    echo "$FIND"
    exit 1
fi