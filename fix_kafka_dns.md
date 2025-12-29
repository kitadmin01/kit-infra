# Fix Kafka DNS Resolution Issue

## Problem
The events pod cannot resolve `analytickit-analytickit-kafka:9092`

Error: `DNS lookup failed for analytickit-analytickit-kafka:9092, exception was [Errno -3] Try again`

## Diagnostic Commands

Run these commands in WSL to diagnose the issue:

### 1. Check if Kafka service exists
```bash
kubectl get svc -n analytickit | grep kafka
```

### 2. Check Kafka pod status
```bash
kubectl get pods -n analytickit | grep kafka
```

### 3. Check what KAFKA environment variables are set in the events pod
```bash
kubectl exec -n analytickit analytickit-events-96d4554b8-rw2n2 -- env | grep KAFKA
```

### 4. Test DNS resolution from inside the events pod
```bash
kubectl exec -n analytickit analytickit-events-96d4554b8-rw2n2 -- nslookup analytickit-analytickit-kafka
```

### 5. Test with full DNS name
```bash
kubectl exec -n analytickit analytickit-events-96d4554b8-rw2n2 -- nslookup analytickit-analytickit-kafka.analytickit.svc.cluster.local
```

### 6. Describe the Kafka service to see endpoints
```bash
kubectl describe svc -n analytickit analytickit-analytickit-kafka
```

### 7. Check CoreDNS pods status
```bash
kubectl get pods -n kube-system | grep coredns
```

## Common Fixes

### Fix 1: Restart CoreDNS (if DNS is broken)
```bash
kubectl rollout restart deployment/coredns -n kube-system
```

### Fix 2: Restart the events pod to pick up DNS changes
```bash
kubectl delete pod -n analytickit analytickit-events-96d4554b8-rw2n2
```

### Fix 3: If Kafka service doesn't exist, check the deployment
```bash
kubectl get all -n analytickit | grep kafka
```

### Fix 4: Check if the events pod needs DNS configuration
```bash
kubectl get pod -n analytickit analytickit-events-96d4554b8-rw2n2 -o yaml | grep -A 10 dnsPolicy
```

### Fix 5: Update the events deployment to use ClusterFirst DNS policy (if needed)
```bash
kubectl patch deployment -n analytickit analytickit-events -p '{"spec":{"template":{"spec":{"dnsPolicy":"ClusterFirst"}}}}'
```

### Fix 6: Check if service endpoints are properly configured
```bash
kubectl get endpoints -n analytickit analytickit-analytickit-kafka
```

### Fix 7: If Kafka service name is wrong, check actual service names
```bash
kubectl get svc -n analytickit
```

## Most Likely Solution

Based on the error, the most common causes are:

1. **Kafka service doesn't exist or has wrong name**
   - Solution: Verify service name matches what the app is trying to connect to

2. **DNS not working in the pod**
   - Solution: Restart CoreDNS and the events pod

3. **Wrong namespace or missing FQDN**
   - Solution: Update KAFKA_HOSTS env variable to use full DNS name:
     `analytickit-analytickit-kafka.analytickit.svc.cluster.local:9092`

## Apply Fix After Diagnosis

Once you identify the issue, apply the appropriate fix from above.

