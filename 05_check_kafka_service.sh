#!/bin/bash
# Verify Kafka service configuration and create if missing

echo "Checking if Kafka service exists..."
if kubectl get svc -n analytickit analytickit-analytickit-kafka &>/dev/null; then
    echo "✓ Kafka service exists"
    echo ""
    echo "Service details:"
    kubectl get svc -n analytickit analytickit-analytickit-kafka
    echo ""
    echo "Service description:"
    kubectl describe svc -n analytickit analytickit-analytickit-kafka
else
    echo "✗ Kafka service NOT found!"
    echo ""
    echo "Listing all services in analytickit namespace:"
    kubectl get svc -n analytickit
    echo ""
    echo "If Kafka pod exists but service doesn't, the service may need to be recreated."
    echo "Check if Kafka statefulset/pod exists:"
    kubectl get statefulset,pods -n analytickit | grep kafka
fi

