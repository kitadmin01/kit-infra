#!/bin/bash
# Diagnostic script for Kafka DNS issue

echo "=================================================="
echo "KAFKA DNS DIAGNOSTICS"
echo "=================================================="
echo ""

echo "1. Checking Kafka services..."
kubectl get svc -n analytickit | grep -E "NAME|kafka"
echo ""

echo "2. Checking Kafka pods..."
kubectl get pods -n analytickit | grep -E "NAME|kafka"
echo ""

echo "3. Checking Events pod environment for KAFKA..."
echo "KAFKA_HOSTS:"
kubectl exec -n analytickit analytickit-events-96d4554b8-rw2n2 -- env 2>/dev/null | grep KAFKA_HOSTS || echo "  Not found or pod not accessible"
echo "KAFKA_URL:"
kubectl exec -n analytickit analytickit-events-96d4554b8-rw2n2 -- env 2>/dev/null | grep KAFKA_URL || echo "  Not found or pod not accessible"
echo ""

echo "4. Checking if Kafka service has endpoints..."
kubectl get endpoints -n analytickit analytickit-analytickit-kafka 2>/dev/null || echo "  Service endpoint not found!"
echo ""

echo "5. Describing Kafka service (if exists)..."
kubectl describe svc -n analytickit analytickit-analytickit-kafka 2>/dev/null | grep -E "Name:|Selector:|Endpoints:|Port:" || echo "  Service not found!"
echo ""

echo "6. Checking CoreDNS status..."
kubectl get pods -n kube-system | grep -E "NAME|coredns"
echo ""

echo "7. Testing DNS resolution from events pod..."
kubectl exec -n analytickit analytickit-events-96d4554b8-rw2n2 -- nslookup analytickit-analytickit-kafka 2>/dev/null || echo "  DNS resolution failed or pod not accessible"
echo ""

echo "=================================================="
echo "DIAGNOSIS COMPLETE"
echo "=================================================="

