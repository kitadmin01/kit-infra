# DNS Resolution Fix After EKS Migration

**Date:** December 29, 2025  
**Issue:** Events not appearing in UI after EKS cluster migration  
**Status:** ✅ RESOLVED

## Problem Description

After migrating the Analytickit deployment to a new EKS cluster in AWS, events were being accepted by the events pod (HTTP 200 responses) but were not appearing in the UI. The ClickHouse database showed no recent events despite successful event ingestion.

### Symptoms

1. Events endpoint (`/e/`) returning HTTP 200 (success)
2. Events not appearing in the UI (latest events were from 2+ months ago)
3. ClickHouse showing 0 recent events
4. Kafka topic `clickhouse_events_json` offset not increasing
5. Intermittent DNS resolution failures in pod logs

### Error Messages Observed

```
OperationalError: could not translate host name "analytickit-pgbouncer" to address: Try again
redis.exceptions.ConnectionError: Error -3 connecting to analytickit-analytickit-redis-master:6379. Try again.
Error: getaddrinfo EAI_AGAIN analytickit-pgbouncer
```

## Root Cause

The root cause was **DNS resolution failures** after the EKS migration. All pods were configured to use Kubernetes DNS service names:

- `analytickit-analytickit-kafka:9092`
- `analytickit-pgbouncer`
- `analytickit-analytickit-redis-master`

However, DNS resolution was intermittently failing or timing out, causing:
- Events pod unable to connect to PostgreSQL (for API key validation)
- Events pod unable to connect to Redis
- Events pod unable to produce events to Kafka
- Plugin server unable to connect to services
- Worker unable to connect to Kafka

## Event Flow Architecture

The event processing pipeline in Analytickit:

```
Browser → Events Pod (/e/) 
  → Kafka Topic: events_plugin_ingestion
  → Plugin Server (processes events)
  → Kafka Topic: clickhouse_events_json
  → ClickHouse Kafka Engine (consumes)
  → ClickHouse Table: sharded_events
  → UI (displays events)
```

When DNS failed at any point in this chain, events would not reach ClickHouse.

## Solution Applied

Updated all pods to use **IP addresses** instead of DNS service names for internal service connections.

### Services and Their IP Addresses

- **Kafka:** `10.100.148.79:9092`
- **PostgreSQL (via pgbouncer):** `10.100.223.26`
- **Redis:** `10.100.250.217`

### Pods Updated

1. **analytickit-events**
2. **analytickit-worker**
3. **analytickit-plugins**

## Fix Commands

### 1. Events Pod

```bash
kubectl set env deployment analytickit-events -n analytickit \
  ANALYTICKIT_POSTGRES_HOST=10.100.223.26 \
  ANALYTICKIT_REDIS_HOST=10.100.250.217 \
  KAFKA_HOSTS=10.100.148.79:9092 \
  KAFKA_URL=kafka://10.100.148.79:9092 \
  KAFKA_BOOTSTRAP_SERVERS=10.100.148.79:9092 \
  ANALYTICKIT_KAFKA_HOSTS=10.100.148.79:9092 \
  ANALYTICKIT_KAFKA_URL=kafka://10.100.148.79:9092
```

### 2. Worker Pod

```bash
kubectl set env deployment analytickit-worker -n analytickit \
  KAFKA_HOSTS=10.100.148.79:9092 \
  KAFKA_URL=kafka://10.100.148.79:9092
```

### 3. Plugin Server Pod

```bash
kubectl set env deployment analytickit-plugins -n analytickit \
  KAFKA_HOSTS=10.100.148.79:9092 \
  KAFKA_URL=kafka://10.100.148.79:9092 \
  ANALYTICKIT_POSTGRES_HOST=10.100.223.26 \
  ANALYTICKIT_REDIS_HOST=10.100.250.217
```

## Verification Steps

### 1. Verify Pods Restarted Successfully

```bash
kubectl get pods -n analytickit | grep -E "events|worker|plugins"
```

### 2. Verify Events Are Being Accepted

```bash
kubectl logs -n analytickit -l app=analytickit,release=analytickit,role=events \
  --tail=100 --since=5m | grep "POST.*\/e\/.*code.*200"
```

### 3. Verify Events Are Reaching ClickHouse

```bash
kubectl exec chi-analytickit-analytickit-0-0-0 -n analytickit -- \
  clickhouse-client --query "SELECT count(*) as recent_events, max(timestamp) as latest \
  FROM analytickit.sharded_events WHERE timestamp > now() - INTERVAL 10 MINUTE"
```

