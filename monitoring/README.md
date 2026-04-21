# Monitoring (optional / advanced)

This folder contains small examples aligned to the monitoring/observability slide.

- `prometheus-alerts.yaml`: sample alert rules

## Prometheus examples

Example query (average latency):

```promql
rate(documentdb_query_duration_seconds_sum[5m])
/ rate(documentdb_query_duration_seconds_count[5m])
```

Metrics names and availability depend on the runtime/deployment mode.
Use these as a template and align them to the metrics you expose in your environment.
