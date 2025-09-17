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
echo " Testing Flask App..."
kubectl port-forward -n application svc/flask-app 5001:5001 &
FLASK_PID=$!
sleep 5

echo " Testing Flask endpoints..."
curl -s http://localhost:5000/ | jq '.'
curl -s http://localhost:5000/health | jq '.'
curl -s http://localhost:5000/api/data | jq '.'

kill $FLASK_PID

echo ""
echo "Testing Elasticsearch..."
kubectl port-forward -n logging svc/elasticsearch 9200:9200 &
ES_PID=$!
sleep 5
curl -s http://localhost:9200/_cluster/health | jq '.'
curl -s http://localhost:9200/_cat/indices

kill $ES_PID

echo ""
echo "Testing Kibana..."
kubectl port-forward -n logging svc/kibana 5601:5601 &
KIBANA_PID=$!
sleep 10
curl -s http://localhost:5601/api/status | jq '.status.overall.state' || echo "Kibana starting..."

kill $KIBANA_PID

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
echo "To access services manually:"
echo "• Kibana: kubectl port-forward -n logging svc/kibana 5601:5601"
echo "• Flask App: kubectl port-forward -n application svc/flask-app 5001:5001"
echo "• Elasticsearch: kubectl port-forward -n logging svc/elasticsearch 9200:9200"