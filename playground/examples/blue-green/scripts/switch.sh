#!/bin/bash
# switch.sh - Switch traffic between blue and green

set -e

COLOR=$1

if [[ "$COLOR" != "blue" && "$COLOR" != "green" ]]; then
    echo "Usage: ./switch.sh [blue|green]"
    exit 1
fi

NGINX_CONF="nginx/nginx.conf"

echo "Switching traffic to $COLOR..."

# Update nginx config
sed -i.bak "s/default        [a-z]*;/default        $COLOR;/" "$NGINX_CONF"

# Reload nginx
docker compose exec lb nginx -s reload

echo "✅ Traffic now routing to $COLOR environment"
echo ""
echo "Test: curl http://localhost:8080"
