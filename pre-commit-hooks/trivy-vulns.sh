#!/usr/bin/env bash

set -e




echo "$(trivy fs --severity high,CRITICAL -q --exit-code=1  --ignore-unfixed --security-checks vuln .)"