#!/bin/bash
# canary.sh - Adjust canary traffic percentage

set -e

PERCENT=${1:-10}
STABLE=$((100 - PERCENT))

echo "Setting traffic: ${STABLE}% stable, ${PERCENT}% canary"

sed -i.bak "s/stable:3000 weight=[0-9]*/stable:3000 weight=${STABLE}/" nginx/nginx.conf
sed -i.bak "s/canary:3000 weight=[0-9]*/canary:3000 weight=${PERCENT}/" nginx/nginx.conf

docker compose exec lb nginx -s reload

echo "✓ Traffic updated!"
echo ""
echo "Test with: for i in {1..20}; do curl -s localhost:8080 | jq -r .version; done | sort | uniq -c"
