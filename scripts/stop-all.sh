#!/bin/bash
# stop-all.sh - Stop all playground services

set -e

echo "🛑 Stopping Local DevOps Playground..."

# Stop monitoring
echo "[*] Stopping monitoring..."
cd playground/monitoring && docker compose down 2>/dev/null || true
cd ../..

# Stop Jenkins
echo "[*] Stopping Jenkins..."
cd playground/jenkins && docker compose down 2>/dev/null || true
cd ../..

# Stop databases
echo "[*] Stopping databases..."
cd playground/databases && docker compose down 2>/dev/null || true
cd ../..

# Stop Vault
echo "[*] Stopping Vault..."
cd playground/vault && docker compose down 2>/dev/null || true
cd ../..

# Destroy Terraform resources
echo "[*] Destroying Terraform resources..."
cd playground/terraform && terraform destroy -auto-approve 2>/dev/null || true
cd ../..

echo ""
echo "✅ All services stopped!"
echo ""
echo "Note: Linux VM is still running. To stop it:"
echo "  orb stop playground-vm"
echo ""
echo "To delete VM completely:"
echo "  orb delete playground-vm"
