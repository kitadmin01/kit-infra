# EKS Migration IP Override Configuration

**Date:** December 30, 2025  
**Issue:** DNS resolution failures after EKS cluster migration  
**Solution:** IP address overrides in Helm values.yaml

## Overview

After migrating to a new EKS cluster, DNS resolution became unreliable, causing service connection failures. As a temporary workaround, IP addresses are configured directly in `values.yaml` to bypass DNS resolution.

## Service IP Addresses

The following ClusterIP addresses are configured (as of December 30, 2025):

- **Kafka:** `10.100.148.79:9092`
- **PostgreSQL (direct):** `10.100.13.52:5432`
- **PgBouncer:** `10.100.223.26:6543`
- **Redis:** `10.100.250.217:6379`
- **ClickHouse:** `10.100.16.131` (ports: 8123 HTTP, 9000 Native)

## Configuration Locations

### 1. Web/Events Deployment (`web.env`)

Located in `charts/analytickit/values.yaml` under `web.env`:

```yaml
env:
  - name: ANALYTICKIT_POSTGRES_HOST
    value: "10.100.223.26"  # PgBouncer IP
  - name: ANALYTICKIT_REDIS_HOST
    value: "10.100.250.217"
  - name: KAFKA_HOSTS
    value: "10.100.148.79:9092"
  - name: KAFKA_URL
    value: "kafka://10.100.148.79:9092"
  - name: KAFKA_BOOTSTRAP_SERVERS
    value: "10.100.148.79:9092"
  - name: ANALYTICKIT_KAFKA_HOSTS
    value: "10.100.148.79:9092"
  - name: ANALYTICKIT_KAFKA_URL
    value: "kafka://10.100.148.79:9092"
  - name: CLICKHOUSE_HOST
    value: "10.100.16.131"
```

**Note:** The events deployment uses `web.env`, so these overrides apply to both web and events pods.

### 2. Worker Deployment (`worker.env`)

Located in `charts/analytickit/values.yaml` under `worker.env`:

```yaml
env:
  - name: KAFKA_HOSTS
    value: "10.100.148.79:9092"
  - name: KAFKA_URL
    value: "kafka://10.100.148.79:9092"
```

### 3. Plugins Deployment (`plugins.env`)

Located in `charts/analytickit/values.yaml` under `plugins.env`:

```yaml
env:
  - name: ANALYTICKIT_POSTGRES_HOST
    value: "10.100.223.26"  # PgBouncer IP
  - name: ANALYTICKIT_REDIS_HOST
    value: "10.100.250.217"
  - name: KAFKA_HOSTS
    value: "10.100.148.79:9092"
  - name: KAFKA_URL
    value: "kafka://10.100.148.79:9092"
  - name: CLICKHOUSE_HOST
    value: "10.100.16.131"
```

## Known Limitations

### Init Containers

The init container `wait-for-service-dependencies` still uses DNS names in the script commands. These are defined in:
- `charts/analytickit/templates/_snippet-initContainers-wait-for-service-dependencies.tpl`

To update init containers, manual patching was required using `kubectl patch`. For future deployments, consider:
1. Updating the template file to use IP addresses (not recommended as IPs may change)
2. Creating a migration script to patch init containers after deployment
3. Fixing the root DNS issue (recommended long-term solution)

### ClickHouse Kafka Tables

ClickHouse Kafka engine tables (e.g., `kafka_events_json`) were manually updated to use IP addresses:

```sql
ENGINE = Kafka('10.100.148.79:9092', 'clickhouse_events_json', 'group1', 'JSONEachRow')
```

These tables are created during Analytickit database migrations, not by Helm templates. After a fresh deployment or if tables are recreated, they may need to be manually updated again.

**Manual fix command (if needed after deployment):**

```bash
kubectl exec -n analytickit chi-analytickit-analytickit-0-0-0 -- clickhouse-client --multiquery --query "
DROP TABLE IF EXISTS analytickit.events_json_mv;
DROP TABLE IF EXISTS analytickit.kafka_events_json;
CREATE TABLE analytickit.kafka_events_json (
    \`uuid\` UUID, \`event\` String, \`properties\` String CODEC(ZSTD(3)),
    \`timestamp\` DateTime64(6, 'UTC'), \`team_id\` Int64, \`distinct_id\` String,
    \`elements_chain\` String, \`created_at\` DateTime64(6, 'UTC'), \`person_id\` UUID,
    \`person_created_at\` DateTime64(3), \`person_properties\` String CODEC(ZSTD(3)),
    \`group0_properties\` String CODEC(ZSTD(3)), \`group1_properties\` String CODEC(ZSTD(3)),
    \`group2_properties\` String CODEC(ZSTD(3)), \`group3_properties\` String CODEC(ZSTD(3)),
    \`group4_properties\` String CODEC(ZSTD(3)), \`group0_created_at\` DateTime64(3),
    \`group1_created_at\` DateTime64(3), \`group2_created_at\` DateTime64(3),
    \`group3_created_at\` DateTime64(3), \`group4_created_at\` DateTime64(3)
) ENGINE = Kafka('10.100.148.79:9092', 'clickhouse_events_json', 'group1', 'JSONEachRow')
SETTINGS kafka_skip_broken_messages = 100;
CREATE MATERIALIZED VIEW IF NOT EXISTS analytickit.events_json_mv TO analytickit.sharded_events
AS SELECT * FROM analytickit.kafka_events_json;
"
```

## Updating IP Addresses

If service IP addresses change (e.g., after a service recreation), update the values in `values.yaml` and redeploy:

1. Get current service ClusterIPs:
   ```bash
   kubectl get svc -n analytickit -o wide | grep -E "kafka|pgbouncer|redis|clickhouse|postgresql"
   ```

2. Update `values.yaml` with new IP addresses

3. Redeploy:
   ```bash
   helm upgrade analytickit ./charts/analytickit -n analytickit -f charts/analytickit/values.yaml
   ```

4. If ClickHouse Kafka tables exist, they may need manual update (see above)

## Long-Term Solution

This is a **temporary workaround**. The recommended long-term solution is to:

1. Fix DNS resolution in the EKS cluster (CoreDNS configuration, network policies, etc.)
2. Remove IP address overrides and revert to DNS names
3. Update ClickHouse Kafka tables to use DNS names

## Related Documentation

- See `DNS_RESOLUTION_FIX_EKS_MIGRATION.md` for the original issue documentation
- See `DNS_RESOLUTION_FIX_EKS_MIGRATION.md` for troubleshooting steps

