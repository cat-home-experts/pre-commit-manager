
#!/bin/bash

set -e -u -o pipefail




trivy fs --severity high,CRITICAL -q --exit-code=1  --ignore-unfixed --security-checks vuln .