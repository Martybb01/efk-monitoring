#!/bin/bash

echo "Testing complete EFK Stack..."

echo " Checking pod status..."
kubectl get pods -A

echo ""
echo " Waiting for all pods to be ready..."
kubectl wait --for=condition=ready pod -l app=elasticsearch -n logging --timeout=300s
kubectl wait --for=condition=ready pod -l app=kibana -n logging --timeout=300s
kubectl wait --for=condition=ready pod -l app=fluent-bit -n logging --timeout=300s
kubectl wait --for=condition=ready pod -l app=flask-app -n application --timeout=300s

echo ""
echo " Getting Minikube IP..."
MINIKUBE_IP=$(minikube ip --profile=efk-monitoring)
echo " Minikube IP: $MINIKUBE_IP"

echo ""
echo " Testing Flask App..."
echo " Testing Flask endpoints..."
curl -s http://$MINIKUBE_IP:30420/ | jq '.' || echo "Flask app not ready yet"
curl -s http://$MINIKUBE_IP:30420/health | jq '.'
curl -s http://$MINIKUBE_IP:30420/api/data | jq '.' || echo "Data endpoint not ready yet"

echo ""
echo "Testing Elasticsearch..."
curl -s http://$MINIKUBE_IP:30200/_cluster/health | jq '.'
curl -s http://$MINIKUBE_IP:30200/_cat/indices

echo ""
echo "Testing Kibana..."
curl -s http://$MINIKUBE_IP:30601/api/status | jq '.status.overall.nickname' || echo "Kibana starting..."

echo ""
echo "Checking logs flow..."
echo "Flask app logs:"
kubectl logs -l app=flask-app -n application --tail=5

echo ""
echo "Fluent Bit logs:"
kubectl logs -l app=fluent-bit -n logging --tail=5

echo ""
echo "EFK Stack test completed!"
echo ""
echo "Services are accessible via NodePort:"
echo "• Flask App: http://$MINIKUBE_IP:30420"
echo "• Kibana: http://$MINIKUBE_IP:30601"
echo "• Elasticsearch: http://$MINIKUBE_IP:30200"