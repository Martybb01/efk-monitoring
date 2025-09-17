#!/bin/bash

echo "Cleaning up EFK Stack..."

echo "Destroying Terraform resources..."
cd terraform
terraform destroy -auto-approve
cd ..

echo ""
echo "Cleaning up Docker images (optional)..."
read -p "Do you want to clean up Docker images? (y/N): " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    docker rmi flask-demo-app:latest 2>/dev/null || echo "Flask image not found"
    docker system prune -f
fi

helm uninstall kibana -n logging 2>/dev/null || true
helm uninstall fluent-bit -n logging 2>/dev/null || true
helm uninstall flask-app -n application 2>/dev/null || true
helm uninstall elasticsearch -n logging 2>/dev/null || true

echo ""
echo "Cleanup completed!"
echo ""
echo "Manual cleanup (if needed):"
echo "• Delete Minikube profile: minikube delete --profile=efk-monitoring"
echo "• Clean Docker: docker system prune -a"