### 4. Verify Kafka Topics Are Receiving Events

```bash
# Check events_plugin_ingestion topic offset
kubectl exec analytickit-analytickit-kafka-0 -n analytickit -- \
  kafka-run-class.sh kafka.tools.GetOffsetShell \
  --broker-list localhost:9092 --topic events_plugin_ingestion --time -1

# Check clickhouse_events_json topic offset (should be increasing)
kubectl exec analytickit-analytickit-kafka-0 -n analytickit -- \
  kafka-run-class.sh kafka.tools.GetOffsetShell \
  --broker-list localhost:9092 --topic clickhouse_events_json --time -1
```

### 5. Verify Plugin Server Is Processing Events

```bash
kubectl logs -n analytickit -l app=analytickit,component=plugins \
  --tail=100 | grep "Kafka batch.*completed"
```

## How to Get Service IP Addresses

If you need to update IPs in the future:

```bash
kubectl get svc -n analytickit \
  analytickit-pgbouncer \
  analytickit-analytickit-redis-master \
  analytickit-analytickit-kafka \
  -o jsonpath='{range .items[*]}{.metadata.name}{"\t"}{.spec.clusterIP}{"\n"}{end}'
```

## Important Notes

### ⚠️ Temporary Solution

Using IP addresses is a **workaround** for the DNS resolution issue. This approach has limitations:

1. **Brittle**: If service IPs change (e.g., after service recreation), pods will fail to connect
2. **Not Kubernetes-native**: Kubernetes services are designed to be accessed via DNS names
3. **Harder to maintain**: Requires manual IP address updates when services change

### ✅ Recommended Next Steps

1. **Investigate DNS Configuration**: 
   - Check CoreDNS configuration in the EKS cluster
   - Verify DNS resolution is working correctly for all pods
   - Check for network policies that might be blocking DNS

2. **Fix DNS Resolution**:
   - Ensure CoreDNS pods are healthy: `kubectl get pods -n kube-system | grep coredns`
   - Check CoreDNS logs for errors
   - Verify DNS server configuration in pod specs (should be `dnsPolicy: ClusterFirst`)
   - Check for network policies or security groups blocking DNS port 53

3. **Revert to DNS Names**:
   Once DNS is fixed, revert the environment variables to use service names:
   ```bash
   kubectl set env deployment analytickit-events -n analytickit \
     ANALYTICKIT_POSTGRES_HOST=analytickit-pgbouncer \
     ANALYTICKIT_REDIS_HOST=analytickit-analytickit-redis-master \
     KAFKA_HOSTS=analytickit-analytickit-kafka:9092 \
     KAFKA_URL=kafka://analytickit-analytickit-kafka:9092 \
     KAFKA_BOOTSTRAP_SERVERS=analytickit-analytickit-kafka:9092 \
     ANALYTICKIT_KAFKA_HOSTS=analytickit-analytickit-kafka:9092 \
     ANALYTICKIT_KAFKA_URL=kafka://analytickit-analytickit-kafka:9092
   ```

4. **Update Helm Chart** (if applicable):
   If using Helm, update the chart values to ensure DNS names are used by default, and document the DNS requirements clearly.

## Related Files

- Helm templates: `charts/analytickit/templates/events-deployment.yaml`
- Helm templates: `charts/analytickit/templates/_postgresql.tpl`
- Helm templates: `charts/analytickit/templates/_snippet-redis-env.tpl`

## Troubleshooting

If events stop flowing again:

1. **Check if IPs changed**: Run the "Get Service IP Addresses" command above and verify they match what's configured in pods
2. **Check pod logs**: Look for connection errors in events, worker, and plugin pods
3. **Check Kafka topic offsets**: Verify events are being produced and consumed
4. **Check ClickHouse**: Verify events are being stored in the database

## Success Criteria

After applying the fix, you should see:

- ✅ Events appearing in UI within 1-2 minutes of ingestion
- ✅ ClickHouse showing recent events: `SELECT count(*) FROM analytickit.sharded_events WHERE timestamp > now() - INTERVAL 5 MINUTE` returns > 0
- ✅ Kafka topic offsets increasing for both `events_plugin_ingestion` and `clickhouse_events_json`
- ✅ Plugin server logs showing "Kafka batch completed" messages
- ✅ No DNS resolution errors in pod logs

## Contact

If DNS resolution issues persist, investigate:
- EKS VPC CNI configuration
- Security group rules for DNS (UDP port 53)
- CoreDNS deployment health
- Network policies affecting DNS traffic

