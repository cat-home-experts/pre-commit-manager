#!/usr/bin/env bash

set -e -u -o pipefail




echo "$(trivy fs --severity high,CRITICAL -q --exit-code=1  --ignore-unfixed --security-checks vuln .)"