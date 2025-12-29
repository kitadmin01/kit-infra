#!/bin/bash
# Restart the events pod to pick up DNS changes

echo "Deleting events pod to trigger restart..."
kubectl delete pod -n analytickit analytickit-events-96d4554b8-rw2n2

echo ""
echo "Waiting for new pod to be ready..."
sleep 5
kubectl get pods -n analytickit | grep events

echo ""
echo "Check logs of new pod with:"
echo "kubectl logs -n analytickit <new-pod-name> --tail=50"

