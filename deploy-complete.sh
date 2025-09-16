#!/bin/bash

echo "Deploying complete EFK Stack with Terraform..."

echo "Checking prerequisites..."
if ! command -v terraform &> /dev/null; then
    echo "Terraform not found. Please install Terraform first."
    exit 1
fi

if ! command -v minikube &> /dev/null; then
    echo "Minikube not found. Please install Minikube first."
    exit 1
fi

if ! command -v kubectl &> /dev/null; then
    echo "kubectl not found. Please install kubectl first."
    exit 1
fi

if ! command -v docker &> /dev/null; then
    echo "sDocker not found. Please install Docker first."
    exit 1
fi

echo "All prerequisites found!"

echo "Deploying infrastructure and applications..."
cd terraform
terraform init
terraform plan
echo "Applying deployment..."
if ! terraform apply -auto-approve; then
    echo "First apply failed, retrying in 10 seconds..."
    sleep 10
    echo "Retrying terraform apply..."
    terraform apply -auto-approve
fi

echo ""
echo "Deployment completed!"
echo ""

terraform output -json | jq -r '.next_steps.value'

cd ..

echo ""
echo "Test the deployment:"
echo "./test-complete-stack.sh"