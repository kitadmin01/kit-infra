#!/bin/bash

# Automatic Kafka DNS Fix Script
# This script will diagnose and attempt to fix the Kafka DNS resolution issue

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo "=================================================="
echo "AUTOMATIC KAFKA DNS FIX"
echo "=================================================="
echo ""

# Step 1: Check if Kafka service exists
echo "Step 1: Checking Kafka service..."
if kubectl get svc -n analytickit analytickit-analytickit-kafka &>/dev/null; then
    echo -e "${GREEN}✓ Kafka service exists${NC}"
    KAFKA_SERVICE_EXISTS=true
else
    echo -e "${RED}✗ Kafka service NOT found${NC}"
    KAFKA_SERVICE_EXISTS=false
fi
echo ""

# Step 2: Check if Kafka pod is running
echo "Step 2: Checking Kafka pod..."
if kubectl get pod -n analytickit analytickit-analytickit-kafka-0 &>/dev/null; then
    POD_STATUS=$(kubectl get pod -n analytickit analytickit-analytickit-kafka-0 -o jsonpath='{.status.phase}')
    if [ "$POD_STATUS" == "Running" ]; then
        echo -e "${GREEN}✓ Kafka pod is running${NC}"
        KAFKA_POD_RUNNING=true
    else
        echo -e "${YELLOW}⚠ Kafka pod exists but status is: $POD_STATUS${NC}"
        KAFKA_POD_RUNNING=false
    fi
else
    echo -e "${RED}✗ Kafka pod NOT found${NC}"
    KAFKA_POD_RUNNING=false
fi
echo ""

# Step 3: Check CoreDNS
echo "Step 3: Checking CoreDNS status..."
COREDNS_READY=$(kubectl get pods -n kube-system -l k8s-app=kube-dns -o jsonpath='{.items[*].status.conditions[?(@.type=="Ready")].status}' | grep -o "True" | wc -l)
if [ "$COREDNS_READY" -ge 1 ]; then
    echo -e "${GREEN}✓ CoreDNS is running (${COREDNS_READY} pods ready)${NC}"
    COREDNS_OK=true
else
    echo -e "${RED}✗ CoreDNS has issues${NC}"
    COREDNS_OK=false
fi
echo ""

# Step 4: Check if events pod can resolve DNS
echo "Step 4: Testing DNS resolution from events pod..."
if kubectl exec -n analytickit analytickit-events-96d4554b8-rw2n2 -- nslookup analytickit-analytickit-kafka &>/dev/null; then
    echo -e "${GREEN}✓ DNS resolution working${NC}"
    DNS_WORKING=true
else
    echo -e "${RED}✗ DNS resolution failing${NC}"
    DNS_WORKING=false
fi
echo ""

echo "=================================================="
echo "DIAGNOSIS COMPLETE"
echo "=================================================="
echo ""

# Determine and apply fix
if [ "$KAFKA_SERVICE_EXISTS" = false ] || [ "$KAFKA_POD_RUNNING" = false ]; then
    echo -e "${RED}ISSUE: Kafka service or pod is missing/not running${NC}"
    echo "This requires manual intervention:"
    echo "1. Check if Kafka was deployed: kubectl get all -n analytickit | grep kafka"
    echo "2. Reinstall Helm chart if needed: helm upgrade analytickit ./charts/analytickit -n analytickit"
    exit 1
fi

if [ "$COREDNS_OK" = false ]; then
    echo -e "${YELLOW}FIX: Restarting CoreDNS...${NC}"
    kubectl rollout restart deployment/coredns -n kube-system
    echo "Waiting for CoreDNS to be ready..."
    kubectl rollout status deployment/coredns -n kube-system
    echo -e "${GREEN}✓ CoreDNS restarted${NC}"
    echo ""
    sleep 5
fi

if [ "$DNS_WORKING" = false ]; then
    echo -e "${YELLOW}FIX: Restarting events pod to pick up DNS changes...${NC}"
    kubectl delete pod -n analytickit analytickit-events-96d4554b8-rw2n2
    echo "Waiting for new pod to start..."
    sleep 10
    
    # Get the new pod name
    NEW_POD=$(kubectl get pods -n analytickit -l app=analytickit,component=events --no-headers | head -1 | awk '{print $1}')
    if [ -n "$NEW_POD" ]; then
        echo -e "${GREEN}✓ New events pod started: $NEW_POD${NC}"
        echo ""
        echo "Waiting for pod to be ready..."
        kubectl wait --for=condition=ready pod/$NEW_POD -n analytickit --timeout=60s
        
        echo ""
        echo "Testing DNS resolution again..."
        if kubectl exec -n analytickit $NEW_POD -- nslookup analytickit-analytickit-kafka &>/dev/null; then
            echo -e "${GREEN}✓ DNS resolution now working!${NC}"
        else
            echo -e "${YELLOW}⚠ DNS still not working. Trying full DNS name...${NC}"
            
            # Update deployment to use full DNS name
            echo "Updating deployment to use full Kafka DNS name..."
            kubectl set env deployment/analytickit-events -n analytickit \
                KAFKA_HOSTS=analytickit-analytickit-kafka.analytickit.svc.cluster.local:9092
            
            echo "Waiting for deployment to roll out..."
            kubectl rollout status deployment/analytickit-events -n analytickit
            echo -e "${GREEN}✓ Deployment updated${NC}"
        fi
    fi
fi

echo ""
echo "=================================================="
echo "FIX APPLIED"
echo "=================================================="
echo ""
echo "To verify the fix:"
echo "1. Check events pod logs:"
echo "   kubectl logs -n analytickit \$(kubectl get pods -n analytickit -l component=events --no-headers | awk '{print \$1}' | head -1) --tail=50"
echo ""
echo "2. Look for successful Kafka connections (no more DNS errors)"
echo ""
echo "3. Test sending an event to verify it's stored in ClickHouse"

