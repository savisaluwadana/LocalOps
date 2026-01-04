#!/bin/bash
# start-all.sh - Start the complete DevOps playground

set -e

echo "🚀 Starting Local DevOps Playground..."

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m'

print_status() {
    echo -e "${BLUE}[*]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[✓]${NC} $1"
}

# Check OrbStack
print_status "Checking OrbStack..."
if ! command -v orb &> /dev/null; then
    echo "OrbStack not installed. Install with: brew install orbstack"
    exit 1
fi
print_success "OrbStack OK"

# Create Linux VM if not exists
print_status "Setting up Linux VM..."
if ! orb list | grep -q "playground-vm"; then
    orb create ubuntu:22.04 playground-vm
    print_success "Created playground-vm"
else
    print_success "playground-vm already exists"
fi

# Start monitoring stack
print_status "Starting monitoring stack..."
cd playground/monitoring
docker compose up -d
cd ../..
print_success "Monitoring: http://localhost:3000 (admin/admin123)"

# Start Jenkins
print_status "Starting Jenkins..."
cd playground/jenkins
docker compose up -d
cd ../..
print_success "Jenkins: http://localhost:8080"

# Start databases
print_status "Starting databases..."
cd playground/databases
docker compose up -d
cd ../..
print_success "PostgreSQL: localhost:5432, MySQL: localhost:3306"

# Apply Terraform
print_status "Applying Terraform configuration..."
cd playground/terraform
terraform init -input=false
terraform apply -auto-approve
cd ../..
print_success "Terraform: http://localhost:8000"

echo ""
echo "=========================================="
echo "  🎉 DevOps Playground is ready!"
echo "=========================================="
echo ""
echo "Services:"
echo "  • Linux VM:    ssh playground-vm"
echo "  • Grafana:     http://localhost:3000"
echo "  • Prometheus:  http://localhost:9090"
echo "  • Jenkins:     http://localhost:8080"
echo "  • Nginx:       http://localhost:8000"
echo "  • PostgreSQL:  localhost:5432"
echo "  • MySQL:       localhost:3306"
echo "  • Redis:       localhost:6379"
echo ""
