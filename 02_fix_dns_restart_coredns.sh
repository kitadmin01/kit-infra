#!/bin/bash
# Fix 1: Restart CoreDNS to fix DNS resolution issues

echo "Restarting CoreDNS pods..."
kubectl rollout restart deployment/coredns -n kube-system

echo "Waiting for CoreDNS to be ready..."
kubectl rollout status deployment/coredns -n kube-system

echo ""
echo "CoreDNS restarted successfully!"
echo "Now restart the events pod with: ./03_restart_events_pod.sh"

