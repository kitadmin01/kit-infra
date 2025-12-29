# Quick Start - Fix Kafka DNS Issue

## The Problem
Your events pod is showing this error:
```
DNS lookup failed for analytickit-analytickit-kafka:9092, exception was [Errno -3] Try again
```

## Quick Fix (Recommended)

Open WSL and run:

```bash
cd /Ubuntu/root/projects/kit-infra
chmod +x auto_fix_kafka_dns.sh
./auto_fix_kafka_dns.sh
```

This script will:
1. ✅ Automatically diagnose the issue
2. ✅ Apply the appropriate fix
3. ✅ Verify the fix worked

## What It Does

The script checks:
- If Kafka service exists
- If Kafka pod is running  
- If CoreDNS is working
- If DNS resolution works from the events pod

Then automatically applies one of these fixes:
- **Restart CoreDNS** (if DNS is broken)
- **Restart events pod** (to pick up DNS changes)
- **Update deployment** to use full DNS name (if short name doesn't resolve)

## Manual Step-by-Step (If You Prefer)

### Option 1: Restart CoreDNS + Events Pod
```bash
# Restart CoreDNS
kubectl rollout restart deployment/coredns -n kube-system
kubectl rollout status deployment/coredns -n kube-system

# Delete events pod to restart it
kubectl delete pod -n analytickit analytickit-events-96d4554b8-rw2n2

# Wait and check new pod
kubectl get pods -n analytickit | grep events
```

### Option 2: Use Full DNS Name
```bash
# Update the events deployment
kubectl set env deployment/analytickit-events -n analytickit \
  KAFKA_HOSTS=analytickit-analytickit-kafka.analytickit.svc.cluster.local:9092

# Wait for rollout
kubectl rollout status deployment/analytickit-events -n analytickit
```

## Verify the Fix

```bash
# Get the new events pod name
kubectl get pods -n analytickit | grep events

# Check logs (replace <pod-name>)
kubectl logs -n analytickit <pod-name> --tail=50 | grep -i kafka
```

You should see:
- ✅ No more DNS errors
- ✅ Successful Kafka connections
- ✅ Events being processed

## Still Having Issues?

See `KAFKA_DNS_FIX_README.md` for detailed troubleshooting steps.

## Files Created

- `auto_fix_kafka_dns.sh` - ⭐ **Run this first** (automatic fix)
- `01_diagnose.sh` - Diagnostic only
- `02_fix_dns_restart_coredns.sh` - Restart CoreDNS
- `03_restart_events_pod.sh` - Restart events pod
- `04_fix_events_deployment_env.sh` - Update env variables
- `05_check_kafka_service.sh` - Check Kafka service
- `KAFKA_DNS_FIX_README.md` - Detailed documentation
- `fix_kafka_dns.md` - Command reference

