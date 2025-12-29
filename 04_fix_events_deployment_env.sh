#!/bin/bash
# Fix the KAFKA_HOSTS environment variable to use full DNS name

echo "Patching events deployment to use full Kafka DNS name..."

kubectl patch deployment -n analytickit analytickit-events --type='json' -p='[
  {
    "op": "replace",
    "path": "/spec/template/spec/containers/0/env",
    "value": [
      {
        "name": "KAFKA_HOSTS",
        "value": "analytickit-analytickit-kafka.analytickit.svc.cluster.local:9092"
      }
    ]
  }
]'

echo ""
echo "Waiting for deployment to roll out..."
kubectl rollout status deployment/analytickit-events -n analytickit

echo ""
echo "Deployment updated! Verify with:"
echo "kubectl get pods -n analytickit | grep events"

