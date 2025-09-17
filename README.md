# EFK Stack on Kubernetes

Automated Kubernetes infrastructure with Flask application and comprehensive logging using Elasticsearch, Fluent Bit, and Kibana.

## What This Does

Creates a complete local development environment with one-command deployment:

- **Minikube** cluster provisioned via Terraform
- **Flask** demo app with structured logging
- **EFK stack** for log collection, storage, and visualization
- **Helm charts** for application management

## Prerequisites

```bash
# Required tools
terraform >= 1.0
docker
kubectl
minikube
helm >= 3.0
```

## Quick Start

```bash
# Deploy everything
./deploy-complete.sh

# Test the stack
./test-complete-stack.sh

# Clean up when done
./cleanup.sh
```

That's it! The deployment script handles infrastructure provisioning and application deployment automatically.

## Project Structure

```
├── terraform/           # Infrastructure as Code
├── helm-charts/         # Kubernetes application packages
│   ├── flask-app/       # Flask application chart
│   ├── elasticsearch/   # Elasticsearch chart
│   ├── kibana/         # Kibana chart
│   └── fluent-bit/     # Fluent Bit chart
├── app/flask-app/      # Flask application source
└── *.sh               # Deployment scripts
```

## Manual Operations

If you prefer step-by-step control:

```bash
# Infrastructure
cd terraform
terraform init
terraform apply

# Applications (after infrastructure is ready)
helm upgrade --install elasticsearch ./helm-charts/elasticsearch -n logging --create-namespace
helm upgrade --install fluent-bit ./helm-charts/fluent-bit -n logging
helm upgrade --install kibana ./helm-charts/kibana -n logging
helm upgrade --install flask-app ./helm-charts/flask-app -n application --create-namespace
```

## Access Services

```bash
# Kibana (logs visualization)
kubectl port-forward -n logging svc/kibana 5601:5601
# Open http://localhost:5601

# Flask App
kubectl port-forward -n application svc/flask-app 5001:5001
# Open http://localhost:5001
```

## Configuration

Customize infrastructure in `terraform/variables.tf`:

```hcl
cluster_name = "efk-monitoring"
nodes = 2
memory = "6144"
cpus = "4"
```

Customize applications via Helm values files in each chart's `values.yaml`.

## Troubleshooting

```bash
# Check cluster status
kubectl get nodes
kubectl get pods -A

# View logs
kubectl logs -f deployment/flask-app -n application
kubectl logs -f daemonset/fluent-bit -n logging

# Reset if needed
minikube delete --profile=efk-monitoring
```
