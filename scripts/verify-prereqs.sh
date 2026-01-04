#!/bin/bash
# verify-prereqs.sh - Verify all prerequisites are installed

echo "🔍 Checking prerequisites..."
echo ""

check_command() {
    if command -v $1 &> /dev/null; then
        version=$($1 --version 2>/dev/null | head -n 1 || $1 version 2>/dev/null | head -n 1)
        echo "✅ $1: $version"
        return 0
    else
        echo "❌ $1: NOT INSTALLED"
        return 1
    fi
}

echo "=== Core Tools ==="
check_command orb
check_command docker
check_command kubectl

echo ""
echo "=== DevOps Tools ==="
check_command terraform
check_command ansible
check_command helm

echo ""
echo "=== Optional Tools ==="
check_command argocd || echo "   Install: brew install argocd"
check_command vault || echo "   Install: brew install vault"

echo ""
echo "=== OrbStack Status ==="
orb status 2>/dev/null || echo "OrbStack not running"

echo ""
echo "=== Docker Status ==="
docker info 2>/dev/null | grep "Server Version" || echo "Docker not running"

echo ""
echo "Done! Install missing tools with:"
echo "  brew install orbstack terraform ansible kubectl helm"
