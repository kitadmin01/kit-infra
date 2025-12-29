# Kafka DNS Resolution Fix

## Problem
Events from website are not getting stored in ClickHouse due to this error:
```
DNS lookup failed for analytickit-analytickit-kafka:9092, exception was [Errno -3] Try again
```

## Step-by-Step Fix

### Step 1: Diagnose the Issue
Run the diagnostic script in WSL:
```bash
cd /mnt/c/Ubuntu/root/projects/kit-infra
./01_diagnose.sh
```

This will check:
- Kafka service existence
- Kafka pod status
- Environment variables in events pod
- DNS resolution
- CoreDNS status

### Step 2: Apply the Appropriate Fix

Based on diagnostic results, choose ONE of the following:

#### Option A: DNS Resolution Issue (Most Common)
If DNS isn't resolving the service name:

```bash
# Restart CoreDNS
./02_fix_dns_restart_coredns.sh

# Then restart the events pod
./03_restart_events_pod.sh
```

#### Option B: Kafka Service Doesn't Exist
If the Kafka service is missing:

```bash
# Check what services exist
./05_check_kafka_service.sh

# Then reinstall/upgrade the helm chart
helm upgrade analytickit ./charts/analytickit -n analytickit
```

#### Option C: Events Pod Using Wrong DNS Name
If the pod is trying to connect with a short name that doesn't resolve:

```bash
# This will update the deployment to use the full DNS name
./04_fix_events_deployment_env.sh
```

### Step 3: Verify the Fix

```bash
# Check if the new events pod is running
kubectl get pods -n analytickit | grep events

# Check the logs (replace <pod-name> with actual pod name)
kubectl logs -n analytickit <pod-name> --tail=50

# Look for successful Kafka connection messages
```

## Manual Commands (Alternative to Scripts)

If you prefer to run commands manually:

### 1. Diagnose
```bash
# Check services
kubectl get svc -n analytickit | grep kafka

# Check pods
kubectl get pods -n analytickit | grep kafka

# Check DNS from inside pod
kubectl exec -n analytickit analytickit-events-96d4554b8-rw2n2 -- nslookup analytickit-analytickit-kafka
```

### 2. Fix - Restart CoreDNS
```bash
kubectl rollout restart deployment/coredns -n kube-system
kubectl rollout status deployment/coredns -n kube-system
```

### 3. Fix - Restart Events Pod
```bash
kubectl delete pod -n analytickit analytickit-events-96d4554b8-rw2n2
```

### 4. Fix - Use Full DNS Name
```bash
# Get current environment variables
kubectl get deployment -n analytickit analytickit-events -o yaml | grep -A 5 KAFKA

# If KAFKA_HOSTS doesn't have full DNS name, patch it:
kubectl set env deployment/analytickit-events -n analytickit \
  KAFKA_HOSTS=analytickit-analytickit-kafka.analytickit.svc.cluster.local:9092
```

## Common Root Causes

1. **CoreDNS Issue**: DNS pods in kube-system namespace not working properly
   - **Fix**: Restart CoreDNS

2. **Service Not Created**: Kafka service wasn't created during helm install
   - **Fix**: Reinstall or upgrade helm chart

3. **Wrong Service Name**: The app is looking for a service that doesn't match the actual service name
   - **Fix**: Check actual service name and update environment variables

4. **Network Policy**: Network policies blocking DNS queries
   - **Fix**: Review and update network policies

5. **Pod DNS Policy**: Pod configured with wrong DNS policy
   - **Fix**: Update pod to use ClusterFirst DNS policy

## Expected Outcome

After fixing, you should see:
- Events pod successfully connecting to Kafka
- No more DNS lookup errors in logs
- Events being stored in ClickHouse
- The error message should disappear from logs

## Troubleshooting

If the fix doesn't work:

1. **Check Kafka is actually running**:
   ```bash
   kubectl logs -n analytickit analytickit-analytickit-kafka-0
   ```

2. **Verify the service has endpoints**:
   ```bash
   kubectl get endpoints -n analytickit analytickit-analytickit-kafka
   ```

3. **Test connectivity**:
   ```bash
   kubectl exec -n analytickit analytickit-events-<pod-name> -- telnet analytickit-analytickit-kafka 9092
   ```

4. **Check if it's a network policy issue**:
   ```bash
   kubectl get networkpolicies -n analytickit
   ```

## Scripts Created

- `01_diagnose.sh` - Run diagnostics
- `02_fix_dns_restart_coredns.sh` - Restart CoreDNS
- `03_restart_events_pod.sh` - Restart events pod
- `04_fix_events_deployment_env.sh` - Update environment variables
- `05_check_kafka_service.sh` - Verify Kafka service
- `fix_kafka_dns.md` - Detailed command reference

## Next Steps

1. Run `./01_diagnose.sh` in WSL
2. Based on the output, run the appropriate fix script
3. Verify the fix worked by checking pod logs
4. Test that events are now being stored in ClickHouse

